from datetime import UTC, datetime

import pytest

from app.providers.mapbox.directions import (
    DirectionsProviderError,
    DirectionsRoute,
)
from app.schemas.navigation import (
    ContextAreaRequest,
    Coordinate,
    LineStringGeometry,
    RouteSuggestionRequest,
)
from app.services.navigation import (
    HAZARDS,
    SHELTERS,
    SIMULATION_MAX_LATITUDE,
    SIMULATION_MAX_LONGITUDE,
    SIMULATION_MIN_LATITUDE,
    SIMULATION_MIN_LONGITUDE,
    NavigationService,
    OutsideSimulationArea,
    RoutingUnavailable,
    SimulationDataDisabled,
)

NOW = datetime(2026, 7, 23, 12, 0, tzinfo=UTC)


def directions_route(coordinates, distance: float, duration: float) -> DirectionsRoute:
    return DirectionsRoute(
        LineStringGeometry(type="LineString", coordinates=coordinates),
        distance,
        duration,
    )


class StubProvider:
    def __init__(self, outcome):
        self.outcome = outcome
        self.calls = []

    def get_routes(self, origin, destination, profile):
        self.calls.append((origin, destination, profile))
        if isinstance(self.outcome, Exception):
            raise self.outcome
        return self.outcome


def request(profile=None):
    return RouteSuggestionRequest(
        origin=Coordinate(latitude=21.95, longitude=96.08),
        shelter_id="simulation-shelter-1",
        disaster_type="earthquake",
        profile=profile,
    )


def test_simulation_gate_blocks_all_data_and_provider_access():
    provider = StubProvider(())
    service = NavigationService(False, provider, clock=lambda: NOW)

    with pytest.raises(SimulationDataDisabled):
        service.list_shelters()
    with pytest.raises(SimulationDataDisabled):
        service.list_hazards()
    with pytest.raises(SimulationDataDisabled):
        service.suggest_routes(request())

    assert provider.calls == []


def test_fixed_lists_are_visibly_simulated_timestamped_and_fictional():
    service = NavigationService(True, StubProvider(()), clock=lambda: NOW)

    shelters = service.list_shelters()
    hazards = service.list_hazards()

    assert shelters.source == hazards.source == "SafeMyanmar Demo"
    assert shelters.simulation is hazards.simulation is True
    assert all(item.name.startswith("SIMULATION:") for item in shelters.items)
    assert all(item.name.startswith("SIMULATION:") for item in hazards.items)
    assert all(item.data_at == shelters.data_at for item in shelters.items)
    assert all(item.data_at == hazards.data_at for item in hazards.items)
    assert "latitude 21.9300 through 21.9900" in shelters.uncertainty_notice
    assert "longitude 96.0600 through 96.1200" in hazards.uncertainty_notice
    assert all(
        SIMULATION_MIN_LATITUDE <= item.coordinate.latitude <= SIMULATION_MAX_LATITUDE
        and SIMULATION_MIN_LONGITUDE
        <= item.coordinate.longitude
        <= SIMULATION_MAX_LONGITUDE
        for item in SHELTERS
    )


def test_context_analysis_prioritizes_open_space_for_outdoor_earthquake():
    service = NavigationService(True, StubProvider(()), clock=lambda: NOW)

    response = service.find_context_areas(
        ContextAreaRequest(
            origin=Coordinate(latitude=21.95, longitude=96.08),
            disaster_type="earthquake",
            scenario="outdoors_after_shaking",
        )
    )

    assert 0 < len(response.items) <= 3
    assert all(item.disaster_type == "earthquake" for item in response.items)
    assert all(item.metrics.hazard_intersections == 0 for item in response.items)
    assert any("building" in reason.lower() for reason in response.items[0].rationale)
    assert all(item.simulation for item in response.items)


def test_context_analysis_prioritizes_higher_ground_for_flood():
    service = NavigationService(True, StubProvider(()), clock=lambda: NOW)

    response = service.find_context_areas(
        ContextAreaRequest(
            origin=Coordinate(latitude=21.95, longitude=96.08),
            disaster_type="flood",
        )
    )

    assert 0 < len(response.items) <= 3
    elevations = [item.metrics.relative_elevation_m for item in response.items]
    assert elevations == sorted(elevations, reverse=True)
    assert all(item.metrics.hazard_intersections == 0 for item in response.items)


def test_context_analysis_does_not_route_outside_during_active_earthquake_shaking():
    service = NavigationService(True, StubProvider(()), clock=lambda: NOW)

    response = service.find_context_areas(
        ContextAreaRequest(
            origin=Coordinate(latitude=21.95, longitude=96.08),
            disaster_type="earthquake",
            scenario="general",
        )
    )

    assert response.items == []
    assert "Drop, Cover, and Hold On" in response.uncertainty_notice
    assert all(
        SIMULATION_MIN_LONGITUDE <= longitude <= SIMULATION_MAX_LONGITUDE
        and SIMULATION_MIN_LATITUDE <= latitude <= SIMULATION_MAX_LATITUDE
        for hazard in HAZARDS
        for longitude, latitude in hazard.geometry.coordinates[0]
    )


def test_ranking_is_hazards_then_duration_then_distance_and_wording_is_safe():
    intersects_hazard = directions_route(
        [(96.08, 21.95), (96.091, 21.958)], 500.0, 100.0
    )
    avoids_hazard_slower = directions_route(
        [(96.08, 21.95), (96.08, 21.97), (96.091, 21.958)], 1300.0, 800.0
    )
    avoids_hazard_faster = directions_route(
        [(96.08, 21.95), (96.075, 21.97), (96.091, 21.958)], 1400.0, 700.0
    )
    provider = StubProvider(
        (intersects_hazard, avoids_hazard_slower, avoids_hazard_faster)
    )
    service = NavigationService(True, provider, clock=lambda: NOW)

    response = service.suggest_routes(request())

    assert [option.distance_m for option in response.options] == [
        1400.0,
        1300.0,
        500.0,
    ]
    assert [option.hazard_intersection_count for option in response.options] == [
        0,
        0,
        1,
    ]
    assert [option.recommended for option in response.options] == [True, False, False]
    assert response.options[0].rationale == (
        "Suggested safer route based on currently available SIMULATION information."
    )
    serialized = response.model_dump_json().lower()
    assert "guaranteed safe" not in serialized
    assert "safe route" not in serialized


@pytest.mark.parametrize("count", [1, 2, 3])
def test_does_not_fabricate_missing_routes(count):
    routes = tuple(
        directions_route(
            [(96.07 - index * 0.001, 21.94), (96.091, 21.958)],
            1000.0 + index,
            600.0 + index,
        )
        for index in range(count)
    )
    service = NavigationService(True, StubProvider(routes), clock=lambda: NOW)

    assert len(service.suggest_routes(request()).options) == count


def test_profile_rule_is_transparent_and_explicit_profile_overrides_it():
    route = directions_route([(96.08, 21.95), (96.091, 21.958)], 1000.0, 600.0)
    provider = StubProvider((route,))
    service = NavigationService(True, provider, clock=lambda: NOW)

    automatic = service.suggest_routes(request())
    overridden = service.suggest_routes(request("driving"))

    assert automatic.profile == "walking"
    assert "5 km or less" in automatic.profile_selection_reason
    assert overridden.profile == "driving"
    assert overridden.profile_selection_reason == (
        "The user requested the driving profile."
    )


def test_provider_failure_becomes_routing_unavailable():
    service = NavigationService(
        True, StubProvider(DirectionsProviderError()), clock=lambda: NOW
    )

    with pytest.raises(RoutingUnavailable):
        service.suggest_routes(request())


def test_origin_outside_simulation_area_fails_before_provider_call():
    provider = StubProvider(())
    service = NavigationService(True, provider, clock=lambda: NOW)
    outside_request = request().model_copy(
        update={"origin": Coordinate(latitude=22.0, longitude=96.08)}
    )

    with pytest.raises(OutsideSimulationArea):
        service.suggest_routes(outside_request)

    assert provider.calls == []


def test_routes_leaving_simulation_area_are_not_returned_or_recommended():
    outside = directions_route(
        [(96.08, 21.95), (96.13, 21.96), (96.091, 21.958)], 500.0, 100.0
    )
    inside = directions_route(
        [(96.08, 21.95), (96.075, 21.97), (96.091, 21.958)], 1400.0, 700.0
    )
    service = NavigationService(
        True, StubProvider((outside, inside)), clock=lambda: NOW
    )

    response = service.suggest_routes(request())

    assert len(response.options) == 1
    assert response.options[0].distance_m == 1400.0
    assert response.options[0].recommended is True


def test_only_out_of_coverage_provider_routes_are_unavailable():
    outside = directions_route(
        [(96.08, 21.95), (96.13, 21.96), (96.091, 21.958)], 500.0, 100.0
    )
    service = NavigationService(True, StubProvider((outside,)), clock=lambda: NOW)

    with pytest.raises(RoutingUnavailable):
        service.suggest_routes(request())
