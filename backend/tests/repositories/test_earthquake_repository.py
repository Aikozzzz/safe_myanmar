from dataclasses import asdict, replace
from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import insert, text
from sqlalchemy.exc import IntegrityError

from app.models.earthquake import Earthquake
from app.models.provider_sync import ProviderSync
from app.repositories.earthquakes import EarthquakeRepository, ProviderSyncRepository
from app.schemas.earthquakes import NormalizedEarthquake

NOW = datetime(2026, 7, 13, 1, 2, 3, tzinfo=UTC)


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
        "source_url": f"https://earthquake.usgs.gov/earthquakes/eventpage/{provider_event_id}",
        "version": 1,
    }
    values.update(changes)
    return NormalizedEarthquake(**values)


def persisted_values(stored: Earthquake) -> dict:
    return {
        "id": stored.id,
        "provider": stored.provider,
        "provider_event_id": stored.provider_event_id,
        "kind": stored.kind,
        "title": stored.title,
        "place": stored.place,
        "magnitude": stored.magnitude,
        "depth_km": stored.depth_km,
        "latitude": stored.latitude,
        "longitude": stored.longitude,
        "event_at": stored.event_at,
        "provider_updated_at": stored.provider_updated_at,
        "retrieved_at": stored.retrieved_at,
        "review_status": stored.review_status,
        "source_url": stored.source_url,
        "version": stored.version,
    }


def test_empty_list_and_get(database_session):
    repository = EarthquakeRepository()

    assert repository.list_recent(database_session) == []
    assert repository.get(database_session, "usgs:missing") is None


def test_insert_persists_exact_fields_and_stable_id(database_session):
    repository = EarthquakeRepository()
    expected = event()

    repository.upsert_many(database_session, [expected])
    stored = repository.get(database_session, expected.id)

    assert stored is not None
    assert persisted_values(stored) == asdict(expected)
    assert stored.created_at.tzinfo is not None
    assert stored.updated_at.tzinfo is not None
    assert repository.get(database_session, "abc123") is None


def test_list_recent_has_deterministic_order(database_session):
    repository = EarthquakeRepository()
    earliest = event("early", event_at=NOW - timedelta(hours=2))
    later_b = event("b", event_at=NOW - timedelta(hours=1))
    later_a = event("a", event_at=NOW - timedelta(hours=1))
    repository.upsert_many(database_session, [earliest, later_b, later_a])

    assert [item.id for item in repository.list_recent(database_session)] == [
        later_a.id,
        later_b.id,
        earliest.id,
    ]


def test_newer_update_replaces_mutable_fields_but_preserves_created_at(
    database_session,
):
    repository = EarthquakeRepository()
    original = event()
    repository.upsert_many(database_session, [original])
    stored = repository.get(database_session, original.id)
    assert stored is not None
    created_at = stored.created_at
    updated_at = stored.updated_at
    newer = replace(
        original,
        title="Revised earthquake title",
        magnitude=5.4,
        provider_updated_at=original.provider_updated_at + timedelta(minutes=1),
        retrieved_at=original.retrieved_at + timedelta(minutes=1),
        version=2,
    )

    repository.upsert_many(database_session, [newer])
    database_session.expire_all()
    stored = repository.get(database_session, original.id)

    assert stored is not None
    assert stored.title == newer.title
    assert stored.magnitude == newer.magnitude
    assert stored.provider_updated_at == newer.provider_updated_at
    assert stored.version == 2
    assert stored.created_at == created_at
    assert stored.updated_at > updated_at


@pytest.mark.parametrize("offset", [timedelta(0), -timedelta(minutes=1)])
def test_equal_or_older_update_does_not_overwrite(database_session, offset):
    repository = EarthquakeRepository()
    current = event()
    repository.upsert_many(database_session, [current])
    database_session.expire_all()
    before = repository.get(database_session, current.id)
    assert before is not None
    before_values = persisted_values(before)
    created_at = before.created_at
    updated_at = before.updated_at
    stale = replace(
        current,
        title="Stale title",
        magnitude=9.9,
        provider_updated_at=current.provider_updated_at + offset,
        retrieved_at=current.retrieved_at + timedelta(hours=1),
        version=9,
    )

    repository.upsert_many(database_session, [stale])
    database_session.expire_all()
    stored = repository.get(database_session, current.id)

    assert stored is not None
    assert persisted_values(stored) == before_values
    assert stored.created_at == created_at
    assert stored.updated_at == updated_at


def test_batch_upsert(database_session):
    repository = EarthquakeRepository()
    events = [event("one"), event("two"), event("three")]

    repository.upsert_many(database_session, events)

    assert {item.id for item in repository.list_recent(database_session)} == {
        item.id for item in events
    }


def test_reconcile_snapshot_removes_only_absent_provider_events(database_session):
    repository = EarthquakeRepository()
    retained = event("retained")
    removed = event("removed")
    future_provider = replace(
        event("future"),
        id="future:future",
        provider="future",
    )
    database_session.execute(
        insert(Earthquake),
        [asdict(retained), asdict(removed), asdict(future_provider)],
    )

    repository.delete_absent(database_session, "usgs", {"retained"})

    assert repository.get(database_session, retained.id) is not None
    assert repository.get(database_session, removed.id) is None
    assert repository.get(database_session, future_provider.id) is not None


def test_reconcile_empty_snapshot_removes_all_provider_events(database_session):
    repository = EarthquakeRepository()
    repository.upsert_many(database_session, [event("one"), event("two")])

    repository.delete_absent(database_session, "usgs", set())

    assert repository.list_recent(database_session) == []


def test_unique_provider_event_constraint(database_session):
    first = event()
    duplicate = replace(first, id="usgs:different-id")
    values = [asdict(first), asdict(duplicate)]

    with pytest.raises(IntegrityError):
        with database_session.begin_nested():
            database_session.execute(insert(Earthquake), values)


@pytest.mark.parametrize(
    ("field", "invalid_value"),
    [
        ("latitude", -90.1),
        ("latitude", 90.1),
        ("longitude", -180.1),
        ("longitude", 180.1),
        ("version", 0),
    ],
)
def test_database_constraints_reject_invalid_values(
    database_session, field, invalid_value
):
    invalid = replace(event(), **{field: invalid_value})

    with pytest.raises(IntegrityError):
        with database_session.begin_nested():
            database_session.execute(insert(Earthquake), [asdict(invalid)])


def test_provider_attempt_creation(database_session):
    repository = ProviderSyncRepository()

    stored = repository.record_attempt(database_session, "usgs", NOW, None)

    assert stored.provider == "usgs"
    assert stored.last_attempt_at == NOW
    assert stored.last_successful_refresh_at is None
    assert stored.last_error_code is None
    assert repository.get(database_session, "usgs") is stored


def test_failed_attempt_preserves_success_and_stores_error(database_session):
    repository = ProviderSyncRepository()
    repository.record_success(database_session, "usgs", NOW)
    attempted_at = NOW + timedelta(minutes=5)

    stored = repository.record_attempt(
        database_session, "usgs", attempted_at, "provider_timeout"
    )

    assert stored.last_attempt_at == attempted_at
    assert stored.last_successful_refresh_at == NOW
    assert stored.last_error_code == "provider_timeout"


def test_success_sets_both_timestamps_and_clears_error(database_session):
    repository = ProviderSyncRepository()
    repository.record_attempt(database_session, "usgs", NOW, "provider_timeout")
    succeeded_at = NOW + timedelta(minutes=5)

    stored = repository.record_success(database_session, "usgs", succeeded_at)

    assert stored.last_attempt_at == succeeded_at
    assert stored.last_successful_refresh_at == succeeded_at
    assert stored.last_error_code is None


def test_repository_methods_do_not_commit(database_session, monkeypatch):
    def fail_commit():
        pytest.fail("repository committed the caller transaction")

    monkeypatch.setattr(database_session, "commit", fail_commit)
    earthquakes = EarthquakeRepository()
    sync = ProviderSyncRepository()

    earthquakes.upsert_many(database_session, [event()])
    earthquakes.list_recent(database_session)
    earthquakes.get(database_session, "usgs:abc123")
    sync.acquire_refresh_lock(database_session, "usgs")
    sync.record_attempt(database_session, "usgs", NOW, None)
    sync.record_success(database_session, "usgs", NOW)
    sync.get(database_session, "usgs")


def test_direct_sql_updates_advance_earthquake_updated_at_repeatedly(
    database_session,
):
    repository = EarthquakeRepository()
    earthquake = event()
    repository.upsert_many(database_session, [earthquake])
    original = repository.get(database_session, earthquake.id)
    assert original is not None
    original_updated_at = original.updated_at

    database_session.execute(
        text("UPDATE earthquakes SET title = :title WHERE id = :id"),
        {"title": "First direct update", "id": earthquake.id},
    )
    first_updated_at = database_session.execute(
        text("SELECT updated_at FROM earthquakes WHERE id = :id"),
        {"id": earthquake.id},
    ).scalar_one()
    database_session.execute(
        text("UPDATE earthquakes SET title = :title WHERE id = :id"),
        {"title": "Second direct update", "id": earthquake.id},
    )
    second_updated_at = database_session.execute(
        text("SELECT updated_at FROM earthquakes WHERE id = :id"),
        {"id": earthquake.id},
    ).scalar_one()

    assert first_updated_at > original_updated_at
    assert second_updated_at > first_updated_at


def test_direct_sql_updates_advance_provider_sync_updated_at_repeatedly(
    database_session,
):
    repository = ProviderSyncRepository()
    provider_sync = repository.record_attempt(database_session, "usgs", NOW, None)
    original_updated_at = provider_sync.updated_at

    database_session.execute(
        text(
            "UPDATE provider_sync "
            "SET last_error_code = :error_code WHERE provider = :provider"
        ),
        {"error_code": "first_error", "provider": "usgs"},
    )
    first_updated_at = database_session.execute(
        text("SELECT updated_at FROM provider_sync WHERE provider = :provider"),
        {"provider": "usgs"},
    ).scalar_one()
    database_session.execute(
        text(
            "UPDATE provider_sync "
            "SET last_error_code = :error_code WHERE provider = :provider"
        ),
        {"error_code": "second_error", "provider": "usgs"},
    )
    second_updated_at = database_session.execute(
        text("SELECT updated_at FROM provider_sync WHERE provider = :provider"),
        {"provider": "usgs"},
    ).scalar_one()

    assert first_updated_at > original_updated_at
    assert second_updated_at > first_updated_at


@pytest.mark.parametrize("model", [Earthquake, ProviderSync])
def test_updated_at_metadata_declares_server_side_update_generation(model):
    updated_at = model.__table__.c.updated_at

    assert updated_at.onupdate is None
    assert updated_at.server_onupdate is not None
