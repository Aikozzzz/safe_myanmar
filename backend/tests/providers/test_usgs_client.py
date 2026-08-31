from datetime import UTC, datetime, timedelta, timezone

import httpx
import pytest

from app.providers.usgs.client import (
    MAX_RESPONSE_BYTES,
    ProviderClientError,
    UsgsClient,
)

FEED_URL = "https://earthquake.usgs.gov/example/feed.geojson"
RETRIEVED_AT = datetime(2026, 7, 13, 1, 2, 3, tzinfo=UTC)


def client_with_handler(handler, **kwargs):
    http_client = httpx.Client(transport=httpx.MockTransport(handler))
    return UsgsClient(
        FEED_URL,
        http_client=http_client,
        clock=lambda: RETRIEVED_AT,
        **kwargs,
    ), http_client


def test_fetch_gets_exact_url_with_timeout_and_returns_object_json():
    observed = {}

    def handler(request):
        observed["method"] = request.method
        observed["url"] = str(request.url)
        observed["timeout"] = request.extensions["timeout"]
        return httpx.Response(200, json={"type": "FeatureCollection", "features": []})

    client, http_client = client_with_handler(handler, timeout_seconds=10.0)

    try:
        payload, retrieved_at = client.fetch()
    finally:
        http_client.close()

    assert observed == {
        "method": "GET",
        "url": FEED_URL,
        "timeout": {"connect": 10.0, "read": 10.0, "write": 10.0, "pool": 10.0},
    }
    assert payload == {"type": "FeatureCollection", "features": []}
    assert retrieved_at == RETRIEVED_AT


def test_fetch_normalizes_aware_clock_to_utc():
    local_time = datetime(
        2026, 7, 13, 7, 32, 3, tzinfo=timezone(timedelta(hours=6, minutes=30))
    )
    http_client = httpx.Client(
        transport=httpx.MockTransport(lambda request: httpx.Response(200, json={}))
    )
    client = UsgsClient(FEED_URL, http_client=http_client, clock=lambda: local_time)

    try:
        _, retrieved_at = client.fetch()
    finally:
        http_client.close()

    assert retrieved_at == RETRIEVED_AT
    assert retrieved_at.tzinfo is UTC


@pytest.mark.parametrize(
    ("error", "expected_code"),
    [
        (httpx.ReadTimeout("sensitive timeout detail"), "provider_timeout"),
        (httpx.ConnectError("sensitive connection detail"), "provider_unavailable"),
    ],
)
def test_transport_failures_have_safe_classification(error, expected_code):
    def handler(request):
        raise error

    client, http_client = client_with_handler(handler)

    try:
        with pytest.raises(ProviderClientError) as caught:
            client.fetch()
    finally:
        http_client.close()

    assert caught.value.code == expected_code
    assert "sensitive" not in str(caught.value)
    assert FEED_URL not in str(caught.value)


@pytest.mark.parametrize("status_code", [300, 400, 404, 500, 503])
def test_non_success_response_is_unavailable_without_response_leakage(status_code):
    def handler(request):
        return httpx.Response(status_code, text="sensitive provider response")

    client, http_client = client_with_handler(handler)

    try:
        with pytest.raises(ProviderClientError) as caught:
            client.fetch()
    finally:
        http_client.close()

    assert caught.value.code == "provider_unavailable"
    assert "sensitive" not in str(caught.value)
    assert FEED_URL not in str(caught.value)


def test_invalid_json_is_invalid_provider_payload():
    client, http_client = client_with_handler(
        lambda request: httpx.Response(200, content=b"not-json")
    )

    try:
        with pytest.raises(ProviderClientError) as caught:
            client.fetch()
    finally:
        http_client.close()

    assert caught.value.code == "invalid_provider_payload"
    assert "not-json" not in str(caught.value)


def test_oversized_response_body_is_rejected_before_json_parsing():
    client, http_client = client_with_handler(
        lambda request: httpx.Response(200, content=b"x" * (MAX_RESPONSE_BYTES + 1))
    )

    try:
        with pytest.raises(ProviderClientError) as caught:
            client.fetch()
    finally:
        http_client.close()

    assert caught.value.code == "provider_response_too_large"


def test_oversized_content_length_is_rejected_before_reading_response():
    client, http_client = client_with_handler(
        lambda request: httpx.Response(
            200,
            headers={"content-length": str(MAX_RESPONSE_BYTES + 1)},
            content=b"{}",
        )
    )

    try:
        with pytest.raises(ProviderClientError) as caught:
            client.fetch()
    finally:
        http_client.close()

    assert caught.value.code == "provider_response_too_large"


@pytest.mark.parametrize("payload", [[], None, "value", 1, True])
def test_non_object_json_root_is_invalid_provider_payload(payload):
    client, http_client = client_with_handler(
        lambda request: httpx.Response(200, json=payload)
    )

    try:
        with pytest.raises(ProviderClientError) as caught:
            client.fetch()
    finally:
        http_client.close()

    assert caught.value.code == "invalid_provider_payload"


def test_close_does_not_close_injected_client():
    http_client = httpx.Client(
        transport=httpx.MockTransport(lambda request: httpx.Response(200, json={}))
    )
    client = UsgsClient(FEED_URL, http_client=http_client)

    client.close()

    assert not http_client.is_closed
    http_client.close()


def test_context_manager_closes_internally_owned_client():
    client = UsgsClient(FEED_URL)
    owned_http_client = client._http_client

    with client:
        assert not owned_http_client.is_closed

    assert owned_http_client.is_closed
