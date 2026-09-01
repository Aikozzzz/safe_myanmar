from datetime import UTC, datetime, timedelta

import pytest

from app.providers.mapbox.directions import (
    DirectionsProviderError,
    DirectionsRoute,
    MapboxDirectionsProvider,
)
from app.schemas.navigation import (
    ContextArea,
    ContextAreaListResponse,
    ContextMetrics,
    Coordinate,
    Hazard,
    LineStringGeometry,
    PolygonGeometry,
    RouteOption,
    RouteSuggestionRequest,
    RouteSuggestionsResponse,
    Shelter,
)
from app.services.environment_provider import ContextAnalysisUnavailable
from app.services.navigation import (
    NavigationService,
    RoutingUnavailable,
    ShelterNotFound,
)
from app.services.real_navigation_data import (
    DEFAULT_SNAPSHOT_MAX_AGE_SECONDS,
    YangonNavigationData,
)

NOW = datetime(2026, 8, 17, 13, 42, tzinfo=UTC)
ORIGIN = Coordinate(latitude=16.856152, longitude=96.130522)
SHELTER_COORDINATE = Coordinate(latitude=16.838, longitude=96.132)


class StubDirectionsProvider:
    def __init__(self, outcome):
        self.outcome = outcome
        self.calls = []

    def get_routes(self, origin, destination, profile):
        self.calls.append((origin, destination, profile))
        if isinstance(self.outcome, Exception):
            raise self.outcome
        return self.outcome


class StubContextAnalyzer:
    def __init__(self, response=None, outcome=None):
        self.response = response
        self.outcome = outcome
        self.calls = []

    def find_context_areas(self, request, hazards, **kwargs):
        self.calls.append((request, tuple(hazards), kwargs))
        if self.outcome is not None:
            raise self.outcome
        return self.response


def directions_route(
    coordinates: list[tuple[float, float]],
    distance: float,
    duration: float,
) -> DirectionsRoute:
    return DirectionsRoute(
        LineStringGeometry(type="LineString", coordinates=coordinates),
        distance,
        duration,
    )


def current_hazard() -> Hazard:
    return Hazard(
        id="current-earthquake",
        name="Current earthquake geometry",
        disaster_type="earthquake",
        geometry=PolygonGeometry(
            coordinates=[
                [
                    (96.1309, 16.8519),
                    (96.1311, 16.8519),
                    (96.1311, 16.8521),
                    (96.1309, 16.8521),
                    (96.1309, 16.8519),
                ]
            ]
        ),
        source="Verified hazard registry",
        data_at=NOW,
        simulation=False,
    )


def verified_shelter(*, data_at: datetime = NOW) -> Shelter:
    return Shelter(
        id="verified-shelter",
        name="Verified community shelter",
        coordinate=SHELTER_COORDINATE,
        description="Snapshot-listed shelter.",
        source="Verified shelter registry",
        data_at=data_at,
        simulation=False,
    )


def real_data(
    *,
    retrieved_at: datetime = NOW,
    shelters: tuple[Shelter, ...] | None = None,
    hazards: tuple[Hazard, ...] | None = None,
    uncertainty_notice: str = "Current snapshot coverage may be incomplete.",
) -> YangonNavigationData:
    return YangonNavigationData(
        source="Verified Yangon snapshot",
        retrieved_at=retrieved_at,
        shelters=shelters if shelters is not None else (verified_shelter(),),
        hazards=hazards if hazards is not None else (current_hazard(),),
        uncertainty_notice=uncertainty_notice,
    )


def route_request(
    *,
    shelter_id: str = "verified-shelter",
    context_area_id: str | None = None,
) -> RouteSuggestionRequest:
    return RouteSuggestionRequest(
        origin=ORIGIN,
        shelter_id=shelter_id,
        context_area_id=context_area_id,
        disaster_type="earthquake",
        scenario="outdoors_after_shaking",
    )


def context_area(
    *,
    identifier: str = "mapped-park",
    data_at: datetime = NOW,
    uncertainty_notice: str = "Mapped coverage may be incomplete.",
    source: str = "OpenStreetMap via Overpass",
    simulation: bool = False,
) -> ContextArea:
    return ContextArea(
        id=identifier,
        name="Mapped public park",
        coordinate=Coordinate(latitude=16.854, longitude=96.134),
        disaster_type="earthquake",
        scenario="outdoors_after_shaking",
        distance_m=400.0,
        metrics=ContextMetrics(
            building_clearance_m=120.0,
            tree_clearance_m=90.0,
            relative_elevation_m=0.0,
            building_density=0.1,
            tree_density=0.2,
            hazard_intersections=0,
        ),
        rationale=["Mapped public open-space polygon"],
        source=source,
        data_at=data_at,
        simulation=simulation,
        uncertainty_notice=uncertainty_notice,
    )


def context_response(
    areas: list[ContextArea],
    *,
    data_at: datetime = NOW,
    source: str = "OpenStreetMap via Overpass",
    simulation: bool = False,
    uncertainty_notice: str = "Mapped coverage may be incomplete.",
) -> ContextAreaListResponse:
    return ContextAreaListResponse(
        items=areas,
        data_at=data_at,
        source=source,
        simulation=simulation,
        uncertainty_notice=uncertainty_notice,
    )


def test_real_route_schema_accepts_actual_source_and_false_simulation_metadata():
    route = directions_route(
        [
            (ORIGIN.longitude, ORIGIN.latitude),
            (SHELTER_COORDINATE.longitude, SHELTER_COORDINATE.latitude),
        ],
        1200.0,
        600.0,
    )
    option = RouteOption(
        id="real-route-1",
        generated_at=NOW,
        hazard_data_at=NOW,
        profile="walking",
        source="Verified shelter registry",
        directions_provider="Mapbox Directions",
        simulation=False,
        geometry=route.geometry,
        distance_m=route.distance_m,
        duration_seconds=route.duration_seconds,
        hazard_intersection_count=0,
        rationale="Current route data may differ from field conditions.",
        recommended=True,
        uncertainty_notice="This is not a guarantee.",
    )

    response = RouteSuggestionsResponse(
        options=[option],
        generated_at=NOW,
        hazard_data_at=NOW,
        profile="walking",
        profile_selection_reason="The user requested the walking profile.",
        source="Verified shelter registry",
        directions_provider="Mapbox Directions",
        simulation=False,
        uncertainty_notice="This is not a guarantee.",
    )

    assert response.source == "Verified shelter registry"
    assert response.simulation is False
    assert response.options[0].source == response.source
    assert response.options[0].simulation is False


def test_real_routes_resolve_verified_shelter_and_rank_current_hazards_first():
    intersects = directions_route(
        [
            (ORIGIN.longitude, ORIGIN.latitude),
            (96.131, 16.852),
            (SHELTER_COORDINATE.longitude, SHELTER_COORDINATE.latitude),
        ],
        500.0,
        100.0,
    )
    avoids_hazard_slower = directions_route(
        [
            (ORIGIN.longitude, ORIGIN.latitude),
            (96.129, 16.852),
            (SHELTER_COORDINATE.longitude, SHELTER_COORDINATE.latitude),
        ],
        1300.0,
        800.0,
    )
    avoids_hazard_faster = directions_route(
        [
            (ORIGIN.longitude, ORIGIN.latitude),
            (96.129, 16.850),
            (SHELTER_COORDINATE.longitude, SHELTER_COORDINATE.latitude),
        ],
        1400.0,
        700.0,
    )
    provider = StubDirectionsProvider(
        (intersects, avoids_hazard_slower, avoids_hazard_faster)
    )
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(),
    )

    response = service.suggest_routes(route_request())

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
    assert response.source == "Verified shelter registry"
    assert response.simulation is False
    assert response.hazard_data_at == NOW
    assert response.generated_at == NOW
    assert provider.calls == [(ORIGIN, SHELTER_COORDINATE, "walking")]
    serialized = response.model_dump_json().lower()
    assert "guaranteed safe" not in serialized
    assert "safe route" not in serialized


def test_real_routes_truncate_provider_output_to_three_options():
    routes = tuple(
        directions_route(
            [
                (ORIGIN.longitude, ORIGIN.latitude),
                (SHELTER_COORDINATE.longitude, SHELTER_COORDINATE.latitude),
            ],
            1000.0 + index,
            600.0 + index,
        )
        for index in range(4)
    )
    service = NavigationService(
        False,
        StubDirectionsProvider(routes),
        clock=lambda: NOW,
        real_data=real_data(),
    )

    response = service.suggest_routes(route_request())

    assert len(response.options) == 3


def test_real_routes_with_no_provider_alternatives_are_unavailable():
    provider = StubDirectionsProvider(())
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(),
    )

    with pytest.raises(RoutingUnavailable):
        service.suggest_routes(route_request())

    assert provider.calls == [(ORIGIN, SHELTER_COORDINATE, "walking")]


def test_real_routes_recompute_selected_context_area_before_requesting_directions():
    selected = context_area()
    analyzer = StubContextAnalyzer(context_response([selected]))
    provider = StubDirectionsProvider(
        (
            directions_route(
                [
                    (ORIGIN.longitude, ORIGIN.latitude),
                    (selected.coordinate.longitude, selected.coordinate.latitude),
                ],
                900.0,
                500.0,
            ),
        )
    )
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(shelters=()),
        context_analyzer=analyzer,
    )

    response = service.suggest_routes(
        route_request(shelter_id=selected.id, context_area_id=selected.id)
    )

    assert response.options[0].simulation is False
    assert response.source == selected.source
    assert provider.calls == [(ORIGIN, selected.coordinate, "walking")]
    assert len(analyzer.calls) == 1
    context_request, hazards, kwargs = analyzer.calls[0]
    assert context_request.origin == ORIGIN
    assert context_request.disaster_type == "earthquake"
    assert context_request.scenario == "outdoors_after_shaking"
    assert hazards == (current_hazard(),)
    assert kwargs["simulation_data_included"] is False


def test_real_routes_accept_context_destination_ids_up_to_context_contract_limit():
    identifier = f"mapped-{'x' * 135}"
    selected = context_area(identifier=identifier)
    analyzer = StubContextAnalyzer(context_response([selected]))
    provider = StubDirectionsProvider(
        (
            directions_route(
                [
                    (ORIGIN.longitude, ORIGIN.latitude),
                    (selected.coordinate.longitude, selected.coordinate.latitude),
                ],
                900.0,
                500.0,
            ),
        )
    )
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(shelters=()),
        context_analyzer=analyzer,
    )

    response = service.suggest_routes(
        route_request(shelter_id=identifier, context_area_id=identifier)
    )

    assert response.options[0].source == selected.source
    assert provider.calls == [(ORIGIN, selected.coordinate, "walking")]


@pytest.mark.parametrize(
    "areas",
    [
        [],
        [
            context_area(
                uncertainty_notice="The mapped observation is stale and may differ."
            )
        ],
    ],
)
def test_real_routes_reject_unknown_or_stale_context_destinations(areas):
    selected_id = "mapped-park"
    analyzer = StubContextAnalyzer(context_response(areas))
    provider = StubDirectionsProvider(())
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(shelters=()),
        context_analyzer=analyzer,
    )

    with pytest.raises(ShelterNotFound):
        service.suggest_routes(
            route_request(shelter_id=selected_id, context_area_id=selected_id)
        )

    assert provider.calls == []


def test_real_routes_map_unavailable_context_analysis_without_exposing_details():
    analyzer = StubContextAnalyzer(outcome=ContextAnalysisUnavailable())
    provider = StubDirectionsProvider(())
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(shelters=()),
        context_analyzer=analyzer,
    )

    with pytest.raises(RoutingUnavailable):
        service.suggest_routes(
            route_request(shelter_id="mapped-park", context_area_id="mapped-park")
        )

    assert provider.calls == []


def test_real_routes_reject_context_without_analyzer():
    provider = StubDirectionsProvider(())
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(shelters=()),
    )

    with pytest.raises(RoutingUnavailable):
        service.suggest_routes(
            route_request(shelter_id="mapped-park", context_area_id="mapped-park")
        )

    assert provider.calls == []


def test_real_routes_reject_simulated_context_even_when_real_data_is_enabled():
    simulated = context_area(
        source="Verified snapshot; SafeMyanmar Demo simulation analysis data",
        simulation=True,
    )
    analyzer = StubContextAnalyzer(
        context_response(
            [simulated],
            source="Verified snapshot; SafeMyanmar Demo simulation analysis data",
            simulation=True,
        )
    )
    provider = StubDirectionsProvider(())
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(shelters=()),
        context_analyzer=analyzer,
    )

    with pytest.raises(ShelterNotFound):
        service.suggest_routes(
            route_request(shelter_id=simulated.id, context_area_id=simulated.id)
        )

    assert provider.calls == []


def test_real_routes_reject_shelter_record_from_an_older_snapshot():
    provider = StubDirectionsProvider(())
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(
            shelters=(verified_shelter(data_at=NOW - timedelta(seconds=1)),)
        ),
    )

    with pytest.raises(ShelterNotFound):
        service.suggest_routes(route_request())

    assert provider.calls == []


def test_real_routes_reject_stale_snapshot_before_provider_call():
    stale = NOW - timedelta(seconds=DEFAULT_SNAPSHOT_MAX_AGE_SECONDS + 1)
    provider = StubDirectionsProvider(())
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(
            retrieved_at=stale, shelters=(verified_shelter(data_at=stale),)
        ),
    )

    with pytest.raises(RoutingUnavailable):
        service.suggest_routes(route_request())

    assert provider.calls == []


def test_real_routes_without_mapbox_token_are_unavailable_without_network_access():
    provider = MapboxDirectionsProvider(None)
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(),
    )

    try:
        with pytest.raises(RoutingUnavailable):
            service.suggest_routes(route_request())
    finally:
        provider.close()


def test_real_routes_map_missing_or_failed_directions_to_safe_unavailable_error():
    provider = StubDirectionsProvider(DirectionsProviderError())
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=real_data(),
    )

    with pytest.raises(RoutingUnavailable) as caught:
        service.suggest_routes(route_request())

    assert str(caught.value) == ""
    assert "96.130522" not in str(caught.value)
    assert "16.856152" not in str(caught.value)
