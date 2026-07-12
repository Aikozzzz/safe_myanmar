from dataclasses import replace
from datetime import UTC, datetime, timedelta, timezone

import pytest

from app.providers.usgs.client import ProviderClientError
from app.providers.usgs.models import NormalizationResult
from app.providers.usgs.normalizer import InvalidProviderPayload
from app.repositories.earthquakes import EarthquakeRepository, ProviderSyncRepository
from app.schemas.earthquakes import NormalizedEarthquake
from app.services.earthquakes import EarthquakeService, LiveDataUnavailable

NOW = datetime(2026, 7, 13, 1, 2, 3, tzinfo=UTC)


def event(provider_event_id="abc123", **changes):
    values = {
        "id": f"usgs:{provider_event_id}",
        "provider": "usgs",
        "provider_event_id": provider_event_id,
        "kind": "earthquake_information",
        "title": "SIMULATION: M 5.1 - Test City",
        "place": "SIMULATION: 20 km NW of Test City",
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
    def __init__(self, outcomes):
        self.outcomes = list(outcomes)
        self.calls = 0

    def fetch(self):
        self.calls += 1
        outcome = self.outcomes.pop(0)
        if isinstance(outcome, Exception):
            raise outcome
        return outcome


def service(client, normalizer=None):
    if normalizer is None:

        def normalizer(payload, retrieved_at):
            return payload["result"]

    return EarthquakeService(
        client=client,
        earthquake_repository=EarthquakeRepository(),
        provider_sync_repository=ProviderSyncRepository(),
        normalizer=normalizer,
        refresh_minimum_seconds=60,
        current_max_age_seconds=300,
    )


def success_outcome(events=(), retrieved_at=NOW):
    return {"result": NormalizationResult(tuple(events), 0)}, retrieved_at


def seed_success(database_session, succeeded_at, *events):
    earthquakes = EarthquakeRepository()
    sync = ProviderSyncRepository()
    earthquakes.upsert_many(database_session, events)
    sync.record_success(database_session, "usgs", succeeded_at)


def test_no_metadata_refreshes_and_upserts_events(database_session):
    expected = event()
    client = FakeClient([success_outcome([expected])])

    result = service(client).list_alerts(database_session, NOW)

    assert client.calls == 1
    assert [item.id for item in result.items] == [expected.id]
    assert result.data_status == "current"
    assert result.last_successful_refresh_at == NOW
    sync = ProviderSyncRepository().get(database_session, "usgs")
    assert sync is not None
    assert sync.last_attempt_at == NOW
    assert sync.last_successful_refresh_at == NOW
    assert sync.last_error_code is None


def test_attempt_under_60_seconds_skips_provider(database_session):
    expected = event()
    seed_success(database_session, NOW - timedelta(seconds=59), expected)
    client = FakeClient([])

    result = service(client).list_alerts(database_session, NOW)

    assert client.calls == 0
    assert [item.id for item in result.items] == [expected.id]
    assert result.data_status == "current"


def test_attempt_at_exactly_60_seconds_refreshes(database_session):
    seed_success(database_session, NOW - timedelta(seconds=60))
    client = FakeClient([success_outcome(retrieved_at=NOW + timedelta(seconds=1))])

    result = service(client).list_alerts(database_session, NOW)

    assert client.calls == 1
    assert result.last_successful_refresh_at == NOW + timedelta(seconds=1)
    assert result.data_status == "current"
    sync = ProviderSyncRepository().get(database_session, "usgs")
    assert sync is not None
    assert sync.last_attempt_at == NOW


def test_valid_empty_feed_records_success(database_session):
    client = FakeClient([success_outcome()])

    result = service(client).list_alerts(database_session, NOW)

    assert result.items == ()
    assert result.last_successful_refresh_at == NOW
    assert result.data_status == "current"


@pytest.mark.parametrize(
    "code", ["provider_timeout", "provider_unavailable", "invalid_provider_payload"]
)
def test_provider_failure_stores_only_safe_code_before_any_success(
    database_session, code
):
    client = FakeClient([ProviderClientError(code)])

    with pytest.raises(LiveDataUnavailable) as caught:
        service(client).list_alerts(database_session, NOW)

    assert caught.value.code == "live_data_unavailable"
    sync = ProviderSyncRepository().get(database_session, "usgs")
    assert sync is not None
    assert sync.last_attempt_at == NOW
    assert sync.last_successful_refresh_at is None
    assert sync.last_error_code == code
    assert str(caught.value) == "live_data_unavailable"


def test_normalizer_top_level_failure_stores_invalid_payload(database_session):
    client = FakeClient([({}, NOW)])

    def fail_normalization(payload, retrieved_at):
        raise InvalidProviderPayload("sensitive normalization detail")

    with pytest.raises(LiveDataUnavailable):
        service(client, fail_normalization).list_alerts(database_session, NOW)

    sync = ProviderSyncRepository().get(database_session, "usgs")
    assert sync is not None
    assert sync.last_error_code == "invalid_provider_payload"
    assert "sensitive" not in sync.last_error_code


def test_initial_failure_is_throttled_but_remains_unavailable(database_session):
    client = FakeClient([ProviderClientError("provider_timeout")])
    earthquake_service = service(client)

    with pytest.raises(LiveDataUnavailable):
        earthquake_service.list_alerts(database_session, NOW)
    with pytest.raises(LiveDataUnavailable):
        earthquake_service.list_alerts(database_session, NOW + timedelta(seconds=59))

    assert client.calls == 1


@pytest.mark.parametrize(
    ("success_age", "expected_status"),
    [(timedelta(seconds=120), "current"), (timedelta(seconds=301), "stale")],
)
def test_failure_after_success_returns_persisted_items_by_age(
    database_session, success_age, expected_status
):
    expected = event()
    successful_at = NOW - success_age
    seed_success(database_session, successful_at, expected)
    client = FakeClient([ProviderClientError("provider_unavailable")])

    result = service(client).list_alerts(database_session, NOW)

    assert [item.id for item in result.items] == [expected.id]
    assert result.data_status == expected_status
    assert result.last_successful_refresh_at == successful_at


def test_failure_never_deletes_events_or_changes_success_time(database_session):
    expected = event()
    successful_at = NOW - timedelta(minutes=10)
    seed_success(database_session, successful_at, expected)
    client = FakeClient([ProviderClientError("provider_timeout")])

    service(client).list_alerts(database_session, NOW)

    assert EarthquakeRepository().get(database_session, expected.id) is not None
    sync = ProviderSyncRepository().get(database_session, "usgs")
    assert sync is not None
    assert sync.last_successful_refresh_at == successful_at
    assert sync.last_error_code == "provider_timeout"


@pytest.mark.parametrize(
    ("success_offset", "expected_status"),
    [
        (-timedelta(seconds=300), "current"),
        (-timedelta(seconds=301), "stale"),
        (timedelta(seconds=30), "current"),
    ],
)
def test_current_age_boundaries_and_future_success(
    database_session, success_offset, expected_status
):
    successful_at = NOW + success_offset
    seed_success(database_session, successful_at)
    client = FakeClient([ProviderClientError("provider_unavailable")])

    result = service(client).list_alerts(database_session, NOW)

    assert client.calls == (0 if success_offset > timedelta(0) else 1)
    assert result.data_status == expected_status


def test_newer_revision_replaces_record_and_older_revision_does_not(
    database_session,
):
    original = event()
    newer = replace(
        original,
        title="SIMULATION: revised title",
        provider_updated_at=original.provider_updated_at + timedelta(minutes=1),
        retrieved_at=NOW + timedelta(minutes=1),
        version=2,
    )
    older = replace(
        original,
        title="SIMULATION: stale title",
        provider_updated_at=original.provider_updated_at - timedelta(minutes=1),
        retrieved_at=NOW + timedelta(minutes=2),
        version=3,
    )
    client = FakeClient(
        [
            success_outcome([original], NOW),
            success_outcome([newer], NOW + timedelta(minutes=1)),
            success_outcome([older], NOW + timedelta(minutes=2)),
        ]
    )
    earthquake_service = service(client)

    earthquake_service.list_alerts(database_session, NOW)
    earthquake_service.list_alerts(database_session, NOW + timedelta(minutes=1))
    result = earthquake_service.list_alerts(
        database_session, NOW + timedelta(minutes=2)
    )

    assert result.items[0].title == newer.title
    assert result.items[0].version == 2


def test_successful_refresh_clears_previous_error(database_session):
    sync_repository = ProviderSyncRepository()
    sync_repository.record_attempt(
        database_session, "usgs", NOW - timedelta(minutes=1), "provider_timeout"
    )
    client = FakeClient([success_outcome()])

    service(client).list_alerts(database_session, NOW)

    sync = sync_repository.get(database_session, "usgs")
    assert sync is not None
    assert sync.last_error_code is None
    assert sync.last_successful_refresh_at == NOW


def test_aware_now_is_normalized_to_utc(database_session):
    local_now = datetime(
        2026, 7, 13, 7, 32, 3, tzinfo=timezone(timedelta(hours=6, minutes=30))
    )
    client = FakeClient([success_outcome()])

    result = service(client).list_alerts(database_session, local_now)

    assert result.last_successful_refresh_at == NOW
    sync = ProviderSyncRepository().get(database_session, "usgs")
    assert sync is not None
    assert sync.last_attempt_at == NOW


def test_naive_now_is_rejected_without_provider_call(database_session):
    client = FakeClient([])

    with pytest.raises(ValueError, match="timezone-aware"):
        service(client).list_alerts(database_session, datetime(2026, 7, 13, 1, 2, 3))

    assert client.calls == 0


def test_service_never_commits_caller_transaction(database_session, monkeypatch):
    def fail_commit():
        pytest.fail("service committed the caller transaction")

    monkeypatch.setattr(database_session, "commit", fail_commit)
    client = FakeClient([success_outcome([event()])])

    service(client).list_alerts(database_session, NOW)
