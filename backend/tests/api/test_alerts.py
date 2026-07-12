from collections.abc import Iterator
from dataclasses import asdict
from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, delete
from sqlalchemy.orm import Session, sessionmaker

from app.api.v1.alerts import get_clock, get_earthquake_service, get_session
from app.main import create_app
from app.models.earthquake import Earthquake
from app.models.provider_sync import ProviderSync
from app.providers.usgs.client import ProviderClientError
from app.providers.usgs.models import NormalizationResult
from app.repositories.earthquakes import EarthquakeRepository, ProviderSyncRepository
from app.schemas.earthquakes import NormalizedEarthquake
from app.services.earthquakes import AlertCollection, EarthquakeService

NOW = datetime(2026, 7, 13, 10, 0, tzinfo=UTC)
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
ENVELOPE_KEYS = {
    "items",
    "data_status",
    "last_successful_refresh_at",
    "provider",
}


def event(provider_event_id: str = "abc123", **changes) -> NormalizedEarthquake:
    values = {
        "id": f"usgs:{provider_event_id}",
        "provider": "usgs",
        "provider_event_id": provider_event_id,
        "kind": "earthquake_information",
        "title": "M 5.1 - 20 km NW of Mandalay",
        "place": "20 km NW of Mandalay",
        "magnitude": 5.1,
        "depth_km": 12.4,
        "latitude": 22.1,
        "longitude": 96.0,
        "event_at": NOW - timedelta(minutes=10),
        "provider_updated_at": NOW - timedelta(minutes=5),
        "retrieved_at": NOW,
        "review_status": "reviewed",
        "source_url": (
            f"https://earthquake.usgs.gov/earthquakes/eventpage/{provider_event_id}"
        ),
        "version": 1,
    }
    values.update(changes)
    return NormalizedEarthquake(**values)


class FakeClient:
    def __init__(self, outcome):
        self.outcome = outcome

    def fetch(self):
        if isinstance(self.outcome, Exception):
            raise self.outcome
        return self.outcome


class StubService:
    def __init__(self, collection: AlertCollection):
        self.collection = collection
        self.detail = None

    def list_alerts(self, session, now):
        return self.collection

    def get_alert(self, session, alert_id):
        return self.detail


def service(client) -> EarthquakeService:
    return EarthquakeService(
        client=client,
        earthquake_repository=EarthquakeRepository(),
        provider_sync_repository=ProviderSyncRepository(),
        normalizer=lambda payload, retrieved_at: payload["result"],
        refresh_minimum_seconds=60,
        current_max_age_seconds=300,
    )


@pytest.fixture
def api_session_factory(test_database_url, database_session):
    engine = create_engine(test_database_url)
    factory = sessionmaker(bind=engine, expire_on_commit=False)
    with engine.begin() as connection:
        connection.execute(delete(Earthquake))
        connection.execute(delete(ProviderSync))
    try:
        yield factory
    finally:
        with engine.begin() as connection:
            connection.execute(delete(Earthquake))
            connection.execute(delete(ProviderSync))
        engine.dispose()


@pytest.fixture
def api_app(api_session_factory):
    application = create_app()

    def session_dependency() -> Iterator[Session]:
        with api_session_factory() as session:
            yield session

    application.dependency_overrides[get_session] = session_dependency
    application.dependency_overrides[get_clock] = lambda: lambda: NOW
    return application


def request(api_app, *, raise_server_exceptions=True):
    return TestClient(api_app, raise_server_exceptions=raise_server_exceptions)


def persist_event(factory, expected):
    with factory.begin() as session:
        EarthquakeRepository().upsert_many(session, [expected])


def test_list_empty_success_has_exact_envelope(api_app):
    stub = StubService(AlertCollection((), "current", NOW))
    api_app.dependency_overrides[get_earthquake_service] = lambda: stub

    with request(api_app) as client:
        response = client.get("/api/v1/alerts")

    assert response.status_code == 200
    assert response.json() == {
        "items": [],
        "data_status": "current",
        "last_successful_refresh_at": "2026-07-13T10:00:00Z",
        "provider": "usgs",
    }


@pytest.mark.parametrize("status", ["current", "stale"])
def test_list_populated_has_exact_public_item_and_status(
    api_app, api_session_factory, status
):
    expected = event(review_status=None)
    persist_event(api_session_factory, expected)
    with api_session_factory() as session:
        stored = EarthquakeRepository().get(session, expected.id)
        assert stored is not None
        stub = StubService(AlertCollection((stored,), status, NOW))
        api_app.dependency_overrides[get_earthquake_service] = lambda: stub
        with request(api_app) as client:
            response = client.get("/api/v1/alerts")

    body = response.json()
    assert response.status_code == 200
    assert set(body) == ENVELOPE_KEYS
    assert body["data_status"] == status
    assert set(body["items"][0]) == ITEM_KEYS
    assert body["items"][0] == {
        **asdict(expected),
        "event_at": "2026-07-13T09:50:00Z",
        "provider_updated_at": "2026-07-13T09:55:00Z",
        "retrieved_at": "2026-07-13T10:00:00Z",
    }
    assert "severity" not in response.text
    assert "freshness" not in response.text


def test_detail_returns_exact_persisted_item_without_refresh(
    api_app, api_session_factory
):
    expected = event()
    persist_event(api_session_factory, expected)

    with request(api_app) as client:
        response = client.get(f"/api/v1/alerts/{expected.id}")

    assert response.status_code == 200
    assert set(response.json()) == ITEM_KEYS
    assert response.json()["id"] == expected.id


def test_detail_missing_returns_safe_exact_404(api_app):
    with request(api_app) as client:
        response = client.get("/api/v1/alerts/usgs:missing")

    request_id = response.json()["error"]["request_id"]
    assert response.status_code == 404
    assert request_id
    assert response.headers["X-Request-ID"] == request_id
    assert response.json() == {
        "error": {
            "code": "not_found",
            "message": "Earthquake information was not found.",
            "request_id": request_id,
        }
    }


def test_never_success_failure_returns_503_and_commits_attempt(
    api_app, api_session_factory
):
    api_app.dependency_overrides[get_earthquake_service] = lambda: service(
        FakeClient(ProviderClientError("provider_timeout"))
    )

    with request(api_app) as client:
        response = client.get("/api/v1/alerts")

    request_id = response.json()["error"]["request_id"]
    assert response.status_code == 503
    assert response.headers["X-Request-ID"] == request_id
    assert response.json() == {
        "error": {
            "code": "live_data_unavailable",
            "message": "Live earthquake data is currently unavailable.",
            "request_id": request_id,
        }
    }
    with api_session_factory() as session:
        sync = ProviderSyncRepository().get(session, "usgs")
        assert sync is not None
        assert sync.last_attempt_at == NOW
        assert sync.last_error_code == "provider_timeout"
        assert sync.last_successful_refresh_at is None


def test_successful_list_commits_events_and_metadata(api_app, api_session_factory):
    expected = event()
    outcome = {"result": NormalizationResult((expected,), 0)}, NOW
    api_app.dependency_overrides[get_earthquake_service] = lambda: service(
        FakeClient(outcome)
    )

    with request(api_app) as client:
        response = client.get("/api/v1/alerts")

    assert response.status_code == 200
    with api_session_factory() as session:
        assert EarthquakeRepository().get(session, expected.id) is not None
        sync = ProviderSyncRepository().get(session, "usgs")
        assert sync is not None
        assert sync.last_successful_refresh_at == NOW


def test_unexpected_failure_rolls_back_partial_changes(api_app, api_session_factory):
    expected = event()

    class FailingService:
        def list_alerts(self, session, now):
            EarthquakeRepository().upsert_many(session, [expected])
            raise RuntimeError("controlled failure")

    api_app.dependency_overrides[get_earthquake_service] = lambda: FailingService()
    with request(api_app, raise_server_exceptions=False) as client:
        response = client.get("/api/v1/alerts")

    assert response.status_code == 500
    with api_session_factory() as session:
        assert EarthquakeRepository().get(session, expected.id) is None


def test_runtime_resources_are_reused_and_closed(monkeypatch):
    from app import main

    created_clients = []

    class TrackedClient:
        def __init__(self, *args, **kwargs):
            self.closed = False
            created_clients.append(self)

        def close(self):
            self.closed = True

    monkeypatch.setattr(main, "UsgsClient", TrackedClient)
    application = create_app()
    with TestClient(application):
        assert (
            application.state.earthquake_service is application.state.earthquake_service
        )
        assert application.state.engine is application.state.engine
        assert len(created_clients) == 1

    assert created_clients[0].closed is True
    assert application.state.engine.pool.status().startswith("Pool size")
