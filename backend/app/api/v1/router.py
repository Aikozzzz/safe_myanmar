from fastapi import APIRouter

from app.api.v1.alerts import router as alerts_router


def create_router(*, enable_simulation_data: bool) -> APIRouter:
    router = APIRouter(prefix="/api/v1")
    router.include_router(alerts_router)
    if enable_simulation_data:
        from app.api.v1.navigation import router as navigation_router

        router.include_router(navigation_router)
    return router
