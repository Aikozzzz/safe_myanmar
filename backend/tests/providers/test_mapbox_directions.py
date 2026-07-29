import logging

import httpx
import pytest

from app.providers.mapbox.directions import (
    MAPBOX_DIRECTIONS_BASE_URL,
    MAX_RESPONSE_BYTES,
    MAX_ROUTE_POINTS,
    DirectionsProviderError,
    MapboxDirectionsProvider,
)
from app.schemas.navigation import Coordinate

ORIGIN = Coordinate(latitude=21.95, longitude=96.08)
DESTINATION = Coordinate(latitude=21.958, longitude=96.091)


def route(index: int) -> dict:
    return {
        "distance": 1000.0 + index,
        "duration": 600.0 + index,
        "geometry": {
            "type": "LineString",
            "coordinates": [[96.08, 21.95], [96.091, 21.958]],
        },
    }


def provider_with_handler(handler, token="test-token"):
    http_client = httpx.Client(transport=httpx.MockTransport(handler))
    return (
        MapboxDirectionsProvider(token, 7.0, http_client=http_client),
        http_client,
    )


def test_requests_fixed_https_mapbox_host_and_route_options():
    observed = {}

    def handler(request):
        observed["url"] = request.url
        observed["timeout"] = request.extensions["timeout"]
        return httpx.Response(200, json={"routes": [route(1)]})

    provider, http_client = provider_with_handler(handler)
    try:
        routes = provider.get_routes(ORIGIN, DESTINATION, "walking")
    finally:
        http_client.close()

    url = observed["url"]
    assert f"{url.scheme}://{url.host}" == "https://api.mapbox.com"
    assert str(url).startswith(f"{MAPBOX_DIRECTIONS_BASE_URL}/walking/")
    assert url.params["alternatives"] == "true"
    assert url.params["geometries"] == "geojson"
    assert url.params["overview"] == "full"
    assert url.params["access_token"] == "test-token"
    assert observed["timeout"] == {
        "connect": 7.0,
        "read": 7.0,
        "write": 7.0,
        "pool": 7.0,
    }
    assert len(routes) == 1


@pytest.mark.parametrize("count", [1, 2, 3])
def test_returns_only_provider_supplied_alternatives(count):
    provider, http_client = provider_with_handler(
        lambda request: httpx.Response(
            200, json={"routes": [route(index) for index in range(count)]}
        )
    )
    try:
        routes = provider.get_routes(ORIGIN, DESTINATION, "driving")
    finally:
        http_client.close()

    assert len(routes) == count
    assert [item.distance_m for item in routes] == [
        1000.0 + index for index in range(count)
    ]


def test_rejects_provider_routes_beyond_mapbox_three_route_limit():
    provider, http_client = provider_with_handler(
        lambda request: httpx.Response(
            200, json={"routes": [route(index) for index in range(4)]}
        )
    )
    try:
        with pytest.raises(DirectionsProviderError, match="routing_unavailable"):
            provider.get_routes(ORIGIN, DESTINATION, "walking")
    finally:
        http_client.close()


@pytest.mark.parametrize(
    "outcome",
    [
        httpx.ReadTimeout("secret test-token 96.08,21.95"),
        httpx.ConnectError("secret test-token 96.08,21.95"),
        httpx.Response(503, text="secret test-token 96.08,21.95"),
        httpx.Response(200, content=b"not-json 96.08,21.95"),
        httpx.Response(200, json={"routes": []}),
        httpx.Response(200, json={"routes": [{"geometry": {}}]}),
    ],
)
def test_provider_failures_are_safe_and_do_not_leak_coordinates_or_token(outcome):
    def handler(request):
        if isinstance(outcome, Exception):
            raise outcome
        return outcome

    provider, http_client = provider_with_handler(handler)
    try:
        with pytest.raises(DirectionsProviderError) as caught:
            provider.get_routes(ORIGIN, DESTINATION, "walking")
    finally:
        http_client.close()

    assert str(caught.value) == "routing_unavailable"
    assert "96.08" not in str(caught.value)
    assert "test-token" not in str(caught.value)


def test_absent_token_fails_before_network_call():
    called = False

    def handler(request):
        nonlocal called
        called = True
        return httpx.Response(200, json={"routes": [route(1)]})

    provider, http_client = provider_with_handler(handler, token=None)
    try:
        with pytest.raises(DirectionsProviderError, match="routing_unavailable"):
            provider.get_routes(ORIGIN, DESTINATION, "walking")
    finally:
        http_client.close()

    assert not called


@pytest.mark.parametrize(
    "bad_route",
    [
        {**route(1), "distance": 10**400},
        {**route(1), "duration": 10**400},
        {
            **route(1),
            "geometry": {
                "type": "LineString",
                "coordinates": [[10**400, 21.95], [96.091, 21.958]],
            },
        },
        {
            **route(1),
            "geometry": {
                "type": "LineString",
                "coordinates": [[96.08, 21.95]] * (MAX_ROUTE_POINTS + 1),
            },
        },
    ],
)
def test_rejects_overflowing_numbers_and_oversized_geometry(bad_route):
    provider, http_client = provider_with_handler(
        lambda request: httpx.Response(200, json={"routes": [bad_route]})
    )
    try:
        with pytest.raises(DirectionsProviderError, match="routing_unavailable"):
            provider.get_routes(ORIGIN, DESTINATION, "walking")
    finally:
        http_client.close()


def test_rejects_oversized_response_body_before_json_parsing():
    provider, http_client = provider_with_handler(
        lambda request: httpx.Response(200, content=b"x" * (MAX_RESPONSE_BYTES + 1))
    )
    try:
        with pytest.raises(DirectionsProviderError, match="routing_unavailable"):
            provider.get_routes(ORIGIN, DESTINATION, "walking")
    finally:
        http_client.close()


def test_rejects_oversized_content_length_before_reading_response():
    provider, http_client = provider_with_handler(
        lambda request: httpx.Response(
            200,
            headers={"content-length": str(MAX_RESPONSE_BYTES + 1)},
            content=b'{"routes":[]}',
        )
    )
    try:
        with pytest.raises(DirectionsProviderError, match="routing_unavailable"):
            provider.get_routes(ORIGIN, DESTINATION, "walking")
    finally:
        http_client.close()


def test_rejects_excessively_nested_provider_json_as_unavailable():
    nested = b'{"routes":' + (b"[" * 1100) + b"0" + (b"]" * 1100) + b"}"
    provider, http_client = provider_with_handler(
        lambda request: httpx.Response(200, content=nested)
    )
    try:
        with pytest.raises(DirectionsProviderError, match="routing_unavailable"):
            provider.get_routes(ORIGIN, DESTINATION, "walking")
    finally:
        http_client.close()


def test_httpx_info_logging_redacts_coordinates_and_token(caplog):
    provider, http_client = provider_with_handler(
        lambda request: httpx.Response(200, json={"routes": [route(1)]})
    )
    logger = logging.getLogger("httpx")
    logger_was_disabled = logger.disabled
    logger.disabled = False
    caplog.set_level("INFO", logger="httpx")
    try:
        provider.get_routes(ORIGIN, DESTINATION, "walking")
    finally:
        http_client.close()
        logger.disabled = logger_was_disabled

    assert "[redacted]" in caplog.text
    assert "96.08" not in caplog.text
    assert "21.95" not in caplog.text
    assert "test-token" not in caplog.text
