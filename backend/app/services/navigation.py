from collections.abc import Callable, Sequence
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
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
    SosRouteRequest,
)
from app.services.environment_provider import ContextAnalysisUnavailable
from app.services.real_context_analysis import RealContextAnalyzer
from app.services.real_navigation_data import (
    DEFAULT_SNAPSHOT_MAX_AGE_SECONDS,
    YangonNavigationData,
)

SIMULATION_DATA_AT = datetime(2026, 7, 23, tzinfo=UTC)


@dataclass(frozen=True)
class SimulationRegion:
    name: str
    min_latitude: float
    max_latitude: float
    min_longitude: float
    max_longitude: float

    def contains(self, coordinate: Coordinate) -> bool:
        return (
            self.min_latitude <= coordinate.latitude <= self.max_latitude
            and self.min_longitude <= coordinate.longitude <= self.max_longitude
        )


@dataclass(frozen=True, slots=True)
class _ResolvedDestination:
    coordinate: Coordinate
    source: str
    uncertainty_notice: str


MANDALAY_REGION = SimulationRegion(
    name="Mandalay",
    min_latitude=21.93,
    max_latitude=21.99,
    min_longitude=96.06,
    max_longitude=96.12,
)
YANGON_REGION = SimulationRegion(
    name="Yangon",
    min_latitude=16.80,
    max_latitude=16.92,
    min_longitude=96.08,
    max_longitude=96.20,
)
SIMULATION_REGIONS = (MANDALAY_REGION, YANGON_REGION)

# Retained as named Mandalay bounds for existing callers and tests.
SIMULATION_MIN_LATITUDE = MANDALAY_REGION.min_latitude
SIMULATION_MAX_LATITUDE = MANDALAY_REGION.max_latitude
SIMULATION_MIN_LONGITUDE = MANDALAY_REGION.min_longitude
SIMULATION_MAX_LONGITUDE = MANDALAY_REGION.max_longitude
UNCERTAINTY_NOTICE = (
    "SIMULATION information is fictional and incomplete. Conditions may differ; "
    "follow authorized local instructions when available. Coverage is limited to "
    "the fictional Mandalay region (latitude 21.9300 through 21.9900 and "
    "longitude 96.0600 through 96.1200) and fictional Yangon region (latitude "
    "16.8000 through 16.9200 and longitude 96.0800 through 96.2000)."
)
SOS_ROUTE_UNCERTAINTY_NOTICE = (
    "This route targets a peer-reported SOS coordinate. Sender identity, "
    "coordinate accuracy, road access, current conditions, and rescue response "
    "are not confirmed."
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
    Shelter(
        id="simulation-yangon-shelter-1",
        name="SIMULATION: Yangon Riverfront Community Hall",
        coordinate=Coordinate(latitude=16.838, longitude=96.132),
        description="Fictional Yangon shelter for SafeMyanmar demonstration only.",
        data_at=SIMULATION_DATA_AT,
    ),
    Shelter(
        id="simulation-yangon-shelter-2",
        name="SIMULATION: Hlaing Learning Centre Shelter",
        coordinate=Coordinate(latitude=16.866, longitude=96.116),
        description="Fictional Yangon shelter for SafeMyanmar demonstration only.",
        data_at=SIMULATION_DATA_AT,
    ),
    Shelter(
        id="simulation-yangon-shelter-3",
        name="SIMULATION: Tamwe Open Grounds Shelter",
        coordinate=Coordinate(latitude=16.816, longitude=96.174),
        description="Fictional Yangon shelter for SafeMyanmar demonstration only.",
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
    Hazard(
        id="simulation-yangon-hazard-earthquake-1",
        name="SIMULATION: Yangon earthquake debris exercise zone",
        disaster_type="earthquake",
        geometry=_polygon(
            (96.124, 16.846),
            (96.132, 16.846),
            (96.132, 16.853),
            (96.124, 16.853),
            (96.124, 16.846),
        ),
        data_at=SIMULATION_DATA_AT,
    ),
    Hazard(
        id="simulation-yangon-hazard-flood-1",
        name="SIMULATION: Yangon flood exercise zone",
        disaster_type="flood",
        geometry=_polygon(
            (96.145, 16.858),
            (96.158, 16.858),
            (96.158, 16.870),
            (96.145, 16.870),
            (96.145, 16.858),
        ),
        data_at=SIMULATION_DATA_AT,
    ),
    Hazard(
        id="simulation-yangon-hazard-fire-1",
        name="SIMULATION: Yangon fire exercise zone",
        disaster_type="fire",
        geometry=_polygon(
            (96.106, 16.812),
            (96.116, 16.812),
            (96.116, 16.822),
            (96.106, 16.822),
            (96.106, 16.812),
        ),
        data_at=SIMULATION_DATA_AT,
    ),
    Hazard(
        id="simulation-yangon-hazard-cyclone-1",
        name="SIMULATION: Yangon cyclone debris exercise zone",
        disaster_type="cyclone",
        geometry=_polygon(
            (96.166, 16.878),
            (96.178, 16.878),
            (96.178, 16.889),
            (96.166, 16.889),
            (96.166, 16.878),
        ),
        data_at=SIMULATION_DATA_AT,
    ),
    Hazard(
        id="simulation-yangon-hazard-landslide-1",
        name="SIMULATION: Yangon landslide exercise zone",
        disaster_type="landslide",
        geometry=_polygon(
            (96.096, 16.892),
            (96.108, 16.892),
            (96.108, 16.904),
            (96.096, 16.904),
            (96.096, 16.892),
        ),
        data_at=SIMULATION_DATA_AT,
    ),
    Hazard(
        id="simulation-yangon-hazard-weather-1",
        name="SIMULATION: Yangon severe weather exercise zone",
        disaster_type="severe_weather",
        geometry=_polygon(
            (96.114, 16.831),
            (96.127, 16.831),
            (96.127, 16.842),
            (96.114, 16.842),
            (96.114, 16.831),
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
        real_data: YangonNavigationData | None = None,
        context_analyzer: RealContextAnalyzer | None = None,
        simulation_analysis_enabled: bool = False,
    ) -> None:
        self._simulation_enabled = simulation_enabled
        self._directions = directions_provider
        self._clock = clock or (lambda: datetime.now(UTC))
        self._real_data = real_data
        self._context_analyzer = context_analyzer
        self._simulation_analysis_enabled = simulation_analysis_enabled

    def list_shelters(self) -> ShelterListResponse:
        if self._real_data is not None:
            return self._real_data.shelter_response()
        self._require_simulation()
        return ShelterListResponse(
            items=list(SHELTERS),
            data_at=SIMULATION_DATA_AT,
            uncertainty_notice=UNCERTAINTY_NOTICE,
        )

    def list_hazards(self) -> HazardListResponse:
        if self._real_data is not None:
            return self._real_data.hazard_response()
        self._require_simulation()
        return HazardListResponse(
            items=list(HAZARDS),
            data_at=SIMULATION_DATA_AT,
            uncertainty_notice=UNCERTAINTY_NOTICE,
        )

    def find_context_areas(
        self, request: ContextAreaRequest
    ) -> ContextAreaListResponse:
        if self._real_data is not None:
            if self._context_analyzer is not None:
                hazards = self._real_data.hazards
                source = self._real_data.source
                uncertainty_notice = self._real_data.uncertainty_notice
                simulation_data_included = False
                if self._simulation_analysis_enabled:
                    hazards = (*hazards, *HAZARDS)
                    source += "; SafeMyanmar Demo simulation analysis data"
                    uncertainty_notice += (
                        " Simulation hazard geometry is included for backend analysis "
                        "only and is not returned by the hazard list. The collected "
                        "and fictional sources are intentionally labeled separately."
                    )
                    simulation_data_included = True
                return self._context_analyzer.find_context_areas(
                    request,
                    hazards,
                    source=source,
                    uncertainty_notice=uncertainty_notice,
                    simulation_data_included=simulation_data_included,
                    source_data_at=self._real_data.retrieved_at,
                )
            return ContextAreaListResponse(
                items=[],
                data_at=self._real_data.retrieved_at,
                source=self._real_data.source,
                simulation=False,
                uncertainty_notice=self._real_data.uncertainty_notice,
            )
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
        if self._real_data is not None:
            return self._suggest_real_routes(request)
        self._require_simulation()
        origin_region = _simulation_region_for_coordinate(request.origin)
        if origin_region is None:
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

        routes = tuple(
            route for route in routes if _route_in_simulation_area(route, origin_region)
        )
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

    def suggest_sos_routes(self, request: SosRouteRequest) -> RouteSuggestionsResponse:
        if self._real_data is not None:
            return self._suggest_real_sos_routes(request)
        self._require_simulation()
        origin_region = _simulation_region_for_coordinate(request.origin)
        destination_region = _simulation_region_for_coordinate(request.destination)
        if origin_region is None or destination_region != origin_region:
            raise OutsideSimulationArea
        try:
            routes = self._directions.get_routes(
                request.origin,
                request.destination,
                request.profile
                or self._select_profile(
                    request.origin, request.destination, request.profile
                )[0],
            )
        except DirectionsProviderError:
            raise RoutingUnavailable from None
        routes = tuple(
            route for route in routes if _route_in_simulation_area(route, origin_region)
        )
        if not routes:
            raise RoutingUnavailable
        generated_at = _utc_datetime_or_none(self._clock())
        if generated_at is None:
            raise RoutingUnavailable
        return self._build_sos_route_response(
            request.origin,
            request.destination,
            request.profile,
            routes,
            HAZARDS,
            generated_at,
            SOS_ROUTE_UNCERTAINTY_NOTICE,
            simulation=True,
        )

    def _suggest_real_sos_routes(
        self, request: SosRouteRequest
    ) -> RouteSuggestionsResponse:
        real_data = self._real_data
        if real_data is None:
            raise RoutingUnavailable
        now = _utc_datetime_or_none(self._clock())
        retrieved_at = _utc_datetime_or_none(real_data.retrieved_at)
        if (
            now is None
            or retrieved_at is None
            or now - retrieved_at > timedelta(seconds=DEFAULT_SNAPSHOT_MAX_AGE_SECONDS)
            or _has_stale_metadata(real_data.uncertainty_notice)
        ):
            raise RoutingUnavailable
        try:
            routes = tuple(
                self._directions.get_routes(
                    request.origin,
                    request.destination,
                    request.profile
                    or self._select_profile(
                        request.origin, request.destination, request.profile
                    )[0],
                )
            )
        except (DirectionsProviderError, TypeError):
            raise RoutingUnavailable from None
        if not routes:
            raise RoutingUnavailable
        generated_at = _utc_datetime_or_none(self._clock())
        if generated_at is None:
            raise RoutingUnavailable
        return self._build_sos_route_response(
            request.origin,
            request.destination,
            request.profile,
            routes,
            real_data.hazards,
            generated_at,
            _append_notice(real_data.uncertainty_notice, SOS_ROUTE_UNCERTAINTY_NOTICE),
            simulation=False,
            hazard_data_at=retrieved_at,
            source="Peer-reported SOS coordinate",
        )

    def _build_sos_route_response(
        self,
        origin: Coordinate,
        destination: Coordinate,
        requested_profile: RouteProfile | None,
        routes: Sequence[DirectionsRoute],
        hazards: Sequence[Hazard],
        generated_at: datetime,
        uncertainty_notice: str,
        *,
        simulation: bool,
        hazard_data_at: datetime = SIMULATION_DATA_AT,
        source: str = "SafeMyanmar Demo",
    ) -> RouteSuggestionsResponse:
        profile, reason = self._select_profile(origin, destination, requested_profile)
        ranked = sorted(
            routes,
            key=lambda route: (
                _intersection_count(route, hazards),
                route.duration_seconds,
                route.distance_m,
            ),
        )[:3]
        options = [
            RouteOption(
                id=f"sos-route-{index}",
                generated_at=generated_at,
                hazard_data_at=hazard_data_at,
                profile=profile,
                source=source,
                simulation=simulation,
                geometry=route.geometry,
                distance_m=route.distance_m,
                duration_seconds=route.duration_seconds,
                hazard_intersection_count=_intersection_count(route, hazards),
                rationale=(
                    "Route to the peer-reported SOS coordinate ranked by currently "
                    "mapped hazard intersections, then duration and distance; "
                    "conditions may differ."
                ),
                recommended=index == 1,
                uncertainty_notice=uncertainty_notice,
            )
            for index, route in enumerate(ranked, start=1)
        ]
        return RouteSuggestionsResponse(
            options=options,
            generated_at=generated_at,
            hazard_data_at=hazard_data_at,
            profile=profile,
            profile_selection_reason=reason,
            source=source,
            directions_provider="Mapbox Directions",
            simulation=simulation,
            uncertainty_notice=uncertainty_notice,
        )

    def _suggest_real_routes(
        self, request: RouteSuggestionRequest
    ) -> RouteSuggestionsResponse:
        real_data = self._real_data
        if real_data is None:
            raise RoutingUnavailable

        now = _utc_datetime_or_none(self._clock())
        retrieved_at = _utc_datetime_or_none(real_data.retrieved_at)
        if (
            now is None
            or retrieved_at is None
            or now - retrieved_at > timedelta(seconds=DEFAULT_SNAPSHOT_MAX_AGE_SECONDS)
            or _has_stale_metadata(real_data.uncertainty_notice)
        ):
            raise RoutingUnavailable

        destination = self._resolve_real_destination(request)
        profile, reason = self._select_profile(
            request.origin, destination.coordinate, request.profile
        )
        try:
            routes = tuple(
                self._directions.get_routes(
                    request.origin, destination.coordinate, profile
                )
            )
        except (DirectionsProviderError, TypeError):
            raise RoutingUnavailable from None

        if not routes:
            raise RoutingUnavailable

        generated_at = _utc_datetime_or_none(self._clock())
        if generated_at is None:
            raise RoutingUnavailable
        relevant_hazards = tuple(
            hazard
            for hazard in real_data.hazards
            if hazard.disaster_type == request.disaster_type
        )
        ranked = sorted(
            enumerate(routes),
            key=lambda indexed_route: (
                _intersection_count(indexed_route[1], relevant_hazards),
                indexed_route[1].duration_seconds,
                indexed_route[1].distance_m,
                indexed_route[0],
            ),
        )[:3]
        uncertainty_notice = _append_notice(
            destination.uncertainty_notice,
            "Route geometry and travel times come from Mapbox Directions. "
            "Mapped hazards, roads, access, weather, and destination conditions "
            "may differ; this suggestion does not confirm destination or route "
            "safety.",
        )
        options = [
            RouteOption(
                id=f"real-route-{index}",
                generated_at=generated_at,
                hazard_data_at=retrieved_at,
                profile=profile,
                source=destination.source,
                simulation=False,
                geometry=route.geometry,
                distance_m=route.distance_m,
                duration_seconds=route.duration_seconds,
                hazard_intersection_count=_intersection_count(route, relevant_hazards),
                rationale=(
                    "Suggested route ranked by current mapped hazard "
                    "intersections, then duration and distance; route conditions "
                    "may differ."
                    if index == 1
                    else "Alternative route ranked by current mapped hazard "
                    "intersections, then duration and distance; route conditions "
                    "may differ."
                ),
                recommended=index == 1,
                uncertainty_notice=uncertainty_notice,
            )
            for index, (_, route) in enumerate(ranked, start=1)
        ]
        return RouteSuggestionsResponse(
            options=options,
            generated_at=generated_at,
            hazard_data_at=retrieved_at,
            profile=profile,
            profile_selection_reason=reason,
            source=destination.source,
            simulation=False,
            uncertainty_notice=uncertainty_notice,
        )

    def _resolve_real_destination(
        self, request: RouteSuggestionRequest
    ) -> _ResolvedDestination:
        real_data = self._real_data
        if real_data is None:
            raise RoutingUnavailable

        if request.context_area_id is not None:
            if self._context_analyzer is None:
                raise RoutingUnavailable
            try:
                context_response = self.find_context_areas(
                    ContextAreaRequest(
                        origin=request.origin,
                        disaster_type=request.disaster_type,
                        scenario=request.scenario,
                        search_radius_m=request.search_radius_m,
                    )
                )
            except ContextAnalysisUnavailable:
                raise RoutingUnavailable from None
            context = next(
                (
                    item
                    for item in context_response.items
                    if item.id == request.context_area_id
                ),
                None,
            )
            if (
                context is None
                or context_response.simulation
                or context.simulation
                or context.disaster_type != request.disaster_type
                or context.scenario != request.scenario
                or not context.source.strip()
                or not context_response.source.strip()
                or _has_simulation_metadata(context.source)
                or _has_simulation_metadata(context_response.source)
                or _has_stale_metadata(
                    context.uncertainty_notice,
                    context_response.uncertainty_notice,
                )
                or _utc_datetime_or_none(context.data_at) is None
                or _utc_datetime_or_none(context_response.data_at) is None
                or _utc_datetime_or_none(context.data_at)
                != _utc_datetime_or_none(context_response.data_at)
            ):
                raise ShelterNotFound
            return _ResolvedDestination(
                coordinate=context.coordinate,
                source=context.source,
                uncertainty_notice=_append_notice(
                    context_response.uncertainty_notice,
                    context.uncertainty_notice,
                ),
            )

        shelter = next(
            (item for item in real_data.shelters if item.id == request.shelter_id),
            None,
        )
        if (
            shelter is None
            or shelter.simulation
            or not shelter.source.strip()
            or _has_simulation_metadata(shelter.source)
            or _utc_datetime_or_none(shelter.data_at)
            != _utc_datetime_or_none(real_data.retrieved_at)
        ):
            raise ShelterNotFound
        return _ResolvedDestination(
            coordinate=shelter.coordinate,
            source=shelter.source,
            uncertainty_notice=_append_notice(
                real_data.uncertainty_notice,
                "The selected snapshot-listed shelter has not been independently "
                "verified for current access or conditions.",
            ),
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


def _utc_datetime_or_none(value: datetime) -> datetime | None:
    if not isinstance(value, datetime):
        return None
    if value.tzinfo is None or value.utcoffset() is None:
        return None
    return value.astimezone(UTC)


def _has_simulation_metadata(*values: str) -> bool:
    return any(
        value == "SafeMyanmar Demo" or "simulation" in value.casefold()
        for value in values
    )


def _has_stale_metadata(*values: str) -> bool:
    return any("stale" in value.casefold() for value in values)


def _append_notice(existing: str, addition: str) -> str:
    return f"{existing.strip()} {addition.strip()}".strip()


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
    return _simulation_region_for_coordinate(coordinate) is not None


def _simulation_region_for_coordinate(
    coordinate: Coordinate,
) -> SimulationRegion | None:
    return next(
        (region for region in SIMULATION_REGIONS if region.contains(coordinate)),
        None,
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


def _route_in_simulation_area(
    route: DirectionsRoute,
    region: SimulationRegion,
) -> bool:
    return all(
        region.min_longitude <= longitude <= region.max_longitude
        and region.min_latitude <= latitude <= region.max_latitude
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
