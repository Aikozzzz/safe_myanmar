import json
import logging
from dataclasses import dataclass
from math import isfinite
from types import TracebackType
from typing import Any

import httpx
from pydantic import ValidationError

from app.schemas.navigation import Coordinate, LineStringGeometry, RouteProfile

MAPBOX_DIRECTIONS_BASE_URL = "https://api.mapbox.com/directions/v5/mapbox"
MAX_RESPONSE_BYTES = 1024 * 1024
RESPONSE_CHUNK_BYTES = 64 * 1024
MAX_ROUTES = 3
MAX_ROUTE_POINTS = 5000


class _RedactHttpxRequestUrl(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        if (
            record.msg == 'HTTP Request: %s %s "%s %d %s"'
            and isinstance(record.args, tuple)
            and len(record.args) == 5
        ):
            record.args = (record.args[0], "[redacted]", *record.args[2:])
        return True


# HTTPX logs complete request URLs at INFO, which would expose route coordinates
# and query-string credentials when an operator enables that logger.
logging.getLogger("httpx").addFilter(_RedactHttpxRequestUrl())


class DirectionsProviderError(Exception):
    code = "routing_unavailable"

    def __init__(self) -> None:
        super().__init__(self.code)


@dataclass(frozen=True, slots=True)
class DirectionsRoute:
    geometry: LineStringGeometry
    distance_m: float
    duration_seconds: float


class MapboxDirectionsProvider:
    def __init__(
        self,
        access_token: str | None,
        timeout_seconds: float = 10.0,
        http_client: httpx.Client | None = None,
    ) -> None:
        self._access_token = access_token
        self._timeout_seconds = timeout_seconds
        self._owns_http_client = http_client is None
        self._http_client = http_client or httpx.Client()

    def get_routes(
        self,
        origin: Coordinate,
        destination: Coordinate,
        profile: RouteProfile,
    ) -> tuple[DirectionsRoute, ...]:
        if not self._access_token:
            raise DirectionsProviderError

        coordinates = (
            f"{origin.longitude},{origin.latitude};"
            f"{destination.longitude},{destination.latitude}"
        )
        url = f"{MAPBOX_DIRECTIONS_BASE_URL}/{profile}/{coordinates}"
        try:
            with self._http_client.stream(
                "GET",
                url,
                params={
                    "access_token": self._access_token,
                    "alternatives": "true",
                    "geometries": "geojson",
                    "overview": "full",
                },
                timeout=self._timeout_seconds,
            ) as response:
                response.raise_for_status()
                content_length = response.headers.get("content-length")
                if (
                    content_length is not None
                    and int(content_length) > MAX_RESPONSE_BYTES
                ):
                    raise DirectionsProviderError
                content = bytearray()
                for chunk in response.iter_bytes(chunk_size=RESPONSE_CHUNK_BYTES):
                    content.extend(chunk)
                    if len(content) > MAX_RESPONSE_BYTES:
                        raise DirectionsProviderError
            payload = json.loads(content)
            return self._parse_routes(payload)
        except (
            httpx.HTTPError,
            OverflowError,
            RecursionError,
            UnicodeDecodeError,
            ValueError,
            TypeError,
            KeyError,
        ):
            raise DirectionsProviderError from None

    @staticmethod
    def _parse_routes(payload: Any) -> tuple[DirectionsRoute, ...]:
        if not isinstance(payload, dict) or not isinstance(payload.get("routes"), list):
            raise DirectionsProviderError

        route_payloads = payload["routes"]
        if not 1 <= len(route_payloads) <= MAX_ROUTES:
            raise DirectionsProviderError

        parsed: list[DirectionsRoute] = []
        for route in route_payloads:
            if not isinstance(route, dict):
                raise DirectionsProviderError
            try:
                distance = _nonnegative_finite_float(route.get("distance"))
                duration = _nonnegative_finite_float(route.get("duration"))
                geometry_payload = route.get("geometry")
                if (
                    not isinstance(geometry_payload, dict)
                    or geometry_payload.get("type") != "LineString"
                    or not isinstance(geometry_payload.get("coordinates"), list)
                ):
                    raise DirectionsProviderError
                coordinate_payloads = geometry_payload["coordinates"]
                if not 2 <= len(coordinate_payloads) <= MAX_ROUTE_POINTS:
                    raise DirectionsProviderError
                coordinates = []
                for pair in coordinate_payloads:
                    if not isinstance(pair, list) or len(pair) != 2:
                        raise DirectionsProviderError
                    coordinates.append((_finite_float(pair[0]), _finite_float(pair[1])))
                geometry = LineStringGeometry(
                    type="LineString", coordinates=coordinates
                )
            except (
                DirectionsProviderError,
                OverflowError,
                TypeError,
                ValidationError,
                ValueError,
            ):
                raise DirectionsProviderError from None
            parsed.append(DirectionsRoute(geometry, distance, duration))
        return tuple(parsed)

    def close(self) -> None:
        if self._owns_http_client:
            self._http_client.close()

    def __enter__(self) -> "MapboxDirectionsProvider":
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: TracebackType | None,
    ) -> None:
        self.close()


def _finite_float(value: Any) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise DirectionsProviderError
    converted = float(value)
    if not isfinite(converted):
        raise DirectionsProviderError
    return converted


def _nonnegative_finite_float(value: Any) -> float:
    converted = _finite_float(value)
    if converted < 0:
        raise DirectionsProviderError
    return converted
