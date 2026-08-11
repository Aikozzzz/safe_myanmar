from collections.abc import Callable, Sequence
from datetime import UTC, datetime
from math import asin, cos, radians, sin, sqrt

from app.providers.mapbox.directions import (
    DirectionsProviderError,
    DirectionsRoute,
    MapboxDirectionsProvider,
)
from app.schemas.navigation import (
    ContextArea,
    ContextAreaListResponse,
    ContextAreaRequest,
    ContextMetrics,
    Coordinate,
    Hazard,
    HazardListResponse,
    PolygonGeometry,
    RouteOption,
    RouteProfile,
    RouteSuggestionRequest,
    RouteSuggestionsResponse,
    Shelter,
    ShelterListResponse,
)

SIMULATION_DATA_AT = datetime(2026, 7, 23, tzinfo=UTC)
SIMULATION_MIN_LATITUDE = 21.93
SIMULATION_MAX_LATITUDE = 21.99
SIMULATION_MIN_LONGITUDE = 96.06
SIMULATION_MAX_LONGITUDE = 96.12
UNCERTAINTY_NOTICE = (
    "SIMULATION information is fictional and incomplete. Conditions may differ; "
    "follow authorized local instructions when available. Coverage is limited to "
    "latitude 21.9300 through 21.9900 and longitude 96.0600 through 96.1200."
)

SHELTERS = (
    Shelter(
        id="simulation-shelter-1",
        name="SIMULATION: Thazin Community Shelter",
        coordinate=Coordinate(latitude=21.958, longitude=96.091),
        description="Fictional shelter for SafeMyanmar demonstration only.",
        data_at=SIMULATION_DATA_AT,
    ),
    Shelter(
        id="simulation-shelter-2",
        name="SIMULATION: Padauk Learning Hall Shelter",
        coordinate=Coordinate(latitude=21.975, longitude=96.105),
        description="Fictional shelter for SafeMyanmar demonstration only.",
        data_at=SIMULATION_DATA_AT,
    ),
    Shelter(
        id="simulation-shelter-3",
        name="SIMULATION: Irrawaddy Training Centre Shelter",
        coordinate=Coordinate(latitude=21.942, longitude=96.078),
        description="Fictional shelter for SafeMyanmar demonstration only.",
        data_at=SIMULATION_DATA_AT,
    ),
)


def _polygon(*coordinates: tuple[float, float]) -> PolygonGeometry:
    return PolygonGeometry(coordinates=[list(coordinates)])


HAZARDS = (
    Hazard(
        id="simulation-hazard-earthquake-1",
        name="SIMULATION: Earthquake debris exercise zone",
        disaster_type="earthquake",
        geometry=_polygon(
            (96.084, 21.952),
            (96.088, 21.952),
            (96.088, 21.956),
            (96.084, 21.956),
            (96.084, 21.952),
        ),
        data_at=SIMULATION_DATA_AT,
    ),
    Hazard(
        id="simulation-hazard-flood-1",
        name="SIMULATION: Flood exercise zone",
        disaster_type="flood",
        geometry=_polygon(
            (96.098, 21.963),
            (96.108, 21.963),
            (96.108, 21.972),
            (96.098, 21.972),
            (96.098, 21.963),
        ),
        data_at=SIMULATION_DATA_AT,
    ),
    Hazard(
        id="simulation-hazard-fire-1",
        name="SIMULATION: Fire exercise zone",
        disaster_type="fire",
        geometry=_polygon(
            (96.076, 21.943),
            (96.085, 21.943),
            (96.085, 21.951),
            (96.076, 21.951),
            (96.076, 21.943),
        ),
        data_at=SIMULATION_DATA_AT,
    ),
    Hazard(
        id="simulation-hazard-cyclone-1",
        name="SIMULATION: Cyclone debris exercise zone",
        disaster_type="cyclone",
        geometry=_polygon(
            (96.096, 21.947),
            (96.105, 21.947),
            (96.105, 21.956),
            (96.096, 21.956),
            (96.096, 21.947),
        ),
        data_at=SIMULATION_DATA_AT,
    ),
    Hazard(
        id="simulation-hazard-landslide-1",
        name="SIMULATION: Landslide exercise zone",
        disaster_type="landslide",
        geometry=_polygon(
            (96.081, 21.965),
            (96.091, 21.965),
            (96.091, 21.974),
            (96.081, 21.974),
            (96.081, 21.965),
        ),
        data_at=SIMULATION_DATA_AT,
    ),
    Hazard(
        id="simulation-hazard-weather-1",
        name="SIMULATION: Severe weather exercise zone",
        disaster_type="severe_weather",
        geometry=_polygon(
            (96.088, 21.969),
            (96.098, 21.969),
            (96.098, 21.978),
            (96.088, 21.978),
            (96.088, 21.969),
        ),
        data_at=SIMULATION_DATA_AT,
    ),
)


class SimulationDataDisabled(Exception):
    pass


class ShelterNotFound(Exception):
    pass


class RoutingUnavailable(Exception):
    pass


class OutsideSimulationArea(Exception):
    pass


class NavigationService:
    def __init__(
        self,
        simulation_enabled: bool,
        directions_provider: MapboxDirectionsProvider,
        clock: Callable[[], datetime] | None = None,
    ) -> None:
        self._simulation_enabled = simulation_enabled
        self._directions = directions_provider
        self._clock = clock or (lambda: datetime.now(UTC))

    def list_shelters(self) -> ShelterListResponse:
        self._require_simulation()
        return ShelterListResponse(
            items=list(SHELTERS),
            data_at=SIMULATION_DATA_AT,
            uncertainty_notice=UNCERTAINTY_NOTICE,
        )

    def list_hazards(self) -> HazardListResponse:
        self._require_simulation()
        return HazardListResponse(
            items=list(HAZARDS),
            data_at=SIMULATION_DATA_AT,
            uncertainty_notice=UNCERTAINTY_NOTICE,
        )

    def find_context_areas(
        self, request: ContextAreaRequest
    ) -> ContextAreaListResponse:
        self._require_simulation()
        if not _coordinate_in_simulation_area(request.origin):
            raise OutsideSimulationArea
        if (
            request.disaster_type == "earthquake"
            and request.scenario != "outdoors_after_shaking"
        ):
            return ContextAreaListResponse(
                items=[],
                data_at=SIMULATION_DATA_AT,
                uncertainty_notice=(
                    "For an earthquake during active shaking, use Drop, Cover, "
                    "and Hold On. "
                    "Outdoor area analysis is available only after shaking stops."
                ),
            )

        relevant_hazards = tuple(
            hazard
            for hazard in HAZARDS
            if hazard.disaster_type == request.disaster_type
        )
        candidates = []
        for index, (latitude_delta, longitude_delta, distance_m) in enumerate(
            _candidate_offsets(request.search_radius_m)
        ):
            coordinate = Coordinate(
                latitude=request.origin.latitude + latitude_delta,
                longitude=request.origin.longitude + longitude_delta,
            )
            if not _coordinate_in_simulation_area(coordinate):
                continue
            hazard_count = sum(
                _point_in_polygon(
                    (coordinate.longitude, coordinate.latitude),
                    hazard.geometry.coordinates[0],
                )
                for hazard in relevant_hazards
            )
            if hazard_count:
                continue
            building_density = _building_density(coordinate)
            tree_density = _tree_density(coordinate)
            relative_elevation = _relative_elevation(coordinate, request.origin)
            building_clearance = round(30 + (1 - building_density) * 120, 1)
            tree_clearance = round(20 + (1 - tree_density) * 100, 1)
            if request.disaster_type == "earthquake":
                ranking = (
                    building_density,
                    tree_density,
                    -building_clearance,
                    -tree_clearance,
                    distance_m,
                )
                rationale = [
                    "Lower simulated building density",
                    "Greater simulated tree clearance",
                    "Outside currently available simulated earthquake hazards",
                ]
            elif request.disaster_type == "flood":
                ranking = (
                    -relative_elevation,
                    distance_m,
                    hazard_count,
                )
                rationale = [
                    "Higher simulated elevation than the requested origin",
                    "Outside currently available simulated flood hazards",
                    "Route conditions may differ from this simulation",
                ]
            else:
                ranking = (hazard_count, distance_m, building_density, tree_density)
                rationale = [
                    "Outside currently available simulated hazards",
                    "Candidate has lower simulated surrounding exposure",
                ]
            candidates.append(
                (
                    ranking,
                    ContextArea(
                        id=_context_area_id(coordinate, request.disaster_type),
                        name=f"SIMULATION: Lower-exposure area {index + 1}",
                        coordinate=coordinate,
                        disaster_type=request.disaster_type,
                        scenario=request.scenario,
                        distance_m=round(distance_m, 1),
                        metrics=ContextMetrics(
                            building_clearance_m=building_clearance,
                            tree_clearance_m=tree_clearance,
                            relative_elevation_m=round(relative_elevation, 1),
                            building_density=round(building_density, 3),
                            tree_density=round(tree_density, 3),
                            hazard_intersections=hazard_count,
                        ),
                        rationale=rationale,
                        data_at=SIMULATION_DATA_AT,
                        uncertainty_notice=UNCERTAINTY_NOTICE,
                    ),
                )
            )
        ranked = [item for _, item in sorted(candidates, key=lambda value: value[0])]
        return ContextAreaListResponse(
            items=ranked[:3],
            data_at=SIMULATION_DATA_AT,
            uncertainty_notice=UNCERTAINTY_NOTICE,
        )

    def suggest_routes(
        self, request: RouteSuggestionRequest
    ) -> RouteSuggestionsResponse:
        self._require_simulation()
        if not _coordinate_in_simulation_area(request.origin):
            raise OutsideSimulationArea
        destination = next(
            (item.coordinate for item in SHELTERS if item.id == request.shelter_id),
            None,
        )
        if request.context_area_id is not None:
            context_response = self.find_context_areas(
                ContextAreaRequest(
                    origin=request.origin,
                    disaster_type=request.disaster_type,
                    scenario=request.scenario,
                    search_radius_m=request.search_radius_m,
                )
            )
            context = next(
                (
                    item
                    for item in context_response.items
                    if item.id == request.context_area_id
                ),
                None,
            )
            if context is None:
                raise ShelterNotFound
            destination = context.coordinate
        if destination is None:
            raise ShelterNotFound

        profile, reason = self._select_profile(
            request.origin, destination, request.profile
        )
        try:
            routes = self._directions.get_routes(request.origin, destination, profile)
        except DirectionsProviderError:
            raise RoutingUnavailable from None

        routes = tuple(route for route in routes if _route_in_simulation_area(route))
        if not routes:
            raise RoutingUnavailable

        generated_at = self._clock()
        if generated_at.tzinfo is None or generated_at.utcoffset() is None:
            raise ValueError("clock must return a timezone-aware datetime")
        generated_at = generated_at.astimezone(UTC)
        relevant_hazards = tuple(
            hazard
            for hazard in HAZARDS
            if hazard.disaster_type == request.disaster_type
        )
        ranked = sorted(
            routes,
            key=lambda route: (
                _intersection_count(route, relevant_hazards),
                route.duration_seconds,
                route.distance_m,
            ),
        )
        options = [
            RouteOption(
                id=f"simulation-route-{index}",
                generated_at=generated_at,
                hazard_data_at=SIMULATION_DATA_AT,
                profile=profile,
                geometry=route.geometry,
                distance_m=route.distance_m,
                duration_seconds=route.duration_seconds,
                hazard_intersection_count=_intersection_count(route, relevant_hazards),
                rationale=(
                    "Suggested safer route based on currently available "
                    "SIMULATION information."
                    if index == 1
                    else "Alternative route based on currently available "
                    "SIMULATION information; it may intersect more hazards or "
                    "take longer."
                ),
                recommended=index == 1,
                uncertainty_notice=UNCERTAINTY_NOTICE,
            )
            for index, route in enumerate(ranked, start=1)
        ]
        return RouteSuggestionsResponse(
            options=options,
            generated_at=generated_at,
            hazard_data_at=SIMULATION_DATA_AT,
            profile=profile,
            profile_selection_reason=reason,
            uncertainty_notice=UNCERTAINTY_NOTICE,
        )

    def _require_simulation(self) -> None:
        if not self._simulation_enabled:
            raise SimulationDataDisabled

    @staticmethod
    def _select_profile(
        origin: Coordinate,
        destination: Coordinate,
        override: RouteProfile | None,
    ) -> tuple[RouteProfile, str]:
        if override is not None:
            return override, f"The user requested the {override} profile."
        distance_m = _straight_line_distance_m(origin, destination)
        if distance_m <= 5000:
            return (
                "walking",
                "Walking was selected because the straight-line distance is "
                "5 km or less; send profile to override this deterministic rule.",
            )
        return (
            "driving",
            "Driving was selected because the straight-line distance is over "
            "5 km; send profile to override this deterministic rule.",
        )


def _straight_line_distance_m(origin: Coordinate, destination: Coordinate) -> float:
    latitude_delta = radians(destination.latitude - origin.latitude)
    longitude_delta = radians(destination.longitude - origin.longitude)
    origin_latitude = radians(origin.latitude)
    destination_latitude = radians(destination.latitude)
    value = sin(latitude_delta / 2) ** 2 + (
        cos(origin_latitude) * cos(destination_latitude) * sin(longitude_delta / 2) ** 2
    )
    return 2 * 6_371_000 * asin(sqrt(value))


def _coordinate_in_simulation_area(coordinate: Coordinate) -> bool:
    return (
        SIMULATION_MIN_LATITUDE <= coordinate.latitude <= SIMULATION_MAX_LATITUDE
        and SIMULATION_MIN_LONGITUDE <= coordinate.longitude <= SIMULATION_MAX_LONGITUDE
    )


def _candidate_offsets(
    search_radius_m: float,
) -> tuple[tuple[float, float, float], ...]:
    latitude_degrees = search_radius_m / 111_000
    longitude_degrees = search_radius_m / 104_000
    return (
        (latitude_degrees * 0.55, 0.0, search_radius_m * 0.55),
        (-latitude_degrees * 0.55, 0.0, search_radius_m * 0.55),
        (0.0, longitude_degrees * 0.55, search_radius_m * 0.55),
        (0.0, -longitude_degrees * 0.55, search_radius_m * 0.55),
        (latitude_degrees * 0.7, longitude_degrees * 0.7, search_radius_m * 0.99),
        (-latitude_degrees * 0.7, -longitude_degrees * 0.7, search_radius_m * 0.99),
        (-latitude_degrees * 0.7, longitude_degrees * 0.7, search_radius_m * 0.99),
        (latitude_degrees * 0.7, -longitude_degrees * 0.7, search_radius_m * 0.99),
    )


def _building_density(coordinate: Coordinate) -> float:
    value = sin(coordinate.latitude * 37) * 0.5 + cos(coordinate.longitude * 29) * 0.5
    return min(1.0, max(0.0, 0.5 + value * 0.35))


def _tree_density(coordinate: Coordinate) -> float:
    value = cos(coordinate.latitude * 23) * 0.5 + sin(coordinate.longitude * 31) * 0.5
    return min(1.0, max(0.0, 0.45 + value * 0.3))


def _relative_elevation(coordinate: Coordinate, origin: Coordinate) -> float:
    return (coordinate.latitude - origin.latitude) * 100_000 + sin(
        coordinate.longitude * 17
    ) * 2


def _context_area_id(coordinate: Coordinate, disaster_type: str) -> str:
    return (
        f"context-area-{disaster_type}-"
        f"{round(coordinate.latitude * 100000)}-"
        f"{round(coordinate.longitude * 100000)}"
    )


def _route_in_simulation_area(route: DirectionsRoute) -> bool:
    return all(
        SIMULATION_MIN_LONGITUDE <= longitude <= SIMULATION_MAX_LONGITUDE
        and SIMULATION_MIN_LATITUDE <= latitude <= SIMULATION_MAX_LATITUDE
        for longitude, latitude in route.geometry.coordinates
    )


def _intersection_count(route: DirectionsRoute, hazards: Sequence[Hazard]) -> int:
    return sum(
        _line_intersects_polygon(
            route.geometry.coordinates, hazard.geometry.coordinates[0]
        )
        for hazard in hazards
    )


def _line_intersects_polygon(
    line: Sequence[tuple[float, float]], polygon: Sequence[tuple[float, float]]
) -> bool:
    if any(_point_in_polygon(point, polygon) for point in line):
        return True
    polygon_segments = zip(polygon, polygon[1:], strict=False)
    edges = tuple(polygon_segments)
    return any(
        _segments_intersect(line_start, line_end, edge_start, edge_end)
        for line_start, line_end in zip(line, line[1:], strict=False)
        for edge_start, edge_end in edges
    )


def _point_in_polygon(
    point: tuple[float, float], polygon: Sequence[tuple[float, float]]
) -> bool:
    x, y = point
    inside = False
    previous_x, previous_y = polygon[-1]
    for current_x, current_y in polygon:
        if _on_segment((previous_x, previous_y), point, (current_x, current_y)):
            return True
        if (current_y > y) != (previous_y > y):
            crossing_x = (previous_x - current_x) * (y - current_y) / (
                previous_y - current_y
            ) + current_x
            if x < crossing_x:
                inside = not inside
        previous_x, previous_y = current_x, current_y
    return inside


def _segments_intersect(
    first_start: tuple[float, float],
    first_end: tuple[float, float],
    second_start: tuple[float, float],
    second_end: tuple[float, float],
) -> bool:
    first_a = _orientation(first_start, first_end, second_start)
    first_b = _orientation(first_start, first_end, second_end)
    second_a = _orientation(second_start, second_end, first_start)
    second_b = _orientation(second_start, second_end, first_end)
    if first_a != first_b and second_a != second_b:
        return True
    return (
        (first_a == 0 and _on_segment(first_start, second_start, first_end))
        or (first_b == 0 and _on_segment(first_start, second_end, first_end))
        or (second_a == 0 and _on_segment(second_start, first_start, second_end))
        or (second_b == 0 and _on_segment(second_start, first_end, second_end))
    )


def _orientation(
    start: tuple[float, float],
    end: tuple[float, float],
    point: tuple[float, float],
) -> int:
    cross = (end[0] - start[0]) * (point[1] - start[1]) - (end[1] - start[1]) * (
        point[0] - start[0]
    )
    if abs(cross) <= 1e-12:
        return 0
    return 1 if cross > 0 else -1


def _on_segment(
    start: tuple[float, float],
    point: tuple[float, float],
    end: tuple[float, float],
) -> bool:
    return (
        _orientation(start, end, point) == 0
        and min(start[0], end[0]) - 1e-12 <= point[0] <= max(start[0], end[0]) + 1e-12
        and min(start[1], end[1]) - 1e-12 <= point[1] <= max(start[1], end[1]) + 1e-12
    )
