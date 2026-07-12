from app.api.health import get_readiness_checker


class ReadyChecker:
    def check(self) -> None:
        return None


class UnavailableChecker:
    def check(self) -> None:
        raise RuntimeError(
            "could not connect to postgresql://admin:secret@database/internal"
        )


def test_liveness_returns_ok(client):
    response = client.get("/health/live")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readiness_returns_ok_when_database_is_available(app, client):
    app.dependency_overrides[get_readiness_checker] = lambda: ReadyChecker()

    response = client.get("/health/ready")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


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


def test_unknown_route_uses_safe_error_shape(client):
    response = client.get("/missing")
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"
    assert response.json()["error"]["request_id"]
    assert response.json()["error"]["message"] == (
        "The requested resource was not found."
    )
