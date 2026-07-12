from fastapi import FastAPI

from app.api.health import router as health_router
from app.core.errors import register_error_handlers
from app.core.request_id import RequestIdMiddleware


def create_app() -> FastAPI:
    application = FastAPI(title="SafeMyanmar API")
    application.add_middleware(RequestIdMiddleware)
    register_error_handlers(application)
    application.include_router(health_router)
    return application


app = create_app()
