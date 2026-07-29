from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import create_engine

from app.api.health import router as health_router
from app.api.v1.router import create_router as create_v1_router
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
    directions_provider = None
    navigation_service = None
    simulation_route_guard = None
    if settings.enable_simulation_data:
        from app.api.v1.navigation import SimulationRouteGuard
        from app.providers.mapbox.directions import MapboxDirectionsProvider
        from app.services.navigation import NavigationService

        mapbox_token = (
            settings.mapbox_directions_access_token.get_secret_value()
            if settings.mapbox_directions_access_token is not None
            else None
        )
        directions_provider = MapboxDirectionsProvider(
            mapbox_token, settings.provider_timeout_seconds
        )
        navigation_service = NavigationService(True, directions_provider)
        simulation_route_guard = SimulationRouteGuard()

    @asynccontextmanager
    async def lifespan(_application: FastAPI) -> AsyncIterator[None]:
        yield
        try:
            client.close()
        finally:
            try:
                if directions_provider is not None:
                    directions_provider.close()
            finally:
                engine.dispose()

    application = FastAPI(title="SafeMyanmar API", lifespan=lifespan)
    application.state.engine = engine
    application.state.session_factory = session_factory
    application.state.earthquake_service = earthquake_service
    if navigation_service is not None:
        application.state.navigation_service = navigation_service
        application.state.simulation_route_guard = simulation_route_guard
    application.add_middleware(RequestIdMiddleware)
    register_error_handlers(application)
    application.include_router(health_router)
    application.include_router(
        create_v1_router(enable_simulation_data=settings.enable_simulation_data)
    )
    return application


app = create_app()
