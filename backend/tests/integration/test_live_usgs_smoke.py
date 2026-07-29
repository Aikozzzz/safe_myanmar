import os
from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, delete, select
from sqlalchemy.orm import Session

from app.main import create_app
from app.models.earthquake import Earthquake
from app.models.provider_sync import ProviderSync

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


def clear_live_usgs_state(session: Session) -> None:
    session.execute(delete(Earthquake).where(Earthquake.provider == "usgs"))
    session.execute(delete(ProviderSync).where(ProviderSync.provider == "usgs"))


def test_clear_live_usgs_state_preserves_future_provider_rows(database_session):
    now = datetime(2026, 7, 13, tzinfo=UTC)
    values = {
        "kind": "earthquake_information",
        "title": "Test earthquake",
        "place": "Test place",
        "magnitude": 1.0,
        "depth_km": 2.0,
        "latitude": 20.0,
        "longitude": 96.0,
        "event_at": now,
        "provider_updated_at": now,
        "retrieved_at": now,
        "review_status": None,
        "source_url": "https://earthquake.usgs.gov/earthquakes/eventpage/test",
        "version": 1,
    }
    database_session.add_all(
        [
            Earthquake(
                id="usgs:test",
                provider="usgs",
                provider_event_id="test",
                **values,
            ),
            Earthquake(
                id="future:test",
                provider="future",
                provider_event_id="test",
                **values,
            ),
            ProviderSync(provider="usgs", last_attempt_at=now),
            ProviderSync(provider="future", last_attempt_at=now),
        ]
    )
    database_session.flush()

    clear_live_usgs_state(database_session)

    assert database_session.get(Earthquake, "usgs:test") is None
    assert database_session.get(ProviderSync, "usgs") is None
    assert database_session.get(Earthquake, "future:test") is not None
    assert database_session.get(ProviderSync, "future") is not None


@pytest.mark.live
@pytest.mark.skipif(
    os.environ.get("RUN_LIVE_USGS_TESTS") != "1",
    reason="set RUN_LIVE_USGS_TESTS=1 to call the live USGS feed",
)
def test_live_usgs_alert_protocol_uses_no_fixture_records(
    monkeypatch, test_database_url
):
    monkeypatch.setenv("DATABASE_URL", test_database_url)
    cleanup_engine = create_engine(test_database_url)
    with Session(cleanup_engine) as session:
        clear_live_usgs_state(session)
        session.commit()

    try:
        application = create_app()
        with TestClient(application, raise_server_exceptions=False) as client:
            response = client.get("/api/v1/alerts")
    finally:
        try:
            with Session(cleanup_engine) as session:
                clear_live_usgs_state(session)
                session.commit()
                assert (
                    session.scalar(
                        select(Earthquake.id).where(Earthquake.provider == "usgs")
                    )
                    is None
                )
                assert session.get(ProviderSync, "usgs") is None
        finally:
            cleanup_engine.dispose()

    if response.status_code == 503:
        pytest.skip("USGS provider or external network is unavailable")
    assert response.status_code == 200
    body = response.json()
    assert set(body) == ENVELOPE_KEYS
    assert body["provider"] == "usgs"
    assert all("fixture" not in item["id"].lower() for item in body["items"])
    assert all(set(item) == ITEM_KEYS for item in body["items"])
