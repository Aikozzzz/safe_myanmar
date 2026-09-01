from datetime import UTC, datetime

import pytest

from app.schemas.navigation import (
    ContextAreaRequest,
    Coordinate,
    Hazard,
    PolygonGeometry,
)
from app.services.real_context_analysis import (
    BuildingFeature,
    ContextAnalysisUnavailable,
    EnvironmentSnapshot,
    OpenSpaceFeature,
    PowerFeature,
    RealContextAnalyzer,
    WaterFeature,
    WoodedAreaFeature,
    _candidate_coordinates,
)

NOW = datetime(2026, 8, 17, 13, 42, tzinfo=UTC)
ORIGIN = Coordinate(latitude=16.856152, longitude=96.130522)


class StubEnvironmentProvider:
    def __init__(self, snapshot_factory):
        self.snapshot_factory = snapshot_factory
        self.calls = []

    def observe(
        self,
        origin,
        candidates,
        radius_m,
        *,
        include_obstacles,
        include_elevation,
        include_water=False,
    ):
        self.calls.append(
            (
                origin,
                tuple(candidates),
                radius_m,
                include_obstacles,
                include_elevation,
                include_water,
            )
        )
        return self.snapshot_factory(candidates)

    def close(self):
        pass


def request(disaster_type, scenario="general"):
    return ContextAreaRequest(
        origin=ORIGIN,
        disaster_type=disaster_type,
        scenario=scenario,
    )


def current_hazard(disaster_type):
    return Hazard(
        id=f"hazard-{disaster_type}",
        name=f"Current {disaster_type} hazard",
        disaster_type=disaster_type,
        geometry=PolygonGeometry(
            coordinates=[
                [
                    (96.20, 16.95),
                    (96.21, 16.95),
                    (96.21, 16.96),
                    (96.20, 16.96),
                    (96.20, 16.95),
                ]
            ]
        ),
        source="Snapshot test data",
        data_at=NOW,
        simulation=False,
    )


def polygon(
    min_longitude: float,
    min_latitude: float,
    max_longitude: float,
    max_latitude: float,
):
    return (
        (min_longitude, min_latitude),
        (max_longitude, min_latitude),
        (max_longitude, max_latitude),
        (min_longitude, max_latitude),
        (min_longitude, min_latitude),
    )


def around(coordinate, half_width=0.00025):
    return polygon(
        coordinate.longitude - half_width,
        coordinate.latitude - half_width,
        coordinate.longitude + half_width,
        coordinate.latitude + half_width,
    )


def flood_hazard_at(coordinate):
    return Hazard(
        id="hazard-flood-at-candidate",
        name="Current flood hazard",
        disaster_type="flood",
        geometry=PolygonGeometry(coordinates=[list(around(coordinate))]),
        source="Snapshot test data",
        data_at=NOW,
        simulation=False,
    )


def open_space(
    name: str,
    min_longitude: float,
    min_latitude: float,
    max_longitude: float,
    max_latitude: float,
    *,
    access: str | None = "yes",
    indoor: str | None = None,
    covered: str | None = None,
):
    return OpenSpaceFeature(
        points=polygon(min_longitude, min_latitude, max_longitude, max_latitude),
        name=name,
        access=access,
        indoor=indoor,
        covered=covered,
    )


def far_supporting_building():
    return BuildingFeature(
        points=polygon(96.145, 16.87, 96.146, 16.871),
        height_m=30,
    )


def supporting_snapshot(
    open_spaces,
    *,
    buildings=None,
    trees=((96.12, 16.84),),
    wooded_areas=(),
    power_features=(),
    data_complete=True,
):
    return EnvironmentSnapshot(
        buildings=tuple(buildings or (far_supporting_building(),)),
        trees=trees,
        elevations_m=(),
        observed_at=NOW,
        source="OSM test snapshot",
        open_spaces=tuple(open_spaces),
        wooded_areas=tuple(wooded_areas),
        power_features=tuple(power_features),
        data_complete=data_complete,
    )


def test_earthquake_prefers_mapped_open_clearance_without_simulation():
    provider = StubEnvironmentProvider(
        lambda candidates: supporting_snapshot(
            (
                open_space("Public Park", 96.131, 16.855, 96.133, 16.857),
                open_space("Community Pitch", 96.136, 16.855, 96.138, 16.857),
            )
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("earthquake", "outdoors_after_shaking"),
        (current_hazard("earthquake"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert response.items
    assert response.simulation is False
    assert {item.name for item in response.items} == {
        "Public Park",
        "Community Pitch",
    }
    assert any("high buildings" in reason for reason in response.items[0].rationale)
    assert "OpenStreetMap" in response.items[0].uncertainty_notice
    assert provider.calls[0][1] == (ORIGIN,)
    assert provider.calls[0][3:] == (True, False, False)


def test_earthquake_filters_private_and_covered_open_spaces():
    provider = StubEnvironmentProvider(
        lambda candidates: supporting_snapshot(
            (
                open_space("Public Park", 96.131, 16.855, 96.133, 16.857),
                open_space(
                    "Private Pitch",
                    96.136,
                    16.855,
                    96.138,
                    16.857,
                    access="private",
                ),
                open_space(
                    "Indoor Hall",
                    96.141,
                    16.855,
                    96.143,
                    16.857,
                    indoor="yes",
                ),
                open_space(
                    "Covered Field",
                    96.146,
                    16.855,
                    96.148,
                    16.857,
                    covered="yes",
                ),
            )
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("earthquake", "outdoors_after_shaking"),
        (current_hazard("earthquake"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert [item.name for item in response.items] == ["Public Park"]


def test_earthquake_uses_polygon_edge_for_building_clearance():
    long_low_building = BuildingFeature(
        points=polygon(96.129, 16.8563, 96.135, 16.8564),
        height_m=3,
    )
    provider = StubEnvironmentProvider(
        lambda candidates: supporting_snapshot(
            (open_space("Edge-Test Field", 96.130, 16.855, 96.134, 16.857),),
            buildings=(long_low_building, far_supporting_building()),
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("earthquake", "outdoors_after_shaking"),
        (current_hazard("earthquake"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert [item.name for item in response.items] == ["Edge-Test Field"]
    assert 25 < response.items[0].metrics.building_clearance_m < 60


def test_earthquake_ranks_clearer_named_fields_before_closer_field():
    near_building = BuildingFeature(
        points=polygon(96.132, 16.856, 96.1325, 16.8565),
        height_m=30,
    )
    near_tree = (96.133, 16.8565)
    provider = StubEnvironmentProvider(
        lambda candidates: supporting_snapshot(
            (
                open_space("Near Field", 96.130, 16.855, 96.132, 16.857),
                open_space("Far Clear Field", 96.137, 16.855, 96.139, 16.857),
            ),
            buildings=(near_building, far_supporting_building()),
            trees=(near_tree, (96.12, 16.84)),
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("earthquake", "outdoors_after_shaking"),
        (current_hazard("earthquake"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert [item.name for item in response.items] == ["Far Clear Field", "Near Field"]
    assert response.items[0].distance_m > response.items[1].distance_m


def test_earthquake_includes_power_and_woodland_clearance_in_filtering():
    power_line = PowerFeature(
        points=((96.1312, 16.854), (96.1312, 16.858)),
        name="Mapped power line",
        feature_type="power:line",
    )
    woodland = WoodedAreaFeature(
        points=polygon(96.136, 16.854, 96.137, 16.858),
        name="Mapped woodland",
        feature_type="wood",
    )
    provider = StubEnvironmentProvider(
        lambda candidates: supporting_snapshot(
            (
                open_space("Powered Field", 96.130, 16.855, 96.132, 16.857),
                open_space("Wooded Field", 96.135, 16.855, 96.139, 16.857),
            ),
            power_features=(power_line,),
            wooded_areas=(woodland,),
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("earthquake", "outdoors_after_shaking"),
        (current_hazard("earthquake"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert response.items == []
    assert "clearance criteria" in response.uncertainty_notice


def test_earthquake_missing_environment_data_fails_closed():
    provider = StubEnvironmentProvider(
        lambda candidates: supporting_snapshot(
            (open_space("Incomplete Field", 96.131, 16.855, 96.133, 16.857),),
            buildings=(
                BuildingFeature(
                    points=polygon(96.145, 16.87, 96.146, 16.871),
                    height_m=None,
                ),
            ),
            data_complete=False,
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("earthquake", "outdoors_after_shaking"),
        (current_hazard("earthquake"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert response.items == []
    assert "incomplete" in response.uncertainty_notice


def test_flood_prefers_higher_mapped_ground_than_origin():
    provider = StubEnvironmentProvider(
        lambda candidates: EnvironmentSnapshot(
            buildings=(),
            trees=(),
            elevations_m=(
                10.0,
                *(
                    15.0 if index % 2 == 0 else 8.0
                    for index, _candidate in enumerate(candidates[1:])
                ),
            ),
            observed_at=NOW,
            source="OpenTopoData test snapshot",
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("flood"),
        (current_hazard("flood"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert response.items
    assert response.items[0].name.startswith("Suggested higher-ground area")
    elevations = [item.metrics.relative_elevation_m for item in response.items]
    assert elevations == sorted(elevations, reverse=True)
    assert all(
        "terrain elevation" in item.uncertainty_notice for item in response.items
    )
    assert all(item.classification == "lower_exposure" for item in response.items)
    serialized = response.model_dump_json().lower()
    assert "guaranteed safe" not in serialized
    assert "flood forecast" in serialized
    assert "vertical evacuation" not in serialized
    assert len(provider.calls[0][1]) > 8
    assert provider.calls[0][3:] == (False, True, True)


def test_flood_discloses_stale_environment_data():
    provider = StubEnvironmentProvider(
        lambda candidates: EnvironmentSnapshot(
            buildings=(),
            trees=(),
            elevations_m=(10.0, *(15.0 for _candidate in candidates[1:])),
            observed_at=NOW,
            source="OpenTopoData stale snapshot",
            cache_status="stale",
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("flood"),
        (current_hazard("flood"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert response.items
    assert "stale" in response.uncertainty_notice.lower()


def test_flood_selects_local_high_points_by_elevation_then_distance():
    provider = StubEnvironmentProvider(
        lambda candidates: EnvironmentSnapshot(
            buildings=(),
            trees=(),
            elevations_m=(
                10.0,
                *(
                    20.0 if index == 0 else 16.0 if index == 1 else 12.0
                    for index, _candidate in enumerate(candidates[1:])
                ),
            ),
            observed_at=NOW,
            source="OpenTopoData test snapshot",
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("flood"),
        (current_hazard("flood"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert response.items
    assert response.items[0].metrics.relative_elevation_m == 10.0
    assert all(
        first.metrics.relative_elevation_m >= second.metrics.relative_elevation_m
        for first, second in zip(response.items, response.items[1:], strict=False)
    )
    assert response.items[0].distance_m <= 1000.0


def test_flood_rejects_candidates_inside_hazard_and_mapped_water_geometry():
    sampled_candidates = _candidate_coordinates(ORIGIN, 1000.0)
    water_candidate = sampled_candidates[0]
    hazard_candidate = sampled_candidates[1]
    wetland_candidate = sampled_candidates[2]
    waterway_candidate = sampled_candidates[3]

    def snapshot_factory(candidates):
        blocked = {
            (
                water_candidate.latitude,
                water_candidate.longitude,
            ),
            (
                hazard_candidate.latitude,
                hazard_candidate.longitude,
            ),
            (
                wetland_candidate.latitude,
                wetland_candidate.longitude,
            ),
            (
                waterway_candidate.latitude,
                waterway_candidate.longitude,
            ),
        }
        return EnvironmentSnapshot(
            buildings=(),
            trees=(),
            elevations_m=(
                10.0,
                *(
                    30.0
                    if (candidate.latitude, candidate.longitude) in blocked
                    else 15.0
                    for candidate in candidates[1:]
                ),
            ),
            observed_at=NOW,
            source="OpenTopoData test snapshot",
            water_features=(
                WaterFeature(
                    points=around(water_candidate),
                    feature_type="water_body",
                ),
                WaterFeature(
                    points=around(wetland_candidate),
                    feature_type="wetland",
                ),
                WaterFeature(
                    points=(
                        (
                            waterway_candidate.longitude - 0.001,
                            waterway_candidate.latitude,
                        ),
                        (
                            waterway_candidate.longitude + 0.001,
                            waterway_candidate.latitude,
                        ),
                    ),
                    feature_type="waterway:river",
                ),
            ),
        )

    provider = StubEnvironmentProvider(snapshot_factory)
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("flood"),
        (flood_hazard_at(hazard_candidate),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    returned_coordinates = {
        (item.coordinate.latitude, item.coordinate.longitude) for item in response.items
    }
    assert (
        water_candidate.latitude,
        water_candidate.longitude,
    ) not in returned_coordinates
    assert (
        hazard_candidate.latitude,
        hazard_candidate.longitude,
    ) not in returned_coordinates
    assert (
        wetland_candidate.latitude,
        wetland_candidate.longitude,
    ) not in returned_coordinates
    assert (
        waterway_candidate.latitude,
        waterway_candidate.longitude,
    ) not in returned_coordinates


def test_flood_rejects_clearly_inaccessible_mapped_spaces():
    sampled_candidates = _candidate_coordinates(ORIGIN, 1000.0)
    inaccessible_candidate = sampled_candidates[0]
    covered_candidate = sampled_candidates[1]

    provider = StubEnvironmentProvider(
        lambda candidates: EnvironmentSnapshot(
            buildings=(),
            trees=(),
            elevations_m=(
                10.0,
                *(
                    30.0 if candidate == inaccessible_candidate else 15.0
                    for candidate in candidates[1:]
                ),
            ),
            observed_at=NOW,
            source="OpenTopoData test snapshot",
            open_spaces=(
                OpenSpaceFeature(
                    points=around(inaccessible_candidate),
                    access="private",
                ),
                OpenSpaceFeature(
                    points=around(covered_candidate),
                    access="yes",
                    covered="yes",
                ),
            ),
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("flood"),
        (current_hazard("flood"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert all(item.coordinate != inaccessible_candidate for item in response.items)


def test_flood_does_not_use_mapped_buildings_as_shelter_candidates():
    sampled_candidates = _candidate_coordinates(ORIGIN, 1000.0)
    building_candidate = sampled_candidates[0]
    provider = StubEnvironmentProvider(
        lambda candidates: EnvironmentSnapshot(
            buildings=(
                BuildingFeature(
                    points=around(building_candidate),
                    height_m=30.0,
                ),
            ),
            trees=(),
            elevations_m=(
                10.0,
                *(
                    30.0 if candidate == building_candidate else 15.0
                    for candidate in candidates[1:]
                ),
            ),
            observed_at=NOW,
            source="OpenTopoData test snapshot",
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("flood"),
        (current_hazard("flood"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert all(item.coordinate != building_candidate for item in response.items)


def test_flood_discloses_height_metadata_gap_without_calling_buildings_safe():
    sampled_candidates = _candidate_coordinates(ORIGIN, 1000.0)
    provider = StubEnvironmentProvider(
        lambda candidates: EnvironmentSnapshot(
            buildings=(
                BuildingFeature(
                    points=around(sampled_candidates[-1]),
                    height_m=None,
                ),
            ),
            trees=(),
            elevations_m=(10.0, *(15.0 for _candidate in candidates[1:])),
            observed_at=NOW,
            source="OpenTopoData test snapshot",
            data_complete=False,
            uncertainty_notice="Some mapped building heights were unavailable.",
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("flood"),
        (current_hazard("flood"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert response.items
    assert "confidence" in response.uncertainty_notice
    assert all(
        "flood shelters" in reason
        for item in response.items
        for reason in item.rationale
        if "buildings" in reason
    )


def test_flood_fails_closed_for_partial_elevation_data():
    provider = StubEnvironmentProvider(
        lambda candidates: EnvironmentSnapshot(
            buildings=(),
            trees=(),
            elevations_m=(10.0, 20.0),
            observed_at=NOW,
            source="OpenTopoData test snapshot",
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("flood"),
        (current_hazard("flood"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert response.items == []
    assert "elevation data was incomplete" in response.uncertainty_notice


def test_flood_fails_closed_for_incomplete_environment_geometry():
    sampled_candidate = _candidate_coordinates(ORIGIN, 1000.0)[0]
    provider = StubEnvironmentProvider(
        lambda candidates: EnvironmentSnapshot(
            buildings=(),
            trees=(),
            elevations_m=(10.0, *(20.0 for _candidate in candidates[1:])),
            observed_at=NOW,
            source="OpenTopoData test snapshot",
            water_features=(
                WaterFeature(
                    points=around(sampled_candidate),
                    feature_type="wetland",
                    geometry_complete=False,
                ),
            ),
            data_complete=False,
            uncertainty_notice="Some mapped features had missing or partial geometry.",
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("flood"),
        (current_hazard("flood"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert response.items == []
    assert "geometry or completeness was insufficient" in response.uncertainty_notice
    assert "not confirmation that water is absent" not in response.uncertainty_notice


def test_active_earthquake_returns_guidance_without_querying_environment():
    provider = StubEnvironmentProvider(lambda candidates: None)
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("earthquake", "general"),
        (),
        source="Yangon test snapshot",
        uncertainty_notice="Test notice.",
    )

    assert response.items == []
    assert "Drop, Cover, and Hold On" in response.uncertainty_notice
    assert provider.calls == []


def test_empty_guidance_response_uses_source_timestamp_when_available():
    provider = StubEnvironmentProvider(lambda candidates: None)
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("earthquake", "general"),
        (),
        source="Yangon test snapshot",
        uncertainty_notice="Test notice.",
        source_data_at=NOW,
    )

    assert response.data_at == NOW


def test_unsupported_disaster_is_unavailable_without_querying_environment():
    provider = StubEnvironmentProvider(lambda candidates: None)
    analyzer = RealContextAnalyzer(provider)

    with pytest.raises(ContextAnalysisUnavailable):
        analyzer.find_context_areas(
            request("landslide"),
            (),
            source="Yangon test snapshot",
            uncertainty_notice="Test notice.",
        )
    assert provider.calls == []


def test_unsupported_hazard_geometry_is_unavailable_without_environment_query():
    provider = StubEnvironmentProvider(lambda candidates: None)
    analyzer = RealContextAnalyzer(provider)

    with pytest.raises(ContextAnalysisUnavailable):
        analyzer.find_context_areas(
            request("severe_weather"),
            (current_hazard("severe_weather"),),
            source="Yangon test snapshot",
            uncertainty_notice="Test notice.",
        )
    assert provider.calls == []


def test_missing_earthquake_environment_data_does_not_become_maximum_clearance():
    provider = StubEnvironmentProvider(
        lambda candidates: EnvironmentSnapshot(
            buildings=(),
            trees=(),
            elevations_m=(),
            observed_at=NOW,
            source="OSM test snapshot",
        )
    )
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("earthquake", "outdoors_after_shaking"),
        (current_hazard("earthquake"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test data is not an official safety assessment.",
    )

    assert response.items == []
    assert response.data_at == NOW
    assert "data was incomplete" in response.uncertainty_notice
