import os

import pytest
from fastapi.testclient import TestClient

from app.main import create_app

ENVELOPE_KEYS = {
    "items",
    "data_status",
    "last_successful_refresh_at",
    "provider",
}
ITEM_KEYS = {
    "id",
    "provider",
    "provider_event_id",
    "kind",
    "title",
    "place",
    "magnitude",
    "depth_km",
    "latitude",
    "longitude",
    "event_at",
    "provider_updated_at",
    "retrieved_at",
    "review_status",
    "source_url",
    "version",
}


@pytest.mark.live
@pytest.mark.skipif(
    os.environ.get("RUN_LIVE_USGS_TESTS") != "1",
    reason="set RUN_LIVE_USGS_TESTS=1 to call the live USGS feed",
)
def test_live_usgs_alert_protocol_uses_no_fixture_records(
    monkeypatch, test_database_url
):
    monkeypatch.setenv("DATABASE_URL", test_database_url)
    application = create_app()

    with TestClient(application, raise_server_exceptions=False) as client:
        response = client.get("/api/v1/alerts")

    if response.status_code == 503:
        pytest.skip("USGS provider or external network is unavailable")
    assert response.status_code == 200
    body = response.json()
    assert set(body) == ENVELOPE_KEYS
    assert body["provider"] == "usgs"
    assert all("fixture" not in item["id"].lower() for item in body["items"])
    assert all(set(item) == ITEM_KEYS for item in body["items"])
