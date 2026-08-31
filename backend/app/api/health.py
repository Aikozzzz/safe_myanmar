from typing import Protocol

from fastapi import APIRouter, Depends, Request
from sqlalchemy import text
from sqlalchemy.engine import Engine

from app.core.errors import ApiError

router = APIRouter(prefix="/health", tags=["health"])


class ReadinessChecker(Protocol):
    def check(self) -> None: ...


class NavigationDataNotReady(Exception):
    def __init__(self, reason: str) -> None:
        super().__init__(reason)
        self.reason = reason


class DatabaseReadinessChecker:
    def __init__(
        self, engine: Engine, navigation_data_error: str | None = None
    ) -> None:
        self.engine = engine
        self.navigation_data_error = navigation_data_error

    def check(self) -> None:
        with self.engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        if self.navigation_data_error is not None:
            raise NavigationDataNotReady(self.navigation_data_error)


def get_readiness_checker(request: Request) -> ReadinessChecker:
    return DatabaseReadinessChecker(
        request.app.state.engine,
        getattr(request.app.state, "navigation_data_error", None),
    )


@router.get("/live")
def liveness() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/ready")
def readiness(
    checker: ReadinessChecker = Depends(get_readiness_checker),
) -> dict[str, str]:
    try:
        checker.check()
    except NavigationDataNotReady as exc:
        messages = {
            "navigation_data_missing": (
                "The configured navigation data snapshot is missing."
            ),
            "navigation_data_stale": (
                "The configured navigation data snapshot is too old for runtime use."
            ),
            "navigation_data_invalid": (
                "The configured navigation data snapshot is invalid."
            ),
        }
        raise ApiError(
            503,
            exc.reason if exc.reason in messages else "navigation_data_unavailable",
            messages.get(exc.reason, "Navigation data is currently unavailable."),
        ) from exc
    except Exception as exc:
        raise ApiError(
            503,
            "service_unavailable",
            "The service is not ready.",
        ) from exc
    return {"status": "ok"}
