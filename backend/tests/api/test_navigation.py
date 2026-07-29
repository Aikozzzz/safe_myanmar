from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from app.api.v1.navigation import SimulationRouteGuard, get_navigation_service
from app.main import create_app
from app.providers.mapbox.directions import DirectionsRoute
from app.schemas.navigation import LineStringGeometry
from app.services.navigation import NavigationService

NOW = datetime(2026, 7, 23, 12, 0, tzinfo=UTC)


class StubProvider:
    def __init__(self, routes=()):
        self.routes = routes
        self.calls = []

    def get_routes(self, origin, destination, profile):
        self.calls.append((origin, destination, profile))
        return self.routes


@pytest.fixture
def navigation_app():
    return create_app()


@pytest.fixture
def enabled_navigation_app(monkeypatch):
    monkeypatch.setenv("ENABLE_SIMULATION_DATA", "true")
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


def test_endpoints_are_disabled_by_default(navigation_app):
    with TestClient(navigation_app) as client:
        shelters = client.get("/api/v1/shelters")
        hazards = client.get("/api/v1/hazards")
        routes = client.post("/api/v1/route-suggestions", content=b"not-json")

    assert shelters.status_code == hazards.status_code == routes.status_code == 404
    assert shelters.json()["error"]["code"] == "not_found"
    assert hazards.json()["error"]["code"] == "not_found"
    assert routes.json()["error"]["code"] == "not_found"
    assert "/api/v1/alerts" in navigation_app.openapi()["paths"]
    assert "/api/v1/route-suggestions" not in navigation_app.openapi()["paths"]


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
    assert "181" not in response.text
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
