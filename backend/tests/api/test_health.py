from fastapi.testclient import TestClient
from starlette.requests import Request

from app.api.health import NavigationDataNotReady, get_readiness_checker


class ReadyChecker:
    def check(self) -> None:
        return None


class UnavailableChecker:
    def check(self) -> None:
        raise RuntimeError(
            "could not connect to postgresql://admin:secret@database/internal"
        )


class MissingNavigationDataChecker:
    def check(self) -> None:
        raise NavigationDataNotReady("navigation_data_missing")


def test_liveness_returns_ok(client):
    response = client.get("/health/live")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_method_not_allowed_preserves_allow_header(client):
    response = client.post("/health/live")

    assert response.status_code == 405
    assert response.headers["Allow"] == "GET"


def test_readiness_returns_ok_when_database_is_available(app, client):
    app.dependency_overrides[get_readiness_checker] = lambda: ReadyChecker()

    response = client.get("/health/ready")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readiness_reuses_application_engine(app):
    request = Request({"type": "http", "app": app})

    checker = get_readiness_checker(request)

    assert checker.engine is app.state.engine


def test_readiness_uses_safe_error_when_database_is_unavailable(app, client):
    app.dependency_overrides[get_readiness_checker] = lambda: UnavailableChecker()

    response = client.get("/health/ready")

    assert response.status_code == 503
    body = response.json()
    assert body["error"]["code"] == "service_unavailable"
    assert body["error"]["request_id"]
    assert "postgresql://" not in response.text
    assert "admin" not in response.text
    assert "secret" not in response.text
    assert "could not connect" not in response.text


def test_readiness_exposes_missing_navigation_data_safely(app, client):
    app.dependency_overrides[get_readiness_checker] = lambda: (
        MissingNavigationDataChecker()
    )

    response = client.get("/health/ready")

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "navigation_data_missing"
    assert "snapshot is missing" in response.json()["error"]["message"]


def test_unexpected_error_uses_consistent_request_id_in_body_and_header(app):
    @app.get("/test/unexpected")
    def unexpected_error():
        raise RuntimeError("controlled test failure")

    with TestClient(app, raise_server_exceptions=False) as test_client:
        response = test_client.get("/test/unexpected")

    assert response.status_code == 500
    request_id = response.json()["error"]["request_id"]
    assert request_id
    assert response.headers["X-Request-ID"] == request_id


def test_unknown_route_uses_safe_error_shape(client):
    response = client.get("/missing")

    assert response.status_code == 404
    request_id = response.json()["error"]["request_id"]
    assert request_id
    assert response.json() == {
        "error": {
            "code": "not_found",
            "message": "The requested resource was not found.",
            "request_id": request_id,
        }
    }
