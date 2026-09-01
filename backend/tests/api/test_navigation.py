from dataclasses import replace
from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from app.api.v1.navigation import (
    ContextAnalysisGuard,
    SimulationRouteGuard,
    get_navigation_service,
)
from app.main import create_app
from app.providers.mapbox.directions import DirectionsProviderError, DirectionsRoute
from app.schemas.navigation import (
    ContextArea,
    ContextAreaListResponse,
    ContextMetrics,
    Coordinate,
    Hazard,
    LineStringGeometry,
    PolygonGeometry,
    Shelter,
)
from app.services.environment_provider import (
    BuildingFeature,
    EnvironmentSnapshot,
    OpenSpaceFeature,
)
from app.services.navigation import NavigationService

NOW = datetime(2026, 7, 23, 12, 0, tzinfo=UTC)


class StubProvider:
    def __init__(self, routes=()):
        self.routes = routes
        self.calls = []

    def get_routes(self, origin, destination, profile):
        self.calls.append((origin, destination, profile))
        return self.routes


class FailingProvider(StubProvider):
    def get_routes(self, origin, destination, profile):
        self.calls.append((origin, destination, profile))
        raise DirectionsProviderError


class StubEnvironmentProvider:
    def __init__(self, snapshot):
        self.snapshot = snapshot
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
            {
                "origin": origin,
                "candidates": tuple(candidates),
                "radius_m": radius_m,
                "include_obstacles": include_obstacles,
                "include_elevation": include_elevation,
                "include_water": include_water,
            }
        )
        return self.snapshot

    def close(self):
        pass


class StubContextAnalyzer:
    def __init__(self, response):
        self.response = response
        self.calls = []

    def find_context_areas(self, request, hazards, **kwargs):
        self.calls.append((request, tuple(hazards), kwargs))
        return self.response


@pytest.fixture
def navigation_app_without_data(monkeypatch):
    monkeypatch.setenv("ENABLE_SIMULATION_DATA", "false")
    monkeypatch.setenv("ENABLE_SIMULATION_ANALYSIS", "false")
    monkeypatch.setenv("NAVIGATION_DATA_PATH", "__missing_navigation_snapshot__")
    return create_app()


@pytest.fixture
def real_navigation_app(monkeypatch):
    monkeypatch.setenv("ENABLE_SIMULATION_DATA", "false")
    monkeypatch.setenv("ENABLE_SIMULATION_ANALYSIS", "false")
    monkeypatch.setenv("NAVIGATION_DATA_PATH", "SafeMyanmar_Yangon_2026-08-17")
    return create_app()


@pytest.fixture
def enabled_navigation_app(monkeypatch):
    monkeypatch.setenv("ENABLE_SIMULATION_DATA", "true")
    monkeypatch.setenv("ENABLE_SIMULATION_ANALYSIS", "false")
    monkeypatch.setenv("MAPBOX_DIRECTIONS_ACCESS_TOKEN", "")
    return create_app()


@pytest.fixture
def real_navigation_app_with_simulation_analysis(monkeypatch):
    monkeypatch.setenv("ENABLE_SIMULATION_DATA", "false")
    monkeypatch.setenv("NAVIGATION_DATA_PATH", "SafeMyanmar_Yangon_2026-08-17")
    monkeypatch.setenv("ENABLE_SIMULATION_ANALYSIS", "true")
    return create_app()


def enable_simulation(application, routes=()):
    provider = StubProvider(routes)
    service = NavigationService(True, provider, clock=lambda: NOW)
    application.dependency_overrides[get_navigation_service] = lambda: service
    return provider


def valid_request():
    return {
        "origin": {"latitude": 21.95, "longitude": 96.08},
        "shelter_id": "simulation-shelter-1",
        "disaster_type": "earthquake",
    }


def configure_real_route_service(application, provider):
    current_service = application.state.navigation_service
    retrieved_at = current_service._real_data.retrieved_at
    shelter = Shelter(
        id="verified-shelter",
        name="Verified snapshot shelter",
        coordinate=Coordinate(latitude=16.838, longitude=96.132),
        description="Snapshot-listed shelter.",
        source="Verified shelter registry",
        data_at=retrieved_at,
        simulation=False,
    )
    data = replace(current_service._real_data, shelters=(shelter,))
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=data,
    )
    application.dependency_overrides[get_navigation_service] = lambda: service
    return service


def test_endpoints_are_disabled_without_a_navigation_snapshot(
    navigation_app_without_data,
):
    assert navigation_app_without_data.state.navigation_data_error == (
        "navigation_data_missing"
    )
    with TestClient(navigation_app_without_data) as client:
        shelters = client.get("/api/v1/shelters")
        hazards = client.get("/api/v1/hazards")
        routes = client.post("/api/v1/route-suggestions", content=b"not-json")

    assert shelters.status_code == hazards.status_code == routes.status_code == 404
    assert shelters.json()["error"]["code"] == "not_found"
    assert hazards.json()["error"]["code"] == "not_found"
    assert routes.json()["error"]["code"] == "not_found"
    assert "/api/v1/alerts" in navigation_app_without_data.openapi()["paths"]
    assert (
        "/api/v1/route-suggestions"
        not in navigation_app_without_data.openapi()["paths"]
    )


def test_real_navigation_snapshot_is_exposed_without_simulation(real_navigation_app):
    with TestClient(real_navigation_app) as client:
        shelters = client.get("/api/v1/shelters")
        hazards = client.get("/api/v1/hazards")

    assert shelters.status_code == hazards.status_code == 200
    assert shelters.json()["items"] == []
    assert hazards.json()["items"]
    assert hazards.json()["simulation"] is False
    assert "SafeMyanmar Yangon snapshot" in hazards.json()["source"]


def test_real_route_endpoint_returns_real_metadata_and_selected_shelter(
    real_navigation_app,
):
    route = DirectionsRoute(
        LineStringGeometry(
            type="LineString",
            coordinates=[(96.130522, 16.856152), (96.132, 16.838)],
        ),
        2100.0,
        900.0,
    )
    provider = StubProvider((route,))
    configure_real_route_service(real_navigation_app, provider)

    with TestClient(real_navigation_app) as client:
        response = client.post(
            "/api/v1/route-suggestions",
            json={
                "origin": {"latitude": 16.856152, "longitude": 96.130522},
                "shelter_id": "verified-shelter",
                "disaster_type": "earthquake",
                "scenario": "outdoors_after_shaking",
            },
        )

    assert response.status_code == 200
    payload = response.json()
    assert payload["simulation"] is False
    assert payload["source"] == "Verified shelter registry"
    assert payload["directions_provider"] == "Mapbox Directions"
    assert payload["options"][0]["simulation"] is False
    assert payload["options"][0]["source"] == "Verified shelter registry"
    assert payload["hazard_data_at"] == "2026-08-17T13:42:17Z"
    assert provider.calls[0][1] == Coordinate(latitude=16.838, longitude=96.132)


def test_real_route_endpoint_resolves_explicit_selected_context_area(
    real_navigation_app,
):
    selected = ContextArea(
        id="mapped-park",
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
        source="OpenStreetMap via Overpass",
        data_at=NOW,
        simulation=False,
        uncertainty_notice="Mapped coverage may be incomplete.",
    )
    analyzer = StubContextAnalyzer(
        ContextAreaListResponse(
            items=[selected],
            data_at=NOW,
            source="OpenStreetMap via Overpass",
            simulation=False,
            uncertainty_notice="Mapped coverage may be incomplete.",
        )
    )
    route = DirectionsRoute(
        LineStringGeometry(
            type="LineString",
            coordinates=[
                (96.130522, 16.856152),
                (selected.coordinate.longitude, selected.coordinate.latitude),
            ],
        ),
        1400.0,
        700.0,
    )
    provider = StubProvider((route,))
    current_service = real_navigation_app.state.navigation_service
    service = NavigationService(
        False,
        provider,
        clock=lambda: NOW,
        real_data=replace(current_service._real_data, shelters=()),
        context_analyzer=analyzer,
    )
    real_navigation_app.dependency_overrides[get_navigation_service] = lambda: service

    with TestClient(real_navigation_app) as client:
        response = client.post(
            "/api/v1/route-suggestions",
            json={
                "origin": {"latitude": 16.856152, "longitude": 96.130522},
                "shelter_id": selected.id,
                "context_area_id": selected.id,
                "disaster_type": "earthquake",
                "scenario": "outdoors_after_shaking",
            },
        )

    assert response.status_code == 200
    payload = response.json()
    assert payload["simulation"] is False
    assert payload["source"] == "OpenStreetMap via Overpass"
    assert payload["options"][0]["source"] == "OpenStreetMap via Overpass"
    assert provider.calls == [
        (
            Coordinate(latitude=16.856152, longitude=96.130522),
            selected.coordinate,
            "walking",
        )
    ]
    assert analyzer.calls[0][0].origin == Coordinate(
        latitude=16.856152, longitude=96.130522
    )


def test_real_route_endpoint_keeps_unknown_destination_as_safe_not_found(
    real_navigation_app,
):
    provider = StubProvider(())
    configure_real_route_service(real_navigation_app, provider)

    with TestClient(real_navigation_app) as client:
        response = client.post(
            "/api/v1/route-suggestions",
            json={
                "origin": {"latitude": 16.856152, "longitude": 96.130522},
                "shelter_id": "unknown-shelter",
                "disaster_type": "earthquake",
            },
        )

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "shelter_not_found"
    assert "16.856152" not in response.text
    assert "96.130522" not in response.text
    assert provider.calls == []


def test_real_route_endpoint_maps_directions_failure_to_existing_unavailable_error(
    real_navigation_app,
):
    provider = FailingProvider()
    configure_real_route_service(real_navigation_app, provider)

    with TestClient(real_navigation_app) as client:
        response = client.post(
            "/api/v1/route-suggestions",
            json={
                "origin": {"latitude": 16.856152, "longitude": 96.130522},
                "shelter_id": "verified-shelter",
                "disaster_type": "earthquake",
            },
        )

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "routing_unavailable"
    assert "16.856152" not in response.text
    assert "96.130522" not in response.text


def test_real_context_analysis_rejects_unsupported_snapshot_hazard_types(
    real_navigation_app,
):
    with TestClient(real_navigation_app) as client:
        response = client.post(
            "/api/v1/context-areas",
            json={
                "origin": {"latitude": 16.856152, "longitude": 96.130522},
                "disaster_type": "severe_weather",
            },
        )

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "context_analysis_unavailable"


def test_real_context_analysis_returns_named_mapped_candidate(
    real_navigation_app,
):
    service = real_navigation_app.state.navigation_service
    service._real_data = replace(
        service._real_data,
        hazards=(
            Hazard(
                id="current-earthquake",
                name="Current earthquake geometry",
                disaster_type="earthquake",
                geometry=PolygonGeometry(
                    coordinates=[
                        [
                            (96.16, 16.90),
                            (96.17, 16.90),
                            (96.17, 16.91),
                            (96.16, 16.91),
                            (96.16, 16.90),
                        ]
                    ]
                ),
                source="Test source",
                data_at=NOW,
                simulation=False,
            ),
        ),
    )
    provider = StubEnvironmentProvider(
        EnvironmentSnapshot(
            buildings=(
                BuildingFeature(
                    points=(
                        (96.15, 16.90),
                        (96.151, 16.90),
                        (96.151, 16.901),
                        (96.15, 16.901),
                        (96.15, 16.90),
                    ),
                    height_m=30.0,
                ),
            ),
            trees=((96.12, 16.84),),
            elevations_m=(),
            observed_at=NOW,
            source="OpenStreetMap via Overpass",
            open_spaces=(
                OpenSpaceFeature(
                    points=(
                        (96.129, 16.854),
                        (96.134, 16.854),
                        (96.134, 16.859),
                        (96.129, 16.859),
                        (96.129, 16.854),
                    ),
                    name="Named test park",
                    access="yes",
                ),
            ),
        )
    )
    service._context_analyzer._provider = provider

    with TestClient(real_navigation_app) as client:
        response = client.post(
            "/api/v1/context-areas",
            json={
                "origin": {"latitude": 16.856152, "longitude": 96.130522},
                "disaster_type": "earthquake",
                "scenario": "outdoors_after_shaking",
            },
        )

    assert response.status_code == 200
    payload = response.json()
    assert payload["simulation"] is False
    assert payload["items"][0]["name"] == "Named test park"
    assert payload["items"][0]["data_at"] == "2026-07-23T12:00:00Z"
    assert provider.calls[0]["include_obstacles"] is True
    assert provider.calls[0]["include_elevation"] is False
    assert provider.calls[0]["include_water"] is False


def test_real_analysis_can_include_labeled_simulation_data_without_mixing_lists(
    real_navigation_app_with_simulation_analysis,
):
    with TestClient(real_navigation_app_with_simulation_analysis) as client:
        context = client.post(
            "/api/v1/context-areas",
            json={
                "origin": {"latitude": 16.856152, "longitude": 96.130522},
                "disaster_type": "fire",
            },
        )
        hazards = client.get("/api/v1/hazards")

    assert context.status_code == 200
    payload = context.json()
    assert payload["simulation"] is True
    assert "SafeMyanmar Yangon snapshot" in payload["source"]
    assert "SafeMyanmar Demo simulation analysis data" in payload["source"]
    assert "backend analysis only" in payload["uncertainty_notice"]
    assert hazards.status_code == 200
    assert hazards.json()["simulation"] is False


def test_lists_remain_available_when_route_provider_has_no_token(
    enabled_navigation_app,
):
    with TestClient(enabled_navigation_app) as client:
        routes = client.post("/api/v1/route-suggestions", json=valid_request())
        shelters = client.get("/api/v1/shelters")
        hazards = client.get("/api/v1/hazards")

    assert routes.status_code == 503
    assert routes.json()["error"]["code"] == "routing_unavailable"
    assert "96.08" not in routes.text
    assert shelters.status_code == hazards.status_code == 200


def test_context_area_analysis_is_explicit_and_disaster_aware(enabled_navigation_app):
    enable_simulation(enabled_navigation_app)

    with TestClient(enabled_navigation_app) as client:
        earthquake = client.post(
            "/api/v1/context-areas",
            json={
                "origin": {"latitude": 21.95, "longitude": 96.08},
                "disaster_type": "earthquake",
                "scenario": "outdoors_after_shaking",
            },
        )
        flood = client.post(
            "/api/v1/context-areas",
            json={
                "origin": {"latitude": 21.95, "longitude": 96.08},
                "disaster_type": "flood",
            },
        )

    assert earthquake.status_code == flood.status_code == 200
    assert earthquake.json()["items"]
    assert flood.json()["items"]
    assert earthquake.json()["items"][0]["disaster_type"] == "earthquake"
    assert flood.json()["items"][0]["disaster_type"] == "flood"
    assert earthquake.json()["simulation"] is True
    assert flood.json()["items"][0]["metrics"]["relative_elevation_m"]


def test_context_area_analysis_supports_yangon_device_locations(
    enabled_navigation_app,
):
    enable_simulation(enabled_navigation_app)

    with TestClient(enabled_navigation_app) as client:
        response = client.post(
            "/api/v1/context-areas",
            json={
                "origin": {"latitude": 16.856152, "longitude": 96.130522},
                "disaster_type": "earthquake",
                "scenario": "outdoors_after_shaking",
            },
        )

    assert response.status_code == 200
    assert response.json()["items"]
    assert response.json()["items"][0]["simulation"] is True


def test_context_area_analysis_returns_guidance_during_active_earthquake(
    enabled_navigation_app,
):
    enable_simulation(enabled_navigation_app)

    with TestClient(enabled_navigation_app) as client:
        response = client.post(
            "/api/v1/context-areas",
            json={
                "origin": {"latitude": 21.95, "longitude": 96.08},
                "disaster_type": "earthquake",
                "scenario": "general",
            },
        )

    assert response.status_code == 200
    assert response.json()["items"] == []
    assert "Drop, Cover, and Hold On" in response.json()["uncertainty_notice"]


@pytest.mark.parametrize(
    "origin",
    [
        {"latitude": 91.0, "longitude": 96.08},
        {"latitude": -91.0, "longitude": 96.08},
        {"latitude": 21.95, "longitude": 181.0},
        {"latitude": 21.95, "longitude": -181.0},
        {"latitude": "21.95", "longitude": 96.08},
        {"latitude": 21.95},
    ],
)
def test_malformed_coordinates_return_safe_validation_error(
    enabled_navigation_app, origin
):
    enable_simulation(enabled_navigation_app)
    body = valid_request()
    body["origin"] = origin

    with TestClient(enabled_navigation_app) as client:
        response = client.post("/api/v1/route-suggestions", json=body)

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "invalid_request"
    assert "96.08" not in response.text
    assert '"longitude"' not in response.text
    assert "21.95" not in response.text


def test_route_response_includes_required_safety_metadata(enabled_navigation_app):
    route = DirectionsRoute(
        LineStringGeometry(
            type="LineString",
            coordinates=[(96.08, 21.95), (96.091, 21.958)],
        ),
        1000.0,
        600.0,
    )
    enable_simulation(enabled_navigation_app, (route,))

    with TestClient(enabled_navigation_app) as client:
        response = client.post("/api/v1/route-suggestions", json=valid_request())

    assert response.status_code == 200
    body = response.json()
    assert body["simulation"] is True
    assert body["source"] == "SafeMyanmar Demo"
    assert body["directions_provider"] == "Mapbox Directions"
    assert body["generated_at"] == "2026-07-23T12:00:00Z"
    assert body["hazard_data_at"]
    option = body["options"][0]
    for field in (
        "generated_at",
        "hazard_data_at",
        "profile",
        "source",
        "directions_provider",
        "simulation",
        "geometry",
        "distance_m",
        "duration_seconds",
        "hazard_intersection_count",
        "rationale",
        "recommended",
        "uncertainty_notice",
    ):
        assert field in option


def test_openapi_has_strict_navigation_contract(enabled_navigation_app):
    openapi = enabled_navigation_app.openapi()
    schemas = openapi["components"]["schemas"]
    coordinate = schemas["Coordinate"]
    request = schemas["RouteSuggestionRequest"]

    assert coordinate["additionalProperties"] is False
    assert coordinate["properties"]["latitude"]["minimum"] == -90.0
    assert coordinate["properties"]["latitude"]["maximum"] == 90.0
    assert coordinate["properties"]["longitude"]["minimum"] == -180.0
    assert coordinate["properties"]["longitude"]["maximum"] == 180.0
    assert set(request["required"]) == {"origin", "shelter_id", "disaster_type"}
    assert request["additionalProperties"] is False
    assert set(openapi["paths"]) >= {
        "/api/v1/shelters",
        "/api/v1/hazards",
        "/api/v1/route-suggestions",
    }
    route_schema = openapi["paths"]["/api/v1/route-suggestions"]["post"]["responses"][
        "200"
    ]["content"]["application/json"]["schema"]
    assert route_schema == {"$ref": "#/components/schemas/RouteSuggestionsResponse"}


def test_outside_coverage_is_safe_and_does_not_call_provider(enabled_navigation_app):
    provider = enable_simulation(enabled_navigation_app)
    body = valid_request()
    body["origin"] = {"latitude": 22.0, "longitude": 96.08}

    with TestClient(enabled_navigation_app) as client:
        response = client.post("/api/v1/route-suggestions", json=body)

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "outside_simulation_area"
    assert "22.0" not in response.text
    assert provider.calls == []


def test_route_posts_are_rate_limited_per_client_host(enabled_navigation_app):
    route = DirectionsRoute(
        LineStringGeometry(
            type="LineString",
            coordinates=[(96.08, 21.95), (96.091, 21.958)],
        ),
        1000.0,
        600.0,
    )
    enable_simulation(enabled_navigation_app, (route,))
    enabled_navigation_app.state.simulation_route_guard = SimulationRouteGuard(
        requests_per_window=1
    )

    with TestClient(enabled_navigation_app) as client:
        first = client.post("/api/v1/route-suggestions", json=valid_request())
        limited = client.post("/api/v1/route-suggestions", json=valid_request())

    assert first.status_code == 200
    assert limited.status_code == 429
    assert limited.json()["error"]["code"] == "route_rate_limit_exceeded"
    assert limited.headers["Retry-After"] == "60"
    assert "96.08" not in limited.text


def test_context_posts_are_rate_limited_per_client_host(enabled_navigation_app):
    enable_simulation(enabled_navigation_app)
    enabled_navigation_app.state.context_analysis_guard = ContextAnalysisGuard(
        requests_per_window=1
    )
    body = {
        "origin": {"latitude": 21.95, "longitude": 96.08},
        "disaster_type": "earthquake",
        "scenario": "outdoors_after_shaking",
    }

    with TestClient(enabled_navigation_app) as client:
        first = client.post("/api/v1/context-areas", json=body)
        limited = client.post("/api/v1/context-areas", json=body)

    assert first.status_code == 200
    assert limited.status_code == 429
    assert limited.json()["error"]["code"] == "context_rate_limit_exceeded"
    assert limited.headers["Retry-After"] == "60"


def test_context_analysis_concurrency_is_bounded(enabled_navigation_app):
    enable_simulation(enabled_navigation_app)
    guard = ContextAnalysisGuard(max_concurrent_calls=1)
    enabled_navigation_app.state.context_analysis_guard = guard
    body = {
        "origin": {"latitude": 21.95, "longitude": 96.08},
        "disaster_type": "earthquake",
        "scenario": "outdoors_after_shaking",
    }

    with guard.provider_slot(), TestClient(enabled_navigation_app) as client:
        response = client.post("/api/v1/context-areas", json=body)

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "context_analysis_busy"
    assert response.headers["Retry-After"] == "1"


def test_rate_limit_state_is_anonymized_bounded_and_short_lived():
    now = [100.0]
    guard = SimulationRouteGuard(
        window_seconds=60.0,
        max_clients=2,
        clock=lambda: now[0],
    )

    guard.record_request("client-a")
    guard.record_request("client-b")
    guard.record_request("client-c")

    assert len(guard._clients) == 2
    assert all(isinstance(key, bytes) and len(key) == 16 for key in guard._clients)
    assert all(b"client" not in key for key in guard._clients)

    now[0] += 61.0
    guard.record_request("client-d")

    assert len(guard._clients) == 1


def test_concurrent_provider_calls_are_bounded(enabled_navigation_app):
    provider = enable_simulation(enabled_navigation_app)
    guard = SimulationRouteGuard(max_concurrent_calls=1)
    enabled_navigation_app.state.simulation_route_guard = guard

    with guard.provider_slot(), TestClient(enabled_navigation_app) as client:
        response = client.post("/api/v1/route-suggestions", json=valid_request())

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "routing_busy"
    assert response.headers["Retry-After"] == "1"
    assert "96.08" not in response.text
    assert provider.calls == []


def test_lifespan_closes_app_scoped_mapbox_http_client(monkeypatch):
    monkeypatch.setenv("ENABLE_SIMULATION_DATA", "true")
    application = create_app()
    provider = application.state.navigation_service._directions
    http_client = provider._http_client

    assert not http_client.is_closed
    with TestClient(application):
        pass

    assert http_client.is_closed
