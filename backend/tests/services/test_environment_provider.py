from datetime import UTC, datetime, timedelta

import httpx
import pytest

from app.schemas.navigation import Coordinate
from app.services.environment_provider import (
    CachedEnvironmentProvider,
    ContextAnalysisUnavailable,
    EnvironmentSnapshot,
    LiveEnvironmentProvider,
    build_overpass_query,
    parse_overpass_response,
)

NOW = datetime(2026, 8, 17, 13, 42, tzinfo=UTC)
ORIGIN = Coordinate(latitude=16.856152, longitude=96.130522)


def test_overpass_query_requests_full_geometry_for_all_environment_categories():
    query = build_overpass_query(ORIGIN, 1000.0, 10.0)

    assert "out tags geom;" in query
    assert "way[building]" in query
    assert "leisure" in query
    assert "natural=tree" in query
    assert "nwr[power]" in query
    assert "nwr[waterway]" in query
    assert "natural=water" in query
    assert "center" not in query


def test_parse_overpass_response_retains_geometry_and_selection_tags():
    observation = parse_overpass_response(
        {
            "elements": [
                {
                    "type": "way",
                    "id": 101,
                    "tags": {
                        "building": "yes",
                        "building:levels": "4",
                        "name": "Mapped building",
                        "access": "private",
                        "indoor": "yes",
                        "covered": "yes",
                    },
                    "geometry": [
                        {"lat": 16.85, "lon": 96.13},
                        {"lat": 16.85, "lon": 96.131},
                        {"lat": 16.851, "lon": 96.131},
                        {"lat": 16.851, "lon": 96.13},
                        {"lat": 16.85, "lon": 96.13},
                    ],
                },
                {
                    "type": "way",
                    "id": 102,
                    "tags": {
                        "leisure": "park",
                        "name": "Public park",
                        "access": "yes",
                        "covered": "no",
                    },
                    "geometry": [
                        {"lat": 16.852, "lon": 96.132},
                        {"lat": 16.852, "lon": 96.134},
                        {"lat": 16.854, "lon": 96.134},
                        {"lat": 16.854, "lon": 96.132},
                        {"lat": 16.852, "lon": 96.132},
                    ],
                },
                {
                    "type": "way",
                    "id": 103,
                    "tags": {
                        "leisure": "pitch",
                        "name": "Private pitch",
                        "access": "private",
                    },
                    "geometry": [
                        {"lat": 16.855, "lon": 96.135},
                        {"lat": 16.855, "lon": 96.136},
                        {"lat": 16.856, "lon": 96.136},
                        {"lat": 16.856, "lon": 96.135},
                    ],
                },
                {
                    "type": "node",
                    "id": 104,
                    "lat": 16.857,
                    "lon": 96.137,
                    "tags": {"natural": "tree"},
                },
                {
                    "type": "relation",
                    "id": 105,
                    "tags": {"natural": "wood", "name": "Mapped woodland"},
                    "geometry": [
                        {"lat": 16.858, "lon": 96.138},
                        {"lat": 16.858, "lon": 96.139},
                        {"lat": 16.859, "lon": 96.139},
                        {"lat": 16.859, "lon": 96.138},
                    ],
                },
                {
                    "type": "way",
                    "id": 106,
                    "tags": {"power": "line", "name": "Power corridor"},
                    "geometry": [
                        {"lat": 16.86, "lon": 96.14},
                        {"lat": 16.861, "lon": 96.141},
                    ],
                },
                {
                    "type": "way",
                    "id": 107,
                    "tags": {"waterway": "river", "name": "Mapped waterway"},
                    "geometry": [
                        {"lat": 16.862, "lon": 96.142},
                        {"lat": 16.863, "lon": 96.143},
                    ],
                },
                {
                    "type": "way",
                    "id": 108,
                    "tags": {
                        "emergency": "assembly_point",
                        "name": "Covered assembly point",
                        "access": "permissive",
                        "indoor": "yes",
                        "covered": "yes",
                    },
                    "geometry": [
                        {"lat": 16.864, "lon": 96.144},
                        {"lat": 16.864, "lon": 96.145},
                        {"lat": 16.865, "lon": 96.145},
                        {"lat": 16.865, "lon": 96.144},
                    ],
                },
            ]
        }
    )

    assert len(observation.buildings) == 1
    building = observation.buildings[0]
    assert len(building.points) == 5
    assert building.height_m == 12.0
    assert building.name == "Mapped building"
    assert building.access == "private"
    assert building.is_indoor_or_covered
    assert building.area_m2 is not None

    assert [feature.name for feature in observation.open_spaces] == [
        "Public park",
        "Covered assembly point",
    ]
    assert observation.open_spaces[1].indoor == "yes"
    assert observation.open_spaces[1].covered == "yes"
    assert all(feature.name != "Private pitch" for feature in observation.open_spaces)
    assert observation.trees == ((96.137, 16.857),)
    assert observation.wooded_areas[0].name == "Mapped woodland"
    assert observation.power_features[0].feature_type == "power:line"
    assert observation.water_features[0].feature_type == "waterway:river"
    assert observation.data_complete


def test_parse_overpass_response_marks_incomplete_geometry():
    observation = parse_overpass_response(
        {
            "elements": [
                {
                    "type": "way",
                    "id": 201,
                    "tags": {"building": "yes"},
                    "center": {"lat": 16.85, "lon": 96.13},
                },
                {
                    "type": "node",
                    "id": 202,
                    "tags": {"natural": "tree"},
                    "lat": "invalid",
                    "lon": 96.14,
                },
            ]
        }
    )

    assert len(observation.buildings) == 1
    assert observation.buildings[0].points == ((96.13, 16.85),)
    assert observation.buildings[0].geometry_complete is False
    assert observation.trees == ()
    assert observation.data_complete is False
    assert "partial geometry" in observation.uncertainty_notice


def test_live_provider_parses_overpass_and_elevation_responses():
    observed = {}

    def handler(request):
        if request.url.host == "overpass.test":
            query = request.url.params["data"]
            observed["query"] = query
            return httpx.Response(
                200,
                json={
                    "elements": [
                        {
                            "type": "way",
                            "id": 301,
                            "tags": {"leisure": "park", "name": "Named park"},
                            "geometry": [
                                {"lat": 16.85, "lon": 96.13},
                                {"lat": 16.85, "lon": 96.131},
                                {"lat": 16.851, "lon": 96.131},
                            ],
                        }
                    ]
                },
                request=request,
            )
        return httpx.Response(
            200,
            json={
                "results": [
                    {"elevation": 10.0},
                    {"elevation": 12.5},
                ]
            },
            request=request,
        )

    client = httpx.Client(transport=httpx.MockTransport(handler))
    provider = LiveEnvironmentProvider(
        overpass_url="https://overpass.test/api/interpreter",
        elevation_url="https://elevation.test/v1",
        timeout_seconds=5.0,
        http_client=client,
        clock=lambda: NOW,
    )
    try:
        snapshot = provider.observe(
            ORIGIN,
            (
                ORIGIN,
                Coordinate(latitude=16.86, longitude=96.14),
            ),
            1000.0,
            include_obstacles=True,
            include_elevation=True,
            include_water=True,
        )
    finally:
        provider.close()
        client.close()

    assert "out tags geom;" in observed["query"]
    assert snapshot.source == (
        "OpenStreetMap via Overpass + Configured elevation provider"
    )
    assert snapshot.observed_at == NOW
    assert snapshot.open_spaces[0].name == "Named park"
    assert snapshot.elevations_m == (10.0, 12.5)
    assert "not confirmed absent" in snapshot.uncertainty_notice


class StubEnvironmentProvider:
    def __init__(self, snapshot: EnvironmentSnapshot | Exception):
        self.snapshot = snapshot
        self.calls = 0
        self.kwargs = []
        self.closed = False

    def observe(self, *args, **kwargs):
        self.calls += 1
        self.kwargs.append(kwargs)
        if isinstance(self.snapshot, Exception):
            raise self.snapshot
        return self.snapshot

    def close(self):
        self.closed = True


def _snapshot() -> EnvironmentSnapshot:
    return EnvironmentSnapshot(
        buildings=(),
        trees=(),
        elevations_m=(),
        observed_at=NOW,
        source="OSM test observation",
    )


def test_cached_provider_hits_with_coarse_key_and_marks_fresh_cache():
    clock_now = [NOW]
    upstream = StubEnvironmentProvider(_snapshot())
    provider = CachedEnvironmentProvider(
        upstream,
        fresh_ttl_seconds=60,
        clock=lambda: clock_now[0],
    )
    nearby_origin = Coordinate(latitude=16.856901, longitude=96.130901)

    first = provider.observe(
        ORIGIN,
        (),
        100.0,
        include_obstacles=True,
        include_elevation=False,
    )
    second = provider.observe(
        nearby_origin,
        (),
        100.0,
        include_obstacles=True,
        include_elevation=False,
    )

    assert upstream.calls == 1
    assert first.cache_status == "live"
    assert second.cache_status == "fresh"
    assert "coarse-area cache hit" in second.source
    assert "source timestamp" in second.uncertainty_notice


def test_cached_provider_uses_timestamped_stale_fallback_after_failure():
    clock_now = [NOW]
    upstream = StubEnvironmentProvider(_snapshot())
    provider = CachedEnvironmentProvider(
        upstream,
        fresh_ttl_seconds=60,
        clock=lambda: clock_now[0],
    )
    provider.observe(
        ORIGIN,
        (),
        100.0,
        include_obstacles=True,
        include_elevation=False,
    )
    clock_now[0] = NOW + timedelta(seconds=61)
    upstream.snapshot = ContextAnalysisUnavailable()

    stale = provider.observe(
        ORIGIN,
        (),
        100.0,
        include_obstacles=True,
        include_elevation=False,
    )

    assert upstream.calls == 2
    assert stale.cache_status == "stale"
    assert stale.observed_at == NOW
    assert "stale coarse-area cache fallback" in stale.source
    assert "live environment provider failed" in stale.uncertainty_notice
    assert NOW.isoformat() in stale.uncertainty_notice


def test_cached_provider_separates_water_requirements_in_cache_key():
    upstream = StubEnvironmentProvider(_snapshot())
    provider = CachedEnvironmentProvider(upstream)

    provider.observe(
        ORIGIN,
        (),
        100.0,
        include_obstacles=False,
        include_elevation=True,
        include_water=False,
    )
    provider.observe(
        ORIGIN,
        (),
        100.0,
        include_obstacles=False,
        include_elevation=True,
        include_water=True,
    )
    provider.observe(
        ORIGIN,
        (),
        100.0,
        include_obstacles=False,
        include_elevation=True,
        include_water=True,
    )

    assert upstream.calls == 2
    assert upstream.kwargs[0] == {
        "include_obstacles": False,
        "include_elevation": True,
    }
    assert upstream.kwargs[1] == {
        "include_obstacles": False,
        "include_elevation": True,
        "include_water": True,
    }


def test_cached_provider_evicts_oldest_entry_and_does_not_persist_exact_origin():
    upstream = StubEnvironmentProvider(_snapshot())
    provider = CachedEnvironmentProvider(upstream, max_entries=2)
    origins = (
        Coordinate(latitude=16.80, longitude=96.10),
        Coordinate(latitude=16.82, longitude=96.10),
        Coordinate(latitude=16.84, longitude=96.10),
    )

    for origin in origins:
        provider.observe(
            origin,
            (),
            100.0,
            include_obstacles=True,
            include_elevation=False,
        )

    assert provider.cache_size == 2
    assert upstream.calls == 3
    assert str(origins[0].latitude) not in repr(provider._cache)
    assert str(origins[0].longitude) not in repr(provider._cache)

    provider.observe(
        origins[0],
        (),
        100.0,
        include_obstacles=True,
        include_elevation=False,
    )
    assert upstream.calls == 4


def test_cached_provider_without_entry_preserves_unavailable_behavior():
    upstream = StubEnvironmentProvider(ContextAnalysisUnavailable())
    provider = CachedEnvironmentProvider(upstream)

    with pytest.raises(ContextAnalysisUnavailable):
        provider.observe(
            ORIGIN,
            (),
            100.0,
            include_obstacles=True,
            include_elevation=False,
        )

    assert upstream.calls == 1


def test_cached_provider_delegates_close():
    upstream = StubEnvironmentProvider(_snapshot())
    provider = CachedEnvironmentProvider(upstream)

    provider.close()

    assert upstream.closed
