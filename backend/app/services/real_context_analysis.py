from collections.abc import Sequence
from dataclasses import dataclass
from datetime import UTC, datetime
from math import asin, cos, radians, sin, sqrt
from re import search
from typing import Any, Protocol

import httpx

from app.schemas.navigation import (
    ContextArea,
    ContextAreaListResponse,
    ContextAreaRequest,
    ContextMetrics,
    Coordinate,
    Hazard,
)

MAX_ENVIRONMENT_RESPONSE_BYTES = 2 * 1024 * 1024
EARTHQUAKE_BUILDING_CLEARANCE_M = 25.0
EARTHQUAKE_HIGH_BUILDING_CLEARANCE_M = 50.0
EARTHQUAKE_TREE_CLEARANCE_M = 20.0
HIGH_BUILDING_HEIGHT_M = 10.0


class ContextAnalysisUnavailable(Exception):
    pass


@dataclass(frozen=True)
class BuildingFeature:
    points: tuple[tuple[float, float], ...]
    height_m: float | None

    @property
    def is_high(self) -> bool:
        return self.height_m is not None and self.height_m >= HIGH_BUILDING_HEIGHT_M


@dataclass(frozen=True)
class EnvironmentSnapshot:
    buildings: tuple[BuildingFeature, ...]
    trees: tuple[tuple[float, float], ...]
    elevations_m: tuple[float, ...]
    observed_at: datetime
    source: str


class EnvironmentProvider(Protocol):
    def observe(
        self,
        origin: Coordinate,
        candidates: Sequence[Coordinate],
        radius_m: float,
        *,
        include_obstacles: bool,
        include_elevation: bool,
    ) -> EnvironmentSnapshot: ...

    def close(self) -> None: ...


class LiveEnvironmentProvider:
    def __init__(
        self,
        *,
        overpass_url: str,
        elevation_url: str,
        timeout_seconds: float,
        http_client: httpx.Client | None = None,
    ) -> None:
        self._overpass_url = overpass_url
        self._elevation_url = elevation_url
        self._timeout_seconds = timeout_seconds
        self._owns_http_client = http_client is None
        self._http_client = http_client or httpx.Client()

    def observe(
        self,
        origin: Coordinate,
        candidates: Sequence[Coordinate],
        radius_m: float,
        *,
        include_obstacles: bool,
        include_elevation: bool,
    ) -> EnvironmentSnapshot:
        buildings: tuple[BuildingFeature, ...] = ()
        trees: tuple[tuple[float, float], ...] = ()
        elevations: tuple[float, ...] = ()
        sources = []
        if include_obstacles:
            buildings, trees = self._load_obstacles(origin, radius_m)
            sources.append("OpenStreetMap via Overpass")
        if include_elevation:
            elevations = self._load_elevations(
                (*candidates,),
            )
            sources.append("OpenTopoData")
        if not sources:
            raise ContextAnalysisUnavailable
        return EnvironmentSnapshot(
            buildings=buildings,
            trees=trees,
            elevations_m=elevations,
            observed_at=datetime.now(UTC),
            source=" + ".join(sources),
        )

    def _load_obstacles(
        self, origin: Coordinate, radius_m: float
    ) -> tuple[tuple[BuildingFeature, ...], tuple[tuple[float, float], ...]]:
        query = f"""[out:json][timeout:{max(1, round(self._timeout_seconds))}];
(
  way[building](around:{radius_m},{origin.latitude},{origin.longitude});
  node[natural=tree](around:{radius_m},{origin.latitude},{origin.longitude});
);
 out tags center;"""
        payload = self._request_json(
            self._http_client.get,
            self._overpass_url,
            params={"data": query},
        )
        elements = payload.get("elements")
        if not isinstance(elements, list):
            raise ContextAnalysisUnavailable

        buildings = []
        trees = []
        for element in elements:
            if not isinstance(element, dict):
                continue
            tags = element.get("tags")
            if not isinstance(tags, dict):
                tags = {}
            if element.get("type") == "way" and "building" in tags:
                points = _way_points(element.get("geometry"), element.get("center"))
                if points:
                    buildings.append(BuildingFeature(points, _building_height_m(tags)))
            elif element.get("type") == "node" and tags.get("natural") == "tree":
                latitude = element.get("lat")
                longitude = element.get("lon")
                if _valid_coordinate(latitude, longitude):
                    trees.append((float(longitude), float(latitude)))
        return tuple(buildings), tuple(trees)

    def _load_elevations(self, candidates: Sequence[Coordinate]) -> tuple[float, ...]:
        locations = "|".join(
            f"{candidate.latitude:.6f},{candidate.longitude:.6f}"
            for candidate in candidates
        )
        payload = self._request_json(
            self._http_client.get,
            self._elevation_url,
            params={"locations": locations},
        )
        results = payload.get("results")
        if not isinstance(results, list) or len(results) != len(candidates):
            raise ContextAnalysisUnavailable
        elevations = []
        for result in results:
            if not isinstance(result, dict) or not isinstance(
                result.get("elevation"), (int, float)
            ):
                raise ContextAnalysisUnavailable
            elevations.append(float(result["elevation"]))
        return tuple(elevations)

    def _request_json(self, request, url: str, **kwargs: Any) -> dict[str, Any]:
        try:
            response = request(
                url,
                timeout=self._timeout_seconds,
                headers={"User-Agent": "SafeMyanmar/1.0"},
                **kwargs,
            )
            response.raise_for_status()
            if len(response.content) > MAX_ENVIRONMENT_RESPONSE_BYTES:
                raise ContextAnalysisUnavailable
            payload = response.json()
        except (
            ContextAnalysisUnavailable,
            httpx.HTTPError,
            ValueError,
            TypeError,
        ):
            raise ContextAnalysisUnavailable from None
        if not isinstance(payload, dict):
            raise ContextAnalysisUnavailable
        return payload

    def close(self) -> None:
        if self._owns_http_client:
            self._http_client.close()


class RealContextAnalyzer:
    def __init__(self, provider: EnvironmentProvider) -> None:
        self._provider = provider

    def find_context_areas(
        self,
        request: ContextAreaRequest,
        hazards: Sequence[Hazard],
        *,
        source: str,
        uncertainty_notice: str,
    ) -> ContextAreaListResponse:
        if request.disaster_type == "earthquake" and request.scenario != (
            "outdoors_after_shaking"
        ):
            return _empty_response(
                source,
                uncertainty_notice
                + " During active shaking, use Drop, Cover, and Hold On "
                "instead of moving to a suggested area.",
            )
        relevant_hazards = tuple(
            hazard
            for hazard in hazards
            if hazard.disaster_type == request.disaster_type
        )
        if not relevant_hazards:
            return _empty_response(
                source,
                uncertainty_notice
                + f" No current verified {request.disaster_type} hazard "
                "geometry is available in this snapshot, so nearby analysis "
                "was not generated.",
            )

        candidates = _candidate_coordinates(request.origin, request.search_radius_m)
        environment_points = (request.origin, *candidates)
        if request.disaster_type in {"earthquake", "flood"}:
            snapshot = self._provider.observe(
                request.origin,
                environment_points,
                request.search_radius_m,
                include_obstacles=request.disaster_type == "earthquake",
                include_elevation=request.disaster_type == "flood",
            )
        else:
            snapshot = EnvironmentSnapshot(
                buildings=(),
                trees=(),
                elevations_m=(),
                observed_at=max(hazard.data_at for hazard in relevant_hazards),
                source="current snapshot hazard geometry",
            )
        origin_elevation = snapshot.elevations_m[0] if snapshot.elevations_m else None
        ranked = []
        for index, candidate in enumerate(candidates):
            hazard_count = sum(
                _point_in_polygon(
                    (candidate.longitude, candidate.latitude),
                    hazard.geometry.coordinates[0],
                )
                for hazard in relevant_hazards
            )
            building_clearance = _nearest_distance(
                (candidate.longitude, candidate.latitude),
                (
                    building_point
                    for building in snapshot.buildings
                    for building_point in building.points
                ),
                request.search_radius_m,
            )
            high_building_clearance = _nearest_distance(
                (candidate.longitude, candidate.latitude),
                (
                    building_point
                    for building in snapshot.buildings
                    if building.is_high
                    for building_point in building.points
                ),
                request.search_radius_m,
            )
            tree_clearance = _nearest_distance(
                (candidate.longitude, candidate.latitude),
                snapshot.trees,
                request.search_radius_m,
            )
            relative_elevation = (
                snapshot.elevations_m[index + 1] - origin_elevation
                if origin_elevation is not None
                else 0.0
            )
            building_density = _density(
                (candidate.longitude, candidate.latitude),
                (_feature_center(building.points) for building in snapshot.buildings),
                20,
            )
            tree_density = _density(
                (candidate.longitude, candidate.latitude), snapshot.trees, 30
            )
            if not _candidate_allowed(
                request.disaster_type,
                hazard_count,
                building_clearance,
                high_building_clearance,
                tree_clearance,
                relative_elevation,
            ):
                continue
            rationale = _rationale(
                request.disaster_type,
                hazard_count,
                building_clearance,
                high_building_clearance,
                tree_clearance,
                relative_elevation,
            )
            ranking = _ranking(
                request.disaster_type,
                hazard_count,
                building_clearance,
                high_building_clearance,
                tree_clearance,
                relative_elevation,
                index,
            )
            ranked.append(
                (
                    ranking,
                    ContextArea(
                        id=_context_area_id(candidate, request.disaster_type),
                        name=_candidate_name(request.disaster_type, index + 1),
                        coordinate=candidate,
                        disaster_type=request.disaster_type,
                        scenario=request.scenario,
                        distance_m=round(_distance_m(request.origin, candidate), 1),
                        metrics=ContextMetrics(
                            building_clearance_m=round(building_clearance, 1),
                            tree_clearance_m=round(tree_clearance, 1),
                            relative_elevation_m=round(relative_elevation, 1),
                            building_density=round(building_density, 3),
                            tree_density=round(tree_density, 3),
                            hazard_intersections=hazard_count,
                        ),
                        rationale=rationale,
                        source=f"{source}; {snapshot.source}",
                        data_at=snapshot.observed_at,
                        simulation=False,
                        uncertainty_notice=uncertainty_notice
                        + " "
                        + _coverage_notice(request.disaster_type),
                    ),
                )
            )
        items = [item for _, item in sorted(ranked, key=lambda value: value[0])][:3]
        return ContextAreaListResponse(
            items=items,
            data_at=snapshot.observed_at,
            source=f"{source}; {snapshot.source}",
            simulation=False,
            uncertainty_notice=(
                uncertainty_notice + " " + _coverage_notice(request.disaster_type)
                if items
                else uncertainty_notice
                + " No candidate met the requested disaster-specific criteria "
                "within the selected radius."
            ),
        )


def _candidate_coordinates(
    origin: Coordinate, radius_m: float
) -> tuple[Coordinate, ...]:
    latitude_degrees = radius_m / 111_000
    longitude_degrees = radius_m / 104_000
    offsets = (
        (latitude_degrees * 0.55, 0.0),
        (-latitude_degrees * 0.55, 0.0),
        (0.0, longitude_degrees * 0.55),
        (0.0, -longitude_degrees * 0.55),
        (latitude_degrees * 0.7, longitude_degrees * 0.7),
        (-latitude_degrees * 0.7, -longitude_degrees * 0.7),
        (-latitude_degrees * 0.7, longitude_degrees * 0.7),
        (latitude_degrees * 0.7, -longitude_degrees * 0.7),
    )
    return tuple(
        Coordinate(
            latitude=origin.latitude + latitude_delta,
            longitude=origin.longitude + longitude_delta,
        )
        for latitude_delta, longitude_delta in offsets
    )


def _candidate_allowed(
    disaster_type: str,
    hazard_count: int,
    building_clearance: float,
    high_building_clearance: float,
    tree_clearance: float,
    relative_elevation: float,
) -> bool:
    if hazard_count:
        return False
    if disaster_type == "earthquake":
        return (
            building_clearance >= EARTHQUAKE_BUILDING_CLEARANCE_M
            and high_building_clearance >= EARTHQUAKE_HIGH_BUILDING_CLEARANCE_M
            and tree_clearance >= EARTHQUAKE_TREE_CLEARANCE_M
        )
    if disaster_type == "flood":
        return relative_elevation > 0.0
    return True


def _ranking(
    disaster_type: str,
    hazard_count: int,
    building_clearance: float,
    high_building_clearance: float,
    tree_clearance: float,
    relative_elevation: float,
    index: int,
) -> tuple[float, ...]:
    if disaster_type == "earthquake":
        return (
            hazard_count,
            -high_building_clearance,
            -tree_clearance,
            -building_clearance,
            float(index),
        )
    if disaster_type == "flood":
        return (hazard_count, -relative_elevation, float(index))
    return (hazard_count, -building_clearance, -tree_clearance, float(index))


def _rationale(
    disaster_type: str,
    hazard_count: int,
    building_clearance: float,
    high_building_clearance: float,
    tree_clearance: float,
    relative_elevation: float,
) -> list[str]:
    reasons = []
    if disaster_type == "earthquake":
        reasons.extend(
            [
                f"At least {round(building_clearance)} m from mapped building records",
                f"At least {round(high_building_clearance)} m from mapped high "
                "buildings",
                f"At least {round(tree_clearance)} m from mapped trees",
            ]
        )
    elif disaster_type == "flood":
        reasons.append(
            f"About {round(relative_elevation, 1)} m higher than the current location"
        )
    if hazard_count == 0:
        reasons.append("No current mapped hazard polygon intersects this point")
    return reasons


def _candidate_name(disaster_type: str, index: int) -> str:
    label = {
        "earthquake": "Suggested open area",
        "flood": "Suggested higher-ground area",
    }.get(disaster_type, "Suggested lower-exposure area")
    return f"{label} {index}"


def _coverage_notice(disaster_type: str) -> str:
    if disaster_type == "earthquake":
        return (
            "Building clearance uses mapped OpenStreetMap building records and "
            "tree clearance uses mapped trees; building footprints and unmapped "
            "obstacles may be missing."
        )
    if disaster_type == "flood":
        return (
            "Elevation is terrain elevation, not a flood forecast. Buildings "
            "are not treated as safe flood shelters without verified access."
        )
    if disaster_type in {"fire", "cyclone", "landslide", "severe_weather"}:
        return (
            "This result uses only current snapshot hazard geometry. It does not "
            "assess fire spread, wind, slope stability, structures, roads, or "
            "shelter availability."
        )
    return "Mapped hazards and environment data may be incomplete or stale."


def _empty_response(source: str, notice: str) -> ContextAreaListResponse:
    now = datetime.now(UTC)
    return ContextAreaListResponse(
        items=[],
        data_at=now,
        source=source,
        simulation=False,
        uncertainty_notice=notice,
    )


def _way_points(value: Any, center: Any = None) -> tuple[tuple[float, float], ...]:
    if not isinstance(value, list):
        if isinstance(center, dict) and _valid_coordinate(
            center.get("lat"), center.get("lon")
        ):
            return ((float(center["lon"]), float(center["lat"])),)
        return ()
    points = []
    for point in value:
        if not isinstance(point, dict) or not _valid_coordinate(
            point.get("lat"), point.get("lon")
        ):
            return ()
        points.append((float(point["lon"]), float(point["lat"])))
    return tuple(points)


def _building_height_m(tags: dict[str, Any]) -> float | None:
    height = _number(tags.get("height"))
    if height is not None:
        return height
    levels = _number(tags.get("building:levels"))
    if levels is not None:
        return levels * 3.0
    if tags.get("building") in {"tower", "apartments", "highrise"}:
        return HIGH_BUILDING_HEIGHT_M
    return None


def _number(value: Any) -> float | None:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return float(value)
    if not isinstance(value, str):
        return None
    match = search(r"[-+]?\d+(?:\.\d+)?", value)
    return float(match.group()) if match else None


def _valid_coordinate(latitude: Any, longitude: Any) -> bool:
    return (
        isinstance(latitude, (int, float))
        and not isinstance(latitude, bool)
        and -90 <= latitude <= 90
        and isinstance(longitude, (int, float))
        and not isinstance(longitude, bool)
        and -180 <= longitude <= 180
    )


def _feature_center(points: Sequence[tuple[float, float]]) -> tuple[float, float]:
    return (
        sum(point[0] for point in points) / len(points),
        sum(point[1] for point in points) / len(points),
    )


def _density(
    coordinate: tuple[float, float],
    points: Sequence[tuple[float, float]] | Any,
    divisor: int,
) -> float:
    nearby = sum(1 for point in points if _distance_pair_m(coordinate, point) <= 100)
    return min(1.0, nearby / divisor)


def _nearest_distance(
    coordinate: tuple[float, float],
    points: Sequence[tuple[float, float]] | Any,
    fallback: float,
) -> float:
    distances = (_distance_pair_m(coordinate, point) for point in points)
    return min(distances, default=fallback)


def _distance_m(first: Coordinate, second: Coordinate) -> float:
    return _distance_pair_m(
        (first.longitude, first.latitude), (second.longitude, second.latitude)
    )


def _distance_pair_m(first: tuple[float, float], second: tuple[float, float]) -> float:
    latitude_delta = radians(second[1] - first[1])
    longitude_delta = radians(second[0] - first[0])
    first_latitude = radians(first[1])
    second_latitude = radians(second[1])
    value = sin(latitude_delta / 2) ** 2 + (
        cos(first_latitude) * cos(second_latitude) * sin(longitude_delta / 2) ** 2
    )
    return 2 * 6_371_000 * asin(sqrt(value))


def _context_area_id(coordinate: Coordinate, disaster_type: str) -> str:
    return (
        f"context-area-{disaster_type}-"
        f"{round(coordinate.latitude * 100000)}-"
        f"{round(coordinate.longitude * 100000)}"
    )


def _point_in_polygon(
    point: tuple[float, float], polygon: Sequence[tuple[float, float]]
) -> bool:
    inside = False
    previous_x, previous_y = polygon[-1]
    for current_x, current_y in polygon:
        if (current_y > point[1]) != (previous_y > point[1]):
            crossing_x = (previous_x - current_x) * (point[1] - current_y) / (
                previous_y - current_y
            ) + current_x
            if point[0] < crossing_x:
                inside = not inside
        previous_x, previous_y = current_x, current_y
    return inside
