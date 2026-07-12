from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import create_engine

from app.api.health import router as health_router
from app.api.v1.router import router as v1_router
from app.core.config import Settings
from app.core.errors import register_error_handlers
from app.core.request_id import RequestIdMiddleware
from app.database.session import create_session_factory
from app.providers.usgs.client import UsgsClient
from app.providers.usgs.normalizer import normalize_feed
from app.repositories.earthquakes import EarthquakeRepository, ProviderSyncRepository
from app.services.earthquakes import EarthquakeService


def create_app() -> FastAPI:
    settings = Settings()
    engine = create_engine(settings.database_url)
    session_factory = create_session_factory(engine)
    client = UsgsClient(settings.usgs_feed_url, settings.provider_timeout_seconds)
    earthquake_service = EarthquakeService(
        client=client,
        earthquake_repository=EarthquakeRepository(),
        provider_sync_repository=ProviderSyncRepository(),
        normalizer=normalize_feed,
        refresh_minimum_seconds=settings.refresh_minimum_seconds,
        current_max_age_seconds=settings.current_max_age_seconds,
    )

    @asynccontextmanager
    async def lifespan(_application: FastAPI) -> AsyncIterator[None]:
        yield
        try:
            client.close()
        finally:
            engine.dispose()

    application = FastAPI(title="SafeMyanmar API", lifespan=lifespan)
    application.state.engine = engine
    application.state.session_factory = session_factory
    application.state.earthquake_service = earthquake_service
    application.add_middleware(RequestIdMiddleware)
    register_error_handlers(application)
    application.include_router(health_router)
    application.include_router(v1_router)
    return application


app = create_app()
