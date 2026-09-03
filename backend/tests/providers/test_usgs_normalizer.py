import copy
import json
from datetime import UTC, datetime, timedelta, timezone
from pathlib import Path
from typing import cast, get_type_hints

import pytest

from app.providers.usgs.normalizer import (
    MAX_LATITUDE,
    MAX_LONGITUDE,
    MIN_LATITUDE,
    MIN_LONGITUDE,
    InvalidProviderPayload,
    normalize_feed,
)

RETRIEVED_AT = datetime(2024, 3, 9, 16, 2, tzinfo=UTC)


def feature(**overrides):
    value = {
        "type": "Feature",
        "id": "us7000test",
        "properties": {
            "mag": 5.2,
            "place": "SIMULATION: 10 km NW of Test City",
            "time": 1710000000000,
            "updated": 1710000060000,
            "title": "SIMULATION: M 5.2 - Test City",
            "status": "reviewed",
            "url": "https://earthquake.usgs.gov/earthquakes/eventpage/us7000test",
        },
        "geometry": {"type": "Point", "coordinates": [96.1, 16.7, 12.5]},
    }
    value.update(overrides)
    return value


def feed(*features):
    return {"type": "FeatureCollection", "features": list(features)}


def test_normalize_feed_preserves_payload_annotation_contract():
    assert get_type_hints(normalize_feed)["payload"] == dict[str, object]


def test_valid_feature_maps_exact_normalized_contract():
    result = normalize_feed(feed(feature()), RETRIEVED_AT)

    assert result.rejected_count == 0
    assert len(result.events) == 1
    event = result.events[0]
    assert event.id == "usgs:us7000test"
    assert event.provider == "usgs"
    assert event.provider_event_id == "us7000test"
    assert event.kind == "earthquake_information"
    assert event.title == "SIMULATION: M 5.2 - Test City"
    assert event.place == "SIMULATION: 10 km NW of Test City"
    assert event.magnitude == 5.2
    assert event.depth_km == 12.5
    assert event.latitude == 16.7
    assert event.longitude == 96.1
    assert event.event_at == datetime(2024, 3, 9, 16, 0, tzinfo=UTC)
    assert event.provider_updated_at == datetime(2024, 3, 9, 16, 1, tzinfo=UTC)
    assert event.retrieved_at == RETRIEVED_AT
    assert event.review_status == "reviewed"
    assert event.source_url == (
        "https://earthquake.usgs.gov/earthquakes/eventpage/us7000test"
    )
    assert event.version == 1
    assert not hasattr(event, "severity")


@pytest.mark.parametrize(
    ("longitude", "latitude"),
    [
        (MIN_LONGITUDE, MIN_LATITUDE),
        (MAX_LONGITUDE, MAX_LATITUDE),
    ],
)
def test_coverage_boundaries_are_inclusive(longitude, latitude):
    earthquake = feature()
    earthquake["geometry"]["coordinates"] = [longitude, latitude, 1.0]

    result = normalize_feed(feed(earthquake), RETRIEVED_AT)

    assert [event.provider_event_id for event in result.events] == ["us7000test"]
    assert result.rejected_count == 0


@pytest.mark.parametrize(
    ("longitude", "latitude"),
    [
        (MIN_LONGITUDE - 0.001, 20.0),
        (MAX_LONGITUDE + 0.001, 20.0),
        (96.0, MIN_LATITUDE - 0.001),
        (96.0, MAX_LATITUDE + 0.001),
    ],
)
def test_valid_points_outside_coverage_are_ignored(longitude, latitude):
    earthquake = feature()
    earthquake["geometry"]["coordinates"] = [longitude, latitude, 1.0]

    result = normalize_feed(feed(earthquake), RETRIEVED_AT)

    assert result.events == ()
    assert result.rejected_count == 0


def test_mixed_fixture_preserves_valid_and_counts_only_malformed():
    fixture_path = Path(__file__).parents[1] / "fixtures" / "usgs_mixed_feed.json"
    payload = json.loads(fixture_path.read_text(encoding="utf-8"))

    result = normalize_feed(payload, RETRIEVED_AT)

    assert [event.provider_event_id for event in result.events] == ["us7000test"]
    assert result.rejected_count == 1


def test_empty_valid_feed_succeeds():
    result = normalize_feed(feed(), RETRIEVED_AT)

    assert result.events == ()
    assert result.rejected_count == 0


@pytest.mark.parametrize(
    "payload",
    [
        [],
        None,
        "FeatureCollection",
        42,
        True,
        {},
        {"type": "Feature", "features": []},
        {"type": "FeatureCollection", "features": {}},
    ],
)
def test_invalid_top_level_payload_raises(payload):
    with pytest.raises(InvalidProviderPayload):
        normalize_feed(cast(dict[str, object], payload), RETRIEVED_AT)


def test_usgs_subdomain_source_url_is_accepted():
    earthquake = feature()
    earthquake["properties"]["url"] = "https://example.earthquake.usgs.gov/event/test"

    result = normalize_feed(feed(earthquake), RETRIEVED_AT)

    assert result.events[0].source_url == (
        "https://example.earthquake.usgs.gov/event/test"
    )


def test_naive_retrieved_at_makes_top_level_call_invalid():
    with pytest.raises(InvalidProviderPayload):
        normalize_feed(feed(), datetime(2024, 3, 9, 16, 2))


@pytest.mark.parametrize(
    "mutation",
    [
        lambda value: value.update(id=""),
        lambda value: value.update(id=7),
        lambda value: value.update(properties=[]),
        lambda value: value.update(geometry={"type": "LineString", "coordinates": []}),
        lambda value: value.update(geometry={"type": "Point", "coordinates": [96, 20]}),
        lambda value: value.update(
            geometry={"type": "Point", "coordinates": [96, 20, 1, 2]}
        ),
        lambda value: value["geometry"].update(coordinates=[float("nan"), 20, 1]),
        lambda value: value["geometry"].update(coordinates=[96, float("inf"), 1]),
        lambda value: value["geometry"].update(coordinates=[96, 20, -float("inf")]),
        lambda value: value["geometry"].update(coordinates=[True, 20, 1]),
        lambda value: value["geometry"].update(coordinates=[181, 20, 1]),
        lambda value: value["geometry"].update(coordinates=[96, -91, 1]),
        lambda value: value["properties"].update(mag=float("nan")),
        lambda value: value["properties"].update(mag=True),
        lambda value: value["properties"].update(time=1710000000000.5),
        lambda value: value["properties"].update(time=float("inf")),
        lambda value: value["properties"].update(updated=True),
        lambda value: value["properties"].update(updated=10**30),
        lambda value: value["properties"].update(title=""),
        lambda value: value["properties"].update(title=5),
        lambda value: value["properties"].update(place=" "),
        lambda value: value["properties"].update(status=""),
        lambda value: value["properties"].update(status=3),
        lambda value: value["properties"].update(
            url="http://earthquake.usgs.gov/event/test"
        ),
        lambda value: value["properties"].update(
            url="https://earthquake.usgs.gov.evil.example/event/test"
        ),
        lambda value: value["properties"].update(url="not-a-url"),
    ],
)
def test_invalid_feature_is_rejected_individually(mutation):
    invalid = copy.deepcopy(feature())
    mutation(invalid)

    result = normalize_feed(feed(invalid, feature(id="us7000valid")), RETRIEVED_AT)

    assert [event.provider_event_id for event in result.events] == ["us7000valid"]
    assert result.rejected_count == 1


@pytest.mark.parametrize("status", [None, "automatic"])
def test_review_status_can_be_null_or_populated(status):
    earthquake = feature()
    earthquake["properties"]["status"] = status

    result = normalize_feed(feed(earthquake), RETRIEVED_AT)

    assert result.events[0].review_status == status


def test_times_are_converted_and_normalized_to_utc():
    retrieved_at = datetime(
        2024, 3, 9, 21, 32, tzinfo=timezone(timedelta(hours=5, minutes=30))
    )

    result = normalize_feed(feed(feature()), retrieved_at)

    event = result.events[0]
    assert event.event_at == datetime(2024, 3, 9, 16, 0, tzinfo=UTC)
    assert event.provider_updated_at == datetime(2024, 3, 9, 16, 1, tzinfo=UTC)
    assert event.retrieved_at == RETRIEVED_AT


def test_normalized_records_and_result_are_immutable():
    result = normalize_feed(feed(feature()), RETRIEVED_AT)

    with pytest.raises((AttributeError, TypeError)):
        result.rejected_count = 2
    with pytest.raises((AttributeError, TypeError)):
        result.events[0].title = "changed"
