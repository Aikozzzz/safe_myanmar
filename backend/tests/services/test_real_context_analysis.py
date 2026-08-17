from datetime import UTC, datetime

from app.schemas.navigation import (
    ContextAreaRequest,
    Coordinate,
    Hazard,
    PolygonGeometry,
)
from app.services.real_context_analysis import (
    BuildingFeature,
    EnvironmentSnapshot,
    RealContextAnalyzer,
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
    ):
        self.calls.append(
            (origin, tuple(candidates), radius_m, include_obstacles, include_elevation)
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


def test_earthquake_prefers_mapped_open_clearance_without_simulation():
    provider = StubEnvironmentProvider(
        lambda candidates: EnvironmentSnapshot(
            buildings=(
                BuildingFeature(
                    points=((96.20, 16.95), (96.201, 16.95)),
                    height_m=30,
                ),
            ),
            trees=((96.20, 16.95),),
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

    assert response.items
    assert response.simulation is False
    assert response.items[0].name.startswith("Suggested open area")
    assert any("high buildings" in reason for reason in response.items[0].rationale)
    assert "OpenStreetMap" in response.items[0].uncertainty_notice
    assert provider.calls[0][3:] == (True, False)


def test_flood_prefers_higher_mapped_ground_than_origin():
    elevations = (10.0, 15.0, 8.0, 14.0, 7.0, 13.0, 6.0, 12.0, 5.0)
    provider = StubEnvironmentProvider(
        lambda candidates: EnvironmentSnapshot(
            buildings=(),
            trees=(),
            elevations_m=elevations,
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
    assert provider.calls[0][3:] == (False, True)


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


def test_unsupported_disaster_returns_explanation_without_failing():
    provider = StubEnvironmentProvider(lambda candidates: None)
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("landslide"),
        (),
        source="Yangon test snapshot",
        uncertainty_notice="Test notice.",
    )

    assert response.items == []
    assert (
        "No current verified landslide hazard geometry" in response.uncertainty_notice
    )
    assert provider.calls == []


def test_hazard_geometry_supports_disaster_types_without_environment_query():
    provider = StubEnvironmentProvider(lambda candidates: None)
    analyzer = RealContextAnalyzer(provider)

    response = analyzer.find_context_areas(
        request("severe_weather"),
        (current_hazard("severe_weather"),),
        source="Yangon test snapshot",
        uncertainty_notice="Test notice.",
    )

    assert response.items
    assert response.items[0].disaster_type == "severe_weather"
    assert response.items[0].metrics.hazard_intersections == 0
    assert "current snapshot hazard geometry" in response.items[0].source
    assert "does not assess fire spread" in response.items[0].uncertainty_notice
    assert provider.calls == []
