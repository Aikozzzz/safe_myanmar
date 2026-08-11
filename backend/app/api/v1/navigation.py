from collections import OrderedDict, deque
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from hashlib import blake2s
from secrets import token_bytes
from threading import BoundedSemaphore, Lock
from time import monotonic

from fastapi import APIRouter, Depends, Request

from app.core.errors import ApiError
from app.schemas.navigation import (
    ContextAreaListResponse,
    ContextAreaRequest,
    HazardListResponse,
    RouteSuggestionRequest,
    RouteSuggestionsResponse,
    ShelterListResponse,
)
from app.services.navigation import (
    NavigationService,
    OutsideSimulationArea,
    RoutingUnavailable,
    ShelterNotFound,
)

router = APIRouter(tags=["simulation navigation"])
RATE_LIMIT_REQUESTS = 30
RATE_LIMIT_WINDOW_SECONDS = 60.0
MAX_RATE_LIMIT_CLIENTS = 1024
MAX_CONCURRENT_MAPBOX_CALLS = 4


class RouteRateLimitExceeded(Exception):
    pass


class RouteCapacityExceeded(Exception):
    pass


class SimulationRouteGuard:
    def __init__(
        self,
        *,
        requests_per_window: int = RATE_LIMIT_REQUESTS,
        window_seconds: float = RATE_LIMIT_WINDOW_SECONDS,
        max_clients: int = MAX_RATE_LIMIT_CLIENTS,
        max_concurrent_calls: int = MAX_CONCURRENT_MAPBOX_CALLS,
        clock: Callable[[], float] | None = None,
    ) -> None:
        self._requests_per_window = requests_per_window
        self._window_seconds = window_seconds
        self._max_clients = max_clients
        self._clock = clock or monotonic
        self._client_hash_key = token_bytes(16)
        self._clients: OrderedDict[bytes, deque[float]] = OrderedDict()
        self._clients_lock = Lock()
        self._provider_slots = BoundedSemaphore(max_concurrent_calls)

    def record_request(self, client_host: str) -> None:
        client_key = blake2s(
            client_host.encode("utf-8"), key=self._client_hash_key, digest_size=16
        ).digest()
        now = self._clock()
        cutoff = now - self._window_seconds
        with self._clients_lock:
            for key in tuple(self._clients):
                attempts = self._clients[key]
                while attempts and attempts[0] <= cutoff:
                    attempts.popleft()
                if not attempts:
                    del self._clients[key]

            attempts = self._clients.setdefault(client_key, deque())
            self._clients.move_to_end(client_key)
            if len(attempts) >= self._requests_per_window:
                raise RouteRateLimitExceeded
            attempts.append(now)
            while len(self._clients) > self._max_clients:
                self._clients.popitem(last=False)

    @contextmanager
    def provider_slot(self) -> Iterator[None]:
        if not self._provider_slots.acquire(blocking=False):
            raise RouteCapacityExceeded
        try:
            yield
        finally:
            self._provider_slots.release()


def get_navigation_service(request: Request) -> NavigationService:
    return request.app.state.navigation_service


def get_simulation_route_guard(request: Request) -> SimulationRouteGuard:
    return request.app.state.simulation_route_guard


def enforce_route_rate_limit(
    request: Request,
    guard: SimulationRouteGuard = Depends(get_simulation_route_guard),
) -> SimulationRouteGuard:
    client_host = request.client.host if request.client is not None else "unknown"
    try:
        guard.record_request(client_host)
    except RouteRateLimitExceeded as error:
        raise ApiError(
            429,
            "route_rate_limit_exceeded",
            "Too many route requests. Try again shortly.",
            headers={"Retry-After": str(int(RATE_LIMIT_WINDOW_SECONDS))},
        ) from error
    return guard


@router.get("/shelters", response_model=ShelterListResponse)
def list_shelters(
    service: NavigationService = Depends(get_navigation_service),
) -> ShelterListResponse:
    return service.list_shelters()


@router.get("/hazards", response_model=HazardListResponse)
def list_hazards(
    service: NavigationService = Depends(get_navigation_service),
) -> HazardListResponse:
    return service.list_hazards()


@router.post("/context-areas", response_model=ContextAreaListResponse)
def find_context_areas(
    context_request: ContextAreaRequest,
    service: NavigationService = Depends(get_navigation_service),
) -> ContextAreaListResponse:
    try:
        return service.find_context_areas(context_request)
    except OutsideSimulationArea as error:
        raise ApiError(
            400,
            "outside_simulation_area",
            "The origin is outside the SIMULATION coverage area.",
        ) from error


@router.post("/route-suggestions", response_model=RouteSuggestionsResponse)
def suggest_routes(
    route_request: RouteSuggestionRequest,
    service: NavigationService = Depends(get_navigation_service),
    guard: SimulationRouteGuard = Depends(enforce_route_rate_limit),
) -> RouteSuggestionsResponse:
    try:
        with guard.provider_slot():
            return service.suggest_routes(route_request)
    except RouteCapacityExceeded as error:
        raise ApiError(
            503,
            "routing_busy",
            "Route suggestions are busy. Try again shortly.",
            headers={"Retry-After": "1"},
        ) from error
    except OutsideSimulationArea as error:
        raise ApiError(
            400,
            "outside_simulation_area",
            "The origin is outside the SIMULATION coverage area.",
        ) from error
    except ShelterNotFound as error:
        raise ApiError(
            404,
            "shelter_not_found",
            "The requested SIMULATION shelter was not found.",
        ) from error
    except RoutingUnavailable as error:
        raise ApiError(
            503,
            "routing_unavailable",
            "Route suggestions are currently unavailable. SIMULATION shelter and "
            "hazard information remains available.",
        ) from error
