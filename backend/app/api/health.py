from typing import Protocol

from fastapi import APIRouter, Depends, Request
from sqlalchemy import text
from sqlalchemy.engine import Engine

from app.core.errors import ApiError

router = APIRouter(prefix="/health", tags=["health"])


class ReadinessChecker(Protocol):
    def check(self) -> None: ...


class DatabaseReadinessChecker:
    def __init__(self, engine: Engine) -> None:
        self.engine = engine

    def check(self) -> None:
        with self.engine.connect() as connection:
            connection.execute(text("SELECT 1"))


def get_readiness_checker(request: Request) -> ReadinessChecker:
    return DatabaseReadinessChecker(request.app.state.engine)


@router.get("/live")
def liveness() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/ready")
def readiness(
    checker: ReadinessChecker = Depends(get_readiness_checker),
) -> dict[str, str]:
    try:
        checker.check()
    except Exception as exc:
        raise ApiError(
            503,
            "service_unavailable",
            "The service is not ready.",
        ) from exc
    return {"status": "ok"}
