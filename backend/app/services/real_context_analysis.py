from collections.abc import Sequence
from dataclasses import dataclass
from datetime import UTC, datetime
from math import asin, cos, isfinite, radians, sin, sqrt
from typing import Any

from app.schemas.navigation import (
    ContextArea,
    ContextAreaListResponse,
    ContextAreaRequest,
    ContextMetrics,
    Coordinate,
    Hazard,
)
from app.services.environment_provider import (
    HIGH_BUILDING_HEIGHT_M,
    MAX_ENVIRONMENT_RADIUS_M,
    MAX_ENVIRONMENT_RESPONSE_BYTES,
    BuildingFeature,
    CachedEnvironmentProvider,
    ContextAnalysisUnavailable,
    EnvironmentProvider,
    EnvironmentSnapshot,
    GeometryFeature,
    LiveEnvironmentProvider,
    OpenSpaceFeature,
    OSMEnvironmentObservation,
    Point,
    PowerFeature,
    PowerInfrastructureFeature,
    WaterBodyFeature,
    WaterFeature,
    WoodedAreaFeature,
    build_overpass_query,
    parse_overpass_response,
)

__all__ = [
    "BuildingFeature",
    "CachedEnvironmentProvider",
    "ContextAnalysisUnavailable",
    "EnvironmentProvider",
    "EnvironmentSnapshot",
    "GeometryFeature",
    "HIGH_BUILDING_HEIGHT_M",
    "LiveEnvironmentProvider",
    "MAX_ENVIRONMENT_RADIUS_M",
    "MAX_ENVIRONMENT_RESPONSE_BYTES",
    "OpenSpaceFeature",
    "OSMEnvironmentObservation",
    "Point",
    "PowerFeature",
    "PowerInfrastructureFeature",
    "RealContextAnalyzer",
    "WaterFeature",
    "WaterBodyFeature",
    "WoodedAreaFeature",
    "build_overpass_query",
    "parse_overpass_response",
]

EARTHQUAKE_BUILDING_CLEARANCE_M = 25.0
EARTHQUAKE_HIGH_BUILDING_CLEARANCE_M = 50.0
EARTHQUAKE_TREE_CLEARANCE_M = 20.0
EARTHQUAKE_POWER_CLEARANCE_M = 25.0
EARTHQUAKE_OPEN_SPACE_EDGE_CLEARANCE_M = 5.0
FLOOD_GRID_STEPS = 5
FLOOD_LOCAL_PEAK_RADIUS_RATIO = 0.30
FLOOD_CANDIDATE_CLUSTER_RADIUS_RATIO = 0.20
FLOOD_MIN_CLUSTER_RADIUS_M = 40.0
FLOOD_ELEVATION_TIE_M = 0.05
FLOOD_WATER_CLEARANCE_M = 15.0
SUPPORTED_REAL_ANALYSIS_TYPES = frozenset({"earthquake", "flood"})


@dataclass(frozen=True)
class _EarthquakeCandidate:
    feature: OpenSpaceFeature
    polygon: tuple[Point, ...]
    coordinate: Coordinate
    area_m2: float
    open_space_edge_clearance_m: float


@dataclass(frozen=True)
class _FloodCandidate:
    coordinate: Coordinate
    relative_elevation_m: float
    distance_m: float
    mapped_accessible: bool


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
        simulation_data_included: bool = False,
        source_data_at: datetime | None = None,
    ) -> ContextAreaListResponse:
        if (
            request.disaster_type not in SUPPORTED_REAL_ANALYSIS_TYPES
            and not simulation_data_included
        ):
            raise ContextAnalysisUnavailable
        source_data_at = _source_data_timestamp(hazards, source_data_at)
        if request.disaster_type == "earthquake" and request.scenario != (
            "outdoors_after_shaking"
        ):
            return _empty_response(
                source,
                uncertainty_notice
                + " During active shaking, use Drop, Cover, and Hold On "
                "instead of moving to a suggested area.",
                simulation=simulation_data_included,
                data_at=source_data_at,
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
                simulation=simulation_data_included,
                data_at=source_data_at,
            )

        if request.disaster_type == "earthquake":
            candidates = ()
            environment_points = (request.origin,)
        elif request.disaster_type == "flood":
            candidates = _candidate_coordinates(request.origin, request.search_radius_m)
            environment_points = (request.origin, *candidates)
        else:
            candidates = _simulation_candidate_coordinates(
                request.origin, request.search_radius_m
            )
            environment_points = (request.origin, *candidates)
        if request.disaster_type in {"earthquake", "flood"}:
            if request.disaster_type == "flood":
                snapshot = self._provider.observe(
                    request.origin,
                    environment_points,
                    request.search_radius_m,
                    include_obstacles=False,
                    include_elevation=True,
                    include_water=True,
                )
            else:
                snapshot = self._provider.observe(
                    request.origin,
                    environment_points,
                    request.search_radius_m,
                    include_obstacles=True,
                    include_elevation=False,
                )
        else:
            snapshot = EnvironmentSnapshot(
                buildings=(),
                trees=(),
                elevations_m=(),
                observed_at=max(hazard.data_at for hazard in relevant_hazards),
                source="current snapshot hazard geometry",
            )
        snapshot_source = f"{source}; {snapshot.source}"
        snapshot_notice = _append_notice(
            uncertainty_notice, getattr(snapshot, "uncertainty_notice", "") or ""
        )
        if request.disaster_type == "earthquake":
            return _analyze_earthquake(
                request,
                relevant_hazards,
                snapshot,
                source=snapshot_source,
                uncertainty_notice=snapshot_notice,
                simulation_data_included=simulation_data_included,
            )
        if request.disaster_type == "flood":
            return _analyze_flood(
                request,
                relevant_hazards,
                snapshot,
                candidates,
                source=snapshot_source,
                uncertainty_notice=snapshot_notice,
                simulation_data_included=simulation_data_included,
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
            )
            high_building_clearance = _nearest_distance(
                (candidate.longitude, candidate.latitude),
                (
                    building_point
                    for building in snapshot.buildings
                    if building.is_high
                    for building_point in building.points
                ),
            )
            tree_clearance = _nearest_distance(
                (candidate.longitude, candidate.latitude),
                snapshot.trees,
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
                            building_clearance_m=round(building_clearance or 0.0, 1),
                            tree_clearance_m=round(tree_clearance or 0.0, 1),
                            relative_elevation_m=round(relative_elevation, 1),
                            building_density=round(building_density, 3),
                            tree_density=round(tree_density, 3),
                            hazard_intersections=hazard_count,
                        ),
                        rationale=rationale,
                        source=snapshot_source,
                        data_at=snapshot.observed_at,
                        simulation=simulation_data_included,
                        uncertainty_notice=snapshot_notice
                        + " "
                        + _coverage_notice(request.disaster_type),
                    ),
                )
            )
        items = [item for _, item in sorted(ranked, key=lambda value: value[0])][:3]
        return ContextAreaListResponse(
            items=items,
            data_at=snapshot.observed_at,
            source=snapshot_source,
            simulation=simulation_data_included,
            uncertainty_notice=(
                snapshot_notice + " " + _coverage_notice(request.disaster_type)
                if items
                else snapshot_notice
                + " No candidate met the requested disaster-specific criteria "
                "within the selected radius."
            ),
        )


def _candidate_coordinates(
    origin: Coordinate, radius_m: float
) -> tuple[Coordinate, ...]:
    """Return a bounded grid of local terrain samples around the origin."""

    latitude_degrees = radius_m / 111_000.0
    longitude_scale = max(
        1_000.0,
        111_000.0 * abs(cos(radians(origin.latitude))),
    )
    longitude_degrees = radius_m / longitude_scale
    candidates: list[Coordinate] = []
    seen: set[tuple[float, float]] = set()
    for latitude_index in range(-FLOOD_GRID_STEPS, FLOOD_GRID_STEPS + 1):
        for longitude_index in range(-FLOOD_GRID_STEPS, FLOOD_GRID_STEPS + 1):
            if latitude_index == 0 and longitude_index == 0:
                continue
            latitude = origin.latitude + (
                latitude_degrees * latitude_index / FLOOD_GRID_STEPS
            )
            longitude = origin.longitude + (
                longitude_degrees * longitude_index / FLOOD_GRID_STEPS
            )
            if not (-90.0 <= latitude <= 90.0 and -180.0 <= longitude <= 180.0):
                continue
            candidate = Coordinate(latitude=latitude, longitude=longitude)
            if _distance_m(origin, candidate) > radius_m:
                continue
            key = (round(candidate.latitude, 8), round(candidate.longitude, 8))
            if key in seen:
                continue
            seen.add(key)
            candidates.append(candidate)
    return tuple(candidates)


def _simulation_candidate_coordinates(
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


def _analyze_flood(
    request: ContextAreaRequest,
    hazards: Sequence[Hazard],
    snapshot: EnvironmentSnapshot,
    candidates: Sequence[Coordinate],
    *,
    source: str,
    uncertainty_notice: str,
    simulation_data_included: bool,
) -> ContextAreaListResponse:
    if not _flood_environment_is_usable(snapshot):
        return _empty_response(
            source,
            _append_notice(
                uncertainty_notice,
                _append_notice(
                    _coverage_notice("flood"),
                    "Mapped environment geometry or completeness was insufficient, "
                    "so nearby flood analysis was not generated.",
                ),
            ),
            simulation=simulation_data_included,
            data_at=snapshot.observed_at,
        )

    coverage_notice = _flood_coverage_notice(snapshot)
    expected_elevation_count = len(candidates) + 1
    elevations = snapshot.elevations_m
    if len(elevations) != expected_elevation_count or any(
        isinstance(elevation, bool)
        or not isinstance(elevation, (int, float))
        or not isfinite(float(elevation))
        for elevation in elevations
    ):
        return _empty_response(
            source,
            _append_notice(
                _append_notice(uncertainty_notice, coverage_notice),
                "Required terrain elevation data was incomplete or invalid, "
                "so nearby flood analysis was not generated.",
            ),
            simulation=simulation_data_included,
            data_at=snapshot.observed_at,
        )

    origin_elevation = float(elevations[0])
    usable_candidates: list[_FloodCandidate] = []
    for candidate, elevation in zip(candidates, elevations[1:], strict=True):
        candidate_point = (candidate.longitude, candidate.latitude)
        hazard_count = sum(
            _point_in_polygon(
                candidate_point,
                hazard.geometry.coordinates[0],
            )
            for hazard in hazards
        )
        if hazard_count:
            continue
        if _point_in_mapped_water(candidate_point, snapshot.water_features):
            continue
        accessible, mapped_accessible = _flood_candidate_accessibility(
            candidate_point, snapshot.open_spaces
        )
        if not accessible or _point_in_mapped_building(
            candidate_point, snapshot.buildings
        ):
            continue
        relative_elevation = float(elevation) - origin_elevation
        if relative_elevation <= 0.0:
            continue
        usable_candidates.append(
            _FloodCandidate(
                coordinate=candidate,
                relative_elevation_m=relative_elevation,
                distance_m=_distance_m(request.origin, candidate),
                mapped_accessible=mapped_accessible,
            )
        )

    if not usable_candidates:
        return _empty_response(
            source,
            _append_notice(
                _append_notice(uncertainty_notice, coverage_notice),
                "No conservative higher-ground candidate met the current "
                "flood, water, terrain, and access criteria within the selected "
                "radius.",
            ),
            simulation=simulation_data_included,
            data_at=snapshot.observed_at,
        )

    local_high_points = _local_high_points(
        usable_candidates,
        request.search_radius_m,
    )
    selected_candidates = _select_flood_candidates(
        local_high_points,
        request.search_radius_m,
    )
    items = []
    for index, candidate in enumerate(selected_candidates, start=1):
        candidate_point = (
            candidate.coordinate.longitude,
            candidate.coordinate.latitude,
        )
        building_clearance = _nearest_distance(
            candidate_point,
            (
                building_point
                for building in snapshot.buildings
                for building_point in building.points
            ),
        )
        tree_clearance = _nearest_distance(candidate_point, snapshot.trees)
        building_density = _density(
            candidate_point,
            (
                _feature_center(building.points)
                for building in snapshot.buildings
                if building.points
            ),
            20,
        )
        tree_density = _density(candidate_point, snapshot.trees, 30)
        rationale = _flood_rationale(candidate)
        items.append(
            ContextArea(
                id=_context_area_id(candidate.coordinate, "flood"),
                name=_candidate_name("flood", index),
                coordinate=candidate.coordinate,
                disaster_type="flood",
                scenario=request.scenario,
                distance_m=round(candidate.distance_m, 1),
                metrics=ContextMetrics(
                    building_clearance_m=round(building_clearance or 0.0, 1),
                    tree_clearance_m=round(tree_clearance or 0.0, 1),
                    relative_elevation_m=round(candidate.relative_elevation_m, 1),
                    building_density=round(building_density, 3),
                    tree_density=round(tree_density, 3),
                    hazard_intersections=0,
                ),
                rationale=rationale,
                source=source,
                data_at=snapshot.observed_at,
                simulation=simulation_data_included,
                uncertainty_notice=_append_notice(
                    _append_notice(uncertainty_notice, coverage_notice),
                    "Candidate access and route conditions are not verified.",
                ),
            )
        )

    return ContextAreaListResponse(
        items=items,
        data_at=snapshot.observed_at,
        source=source,
        simulation=simulation_data_included,
        uncertainty_notice=_append_notice(
            _append_notice(uncertainty_notice, coverage_notice),
            "Candidate access and route conditions are not verified.",
        ),
    )


def _flood_environment_is_usable(snapshot: EnvironmentSnapshot) -> bool:
    feature_groups = (
        snapshot.buildings,
        snapshot.open_spaces,
        snapshot.water_features,
    )
    if any(
        not getattr(feature, "geometry_complete", True)
        for features in feature_groups
        for feature in features
    ):
        return False
    if snapshot.data_complete:
        return True
    notice = snapshot.uncertainty_notice.casefold()
    return (
        "building height" in notice
        and "unavailable" in notice
        and "partial geometry" not in notice
    )


def _flood_coverage_notice(snapshot: EnvironmentSnapshot) -> str:
    notices = [
        _coverage_notice("flood"),
        "This is a lower-exposure terrain suggestion, not a guarantee; "
        "terrain, water levels, roads, and route conditions may differ.",
        "No authority-verified building-based flood shelter is available; "
        "mapped buildings are not recommended as flood shelters.",
    ]
    if snapshot.water_features:
        notices.append(
            "Mapped water, wetland, and waterway coverage may be incomplete; "
            "missing features are not confirmed absent."
        )
    else:
        notices.append(
            "No mapped water, wetland, or waterway geometry was returned; "
            "that is not confirmation that water is absent."
        )
    if snapshot.open_spaces:
        notices.append(
            "Mapped access metadata may be incomplete; unlisted spaces are not "
            "confirmed accessible."
        )
    else:
        notices.append(
            "No mapped accessible open-space geometry was returned; "
            "reachability and access were not confirmed."
        )
    if not snapshot.buildings:
        notices.append(
            "No mapped building footprint was returned; unmapped structures "
            "may overlap sampled terrain points."
        )
    if not snapshot.data_complete:
        notices.append(
            "Some environment metadata was incomplete, so confidence in this "
            "terrain comparison is lower."
        )
    if snapshot.cache_status == "stale":
        notices.append(
            "The environment observation is stale; mapped conditions may have "
            "changed since it was collected."
        )
    return " ".join(notices)


def _point_in_mapped_water(coordinate: Point, features: Sequence[WaterFeature]) -> bool:
    for feature in features:
        points = feature.points
        if not points:
            continue
        is_area = len(points) >= 3 and (
            not feature.feature_type.startswith("waterway:") or points[0] == points[-1]
        )
        if is_area and _point_in_polygon(coordinate, points):
            return True
        distance = _distance_to_geometry_m(
            coordinate,
            points,
            is_area=is_area,
        )
        if distance is not None and distance <= FLOOD_WATER_CLEARANCE_M:
            return True
    return False


def _flood_candidate_accessibility(
    coordinate: Point,
    features: Sequence[OpenSpaceFeature],
) -> tuple[bool, bool]:
    mapped_accessible = False
    for feature in features:
        if len(feature.points) < 3 or not _point_in_polygon(coordinate, feature.points):
            continue
        if feature.is_clearly_inaccessible or feature.is_indoor_or_covered:
            return False, False
        if (feature.access or "").casefold() in {
            "designated",
            "permissive",
            "public",
            "yes",
        }:
            mapped_accessible = True
    return True, mapped_accessible


def _point_in_mapped_building(
    coordinate: Point, features: Sequence[BuildingFeature]
) -> bool:
    for feature in features:
        if len(feature.points) >= 3 and _point_in_polygon(coordinate, feature.points):
            return True
        distance = _distance_to_geometry_m(
            coordinate,
            feature.points,
            is_area=len(feature.points) >= 3,
        )
        if distance is not None and distance <= 0.1:
            return True
    return False


def _local_high_points(
    candidates: Sequence[_FloodCandidate],
    radius_m: float,
) -> tuple[_FloodCandidate, ...]:
    neighborhood_radius = max(
        FLOOD_MIN_CLUSTER_RADIUS_M,
        radius_m * FLOOD_LOCAL_PEAK_RADIUS_RATIO,
    )
    peaks = tuple(
        candidate
        for candidate in candidates
        if not any(
            other.coordinate != candidate.coordinate
            and _distance_m(candidate.coordinate, other.coordinate)
            <= neighborhood_radius
            and other.relative_elevation_m
            > candidate.relative_elevation_m + FLOOD_ELEVATION_TIE_M
            for other in candidates
        )
    )
    return peaks or tuple(candidates)


def _select_flood_candidates(
    candidates: Sequence[_FloodCandidate],
    radius_m: float,
) -> tuple[_FloodCandidate, ...]:
    ranked = sorted(
        candidates,
        key=lambda candidate: (
            -candidate.relative_elevation_m,
            0 if candidate.mapped_accessible else 1,
            candidate.distance_m,
            candidate.coordinate.latitude,
            candidate.coordinate.longitude,
        ),
    )
    cluster_radius = max(
        FLOOD_MIN_CLUSTER_RADIUS_M,
        radius_m * FLOOD_CANDIDATE_CLUSTER_RADIUS_RATIO,
    )
    selected: list[_FloodCandidate] = []
    for candidate in ranked:
        if any(
            _distance_m(candidate.coordinate, selected_candidate.coordinate)
            <= cluster_radius
            for selected_candidate in selected
        ):
            continue
        selected.append(candidate)
        if len(selected) == 3:
            break
    return tuple(selected)


def _flood_rationale(
    candidate: _FloodCandidate,
) -> list[str]:
    access_reason = (
        "Located within a mapped accessible open space"
        if candidate.mapped_accessible
        else "No mapped accessible open space was confirmed"
    )
    return [
        "Lower-exposure terrain suggestion based on sampled elevation; "
        "it is not a guarantee",
        f"About {round(candidate.relative_elevation_m, 1)} m higher than "
        "the current location",
        "Outside current mapped flood hazards and mapped water, wetland, "
        "or waterway geometry",
        access_reason,
        f"About {round(candidate.distance_m)} m away; roads and route access "
        "are not verified",
        "Mapped buildings are not treated as flood shelters; only sampled "
        "outdoor terrain is considered",
    ]


def _analyze_earthquake(
    request: ContextAreaRequest,
    hazards: Sequence[Hazard],
    snapshot: EnvironmentSnapshot,
    *,
    source: str,
    uncertainty_notice: str,
    simulation_data_included: bool,
) -> ContextAreaListResponse:
    if not snapshot.data_complete:
        return _empty_response(
            source,
            uncertainty_notice
            + " Required mapped building, obstacle, or open-space geometry "
            "was incomplete, so nearby analysis was not generated.",
            simulation=simulation_data_included,
            data_at=snapshot.observed_at,
        )

    if not snapshot.open_spaces:
        missing_obstacles_notice = (
            " Required mapped building and tree/woodland data was incomplete."
            if not snapshot.buildings or not (snapshot.trees or snapshot.wooded_areas)
            else ""
        )
        return _empty_response(
            source,
            uncertainty_notice
            + " No mapped accessible open-space polygon was available, so "
            "nearby analysis was not generated; absence from the map is not "
            "confirmation that no suitable place exists." + missing_obstacles_notice,
            simulation=simulation_data_included,
            data_at=snapshot.observed_at,
        )

    if not snapshot.buildings or not (snapshot.trees or snapshot.wooded_areas):
        return _empty_response(
            source,
            uncertainty_notice
            + " Required mapped building and tree/woodland data was incomplete, "
            "so nearby analysis was not generated.",
            simulation=simulation_data_included,
            data_at=snapshot.observed_at,
        )

    if any(
        building.height_m is None
        or not building.geometry_complete
        or len(building.points) < 2
        for building in snapshot.buildings
    ):
        return _empty_response(
            source,
            uncertainty_notice
            + " Mapped building height or footprint data was incomplete, so "
            "nearby analysis was not generated.",
            simulation=simulation_data_included,
            data_at=snapshot.observed_at,
        )

    open_space_candidates = _open_space_candidates(
        snapshot.open_spaces,
        request.origin,
        request.search_radius_m,
    )
    if not open_space_candidates:
        return _empty_response(
            source,
            uncertainty_notice
            + " No mapped accessible open-space polygon had a usable interior "
            "point within the selected radius.",
            simulation=simulation_data_included,
            data_at=snapshot.observed_at,
        )

    high_buildings = tuple(
        building for building in snapshot.buildings if building.is_high
    )
    mapped_power = any(feature.points for feature in snapshot.power_features)
    coverage_notice = _earthquake_coverage_notice(
        snapshot, bool(high_buildings), mapped_power
    )
    ranked: list[tuple[tuple[float | str, ...], ContextArea]] = []
    seen_coordinates: set[tuple[float, float]] = set()

    for candidate in open_space_candidates:
        coordinate_key = (
            round(candidate.coordinate.latitude, 7),
            round(candidate.coordinate.longitude, 7),
        )
        if coordinate_key in seen_coordinates:
            continue
        seen_coordinates.add(coordinate_key)

        hazard_count = _polygon_hazard_intersections(candidate.polygon, hazards)
        if hazard_count:
            continue

        candidate_point = (
            candidate.coordinate.longitude,
            candidate.coordinate.latitude,
        )
        building_clearance = _nearest_feature_clearance(
            candidate_point, snapshot.buildings
        )
        high_building_clearance = (
            _nearest_feature_clearance(candidate_point, high_buildings)
            if high_buildings
            else float(EARTHQUAKE_HIGH_BUILDING_CLEARANCE_M)
        )
        tree_clearance = _tree_and_woodland_clearance(candidate_point, snapshot)
        power_clearance = (
            _nearest_feature_clearance(candidate_point, snapshot.power_features)
            if mapped_power
            else None
        )
        effective_power_clearance = (
            power_clearance
            if power_clearance is not None
            else float(EARTHQUAKE_POWER_CLEARANCE_M)
        )

        if (
            building_clearance is None
            or tree_clearance is None
            or candidate.open_space_edge_clearance_m
            < EARTHQUAKE_OPEN_SPACE_EDGE_CLEARANCE_M
            or building_clearance < EARTHQUAKE_BUILDING_CLEARANCE_M
            or high_building_clearance < EARTHQUAKE_HIGH_BUILDING_CLEARANCE_M
            or tree_clearance < EARTHQUAKE_TREE_CLEARANCE_M
            or effective_power_clearance < EARTHQUAKE_POWER_CLEARANCE_M
        ):
            continue

        building_density = _density(
            candidate_point,
            (_feature_center(building.points) for building in snapshot.buildings),
            20,
        )
        tree_density = _density(
            candidate_point,
            (
                *snapshot.trees,
                *(
                    _feature_center(wooded_area.points)
                    for wooded_area in snapshot.wooded_areas
                    if wooded_area.points
                ),
            ),
            30,
        )
        distance_m = _distance_m(request.origin, candidate.coordinate)
        name = _open_space_name(candidate.feature)
        high_building_reason = (
            f"At least {round(high_building_clearance)} m from mapped high buildings"
            if high_buildings
            else "High-building clearance is not confirmed; no mapped high "
            "building was returned"
        )
        power_reason = (
            f"At least {round(effective_power_clearance)} m from mapped power "
            "infrastructure"
            if mapped_power
            else "Power clearance is not confirmed; no mapped power "
            "infrastructure was returned"
        )
        rationale = [
            "Lower-exposure suggestion based on the mapped accessible "
            "open-space footprint",
            f"At least {round(building_clearance)} m from mapped building footprints",
            high_building_reason,
            f"At least {round(tree_clearance)} m from mapped trees or woodland",
            power_reason,
            f"Interior point is about {round(candidate.open_space_edge_clearance_m)} "
            f"m from the mapped edge; usable area is about "
            f"{round(candidate.area_m2)} m²",
        ]
        ranked.append(
            (
                (
                    -high_building_clearance,
                    -building_clearance,
                    -tree_clearance,
                    -effective_power_clearance,
                    -candidate.area_m2,
                    distance_m,
                    name,
                ),
                ContextArea(
                    id=_context_area_id(candidate.coordinate, "earthquake"),
                    name=name,
                    coordinate=candidate.coordinate,
                    disaster_type="earthquake",
                    scenario=request.scenario,
                    distance_m=round(distance_m, 1),
                    metrics=ContextMetrics(
                        building_clearance_m=round(building_clearance, 1),
                        tree_clearance_m=round(tree_clearance, 1),
                        relative_elevation_m=0.0,
                        building_density=round(building_density, 3),
                        tree_density=round(tree_density, 3),
                        hazard_intersections=hazard_count,
                    ),
                    rationale=rationale,
                    source=source,
                    data_at=snapshot.observed_at,
                    simulation=simulation_data_included,
                    uncertainty_notice=_append_notice(
                        uncertainty_notice, coverage_notice
                    ),
                ),
            )
        )

    items = [item for _, item in sorted(ranked, key=lambda value: value[0])][:3]
    return ContextAreaListResponse(
        items=items,
        data_at=snapshot.observed_at,
        source=source,
        simulation=simulation_data_included,
        uncertainty_notice=(
            _append_notice(uncertainty_notice, coverage_notice)
            if items
            else _append_notice(
                uncertainty_notice,
                "No mapped open-space candidate met the conservative "
                "earthquake clearance criteria within the selected radius.",
            )
        ),
    )


def _open_space_candidates(
    features: Sequence[OpenSpaceFeature],
    origin: Coordinate,
    radius_m: float,
) -> tuple[_EarthquakeCandidate, ...]:
    candidates: list[_EarthquakeCandidate] = []
    for feature in features:
        if (
            feature.is_clearly_inaccessible
            or feature.is_indoor_or_covered
            or not feature.geometry_complete
        ):
            continue
        polygon = _normalise_polygon(feature.points)
        if polygon is None:
            continue
        area_m2 = feature.area_m2 or _polygon_area_m2(polygon)
        if area_m2 is None or area_m2 <= 0:
            continue
        interior_point = _safe_interior_point(polygon)
        if interior_point is None:
            continue
        coordinate = Coordinate(latitude=interior_point[1], longitude=interior_point[0])
        if _distance_m(origin, coordinate) > radius_m:
            continue
        edge_clearance = _distance_to_geometry_m(
            interior_point,
            polygon,
            is_area=True,
            zero_if_inside=False,
        )
        if edge_clearance is None or edge_clearance <= 0:
            continue
        candidates.append(
            _EarthquakeCandidate(
                feature=feature,
                polygon=polygon,
                coordinate=coordinate,
                area_m2=area_m2,
                open_space_edge_clearance_m=edge_clearance,
            )
        )
    return tuple(candidates)


def _open_space_name(feature: OpenSpaceFeature) -> str:
    if feature.name:
        return feature.name
    labels = {
        "common": "common",
        "garden": "garden",
        "golf_course": "golf course",
        "park": "park",
        "pitch": "sports field",
        "playground": "playground",
        "recreation_ground": "recreation ground",
        "sports_centre": "sports centre",
        "sports_hall": "sports hall",
        "stadium": "stadium",
        "track": "track",
        "square": "public square",
        "assembly_point": "assembly point",
    }
    return f"Mapped {labels.get(feature.feature_type, 'open space')}"


def _earthquake_coverage_notice(
    snapshot: EnvironmentSnapshot, mapped_high_building: bool, mapped_power: bool
) -> str:
    notices = [
        "This lower-exposure suggestion uses mapped OpenStreetMap geometry "
        "and is not a guarantee; unmapped buildings, trees, woodland, power "
        "infrastructure, hazards, access restrictions, and route conditions "
        "may differ."
    ]
    if not mapped_power:
        notices.append(
            "No mapped power infrastructure was returned; power clearance is "
            "not confirmed."
        )
    if not mapped_high_building:
        notices.append(
            "No mapped high-building record was returned; high-building "
            "clearance is not confirmed."
        )
    if not snapshot.wooded_areas:
        notices.append(
            "No mapped woodland polygon was returned; woodland absence is not "
            "confirmed."
        )
    return " ".join(notices)


def _normalise_polygon(points: Sequence[Point]) -> tuple[Point, ...] | None:
    cleaned: list[Point] = []
    for point in points:
        if not cleaned or point != cleaned[-1]:
            cleaned.append(point)
    if len(cleaned) >= 2 and cleaned[0] == cleaned[-1]:
        cleaned.pop()
    if len(cleaned) < 3:
        return None
    area_m2 = _polygon_area_m2(tuple((*cleaned, cleaned[0])))
    if area_m2 is None:
        return None
    return tuple((*cleaned, cleaned[0]))


def _safe_interior_point(polygon: Sequence[Point]) -> Point | None:
    unique_points = polygon[:-1] if polygon and polygon[0] == polygon[-1] else polygon
    if len(unique_points) < 3:
        return None
    candidates: list[Point] = []
    centroid = _polygon_centroid(unique_points)
    if centroid is not None:
        candidates.append(centroid)
    candidates.append(
        (
            sum(point[0] for point in unique_points) / len(unique_points),
            sum(point[1] for point in unique_points) / len(unique_points),
        )
    )
    min_longitude = min(point[0] for point in unique_points)
    max_longitude = max(point[0] for point in unique_points)
    min_latitude = min(point[1] for point in unique_points)
    max_latitude = max(point[1] for point in unique_points)
    for latitude_index in range(1, 10):
        latitude = min_latitude + (max_latitude - min_latitude) * latitude_index / 10
        for longitude_index in range(1, 10):
            longitude = (
                min_longitude + (max_longitude - min_longitude) * longitude_index / 10
            )
            candidates.append((longitude, latitude))

    scored = []
    for candidate in candidates:
        if not _point_in_polygon(candidate, polygon):
            continue
        edge_clearance = _distance_to_geometry_m(
            candidate,
            polygon,
            is_area=True,
            zero_if_inside=False,
        )
        if edge_clearance is not None and edge_clearance > 0:
            scored.append((edge_clearance, candidate))
    if not scored:
        return None
    return max(scored, key=lambda value: value[0])[1]


def _polygon_centroid(points: Sequence[Point]) -> Point | None:
    area_twice = 0.0
    longitude_sum = 0.0
    latitude_sum = 0.0
    for first, second in zip(points, (*points[1:], points[0]), strict=False):
        cross = first[0] * second[1] - second[0] * first[1]
        area_twice += cross
        longitude_sum += (first[0] + second[0]) * cross
        latitude_sum += (first[1] + second[1]) * cross
    if abs(area_twice) <= 1e-15:
        return None
    return (
        longitude_sum / (3 * area_twice),
        latitude_sum / (3 * area_twice),
    )


def _polygon_area_m2(points: Sequence[Point]) -> float | None:
    if len(points) < 3:
        return None
    mean_latitude = sum(point[1] for point in points) / len(points)
    scale_x = 111_320.0 * cos(radians(mean_latitude))
    scale_y = 110_540.0
    area_twice = 0.0
    for first, second in zip(points, (*points[1:], points[0]), strict=False):
        area_twice += (
            first[0] * scale_x * second[1] * scale_y
            - second[0] * scale_x * first[1] * scale_y
        )
    area = abs(area_twice) / 2
    return area if area > 0 else None


def _nearest_feature_clearance(
    coordinate: Point, features: Sequence[Any]
) -> float | None:
    distances = []
    for feature in features:
        points = getattr(feature, "points", getattr(feature, "footprint", ()))
        if not points:
            continue
        distance = _distance_to_geometry_m(
            coordinate,
            points,
            is_area=_feature_is_area(feature),
        )
        if distance is not None:
            distances.append(distance)
    return min(distances, default=None)


def _tree_and_woodland_clearance(
    coordinate: Point, snapshot: EnvironmentSnapshot
) -> float | None:
    distances = [_distance_pair_m(coordinate, tree) for tree in snapshot.trees]
    for wooded_area in snapshot.wooded_areas:
        distance = _distance_to_geometry_m(coordinate, wooded_area.points, is_area=True)
        if distance is not None:
            distances.append(distance)
    return min(distances, default=None)


def _feature_is_area(feature: Any) -> bool:
    if isinstance(feature, (BuildingFeature, OpenSpaceFeature, WoodedAreaFeature)):
        return True
    feature_type = getattr(feature, "feature_type", "")
    return feature_type in {
        "power:plant",
        "power:substation",
        "power:transformer",
    }


def _distance_to_geometry_m(
    coordinate: Point,
    points: Sequence[Point],
    *,
    is_area: bool,
    zero_if_inside: bool = True,
) -> float | None:
    if not points:
        return None
    if len(points) == 1:
        return _distance_pair_m(coordinate, points[0])
    if is_area and zero_if_inside and _point_in_polygon(coordinate, points):
        return 0.0
    segments = tuple(zip(points, points[1:], strict=False))
    if is_area and points[0] != points[-1]:
        segments += ((points[-1], points[0]),)
    if not segments:
        return _distance_pair_m(coordinate, points[0])
    return min(
        _distance_to_segment_m(coordinate, start, end) for start, end in segments
    )


def _distance_to_segment_m(coordinate: Point, start: Point, end: Point) -> float:
    latitude = radians((coordinate[1] + start[1] + end[1]) / 3)
    scale_x = 111_320.0 * cos(latitude)
    scale_y = 110_540.0
    start_x = start[0] * scale_x
    start_y = start[1] * scale_y
    end_x = end[0] * scale_x
    end_y = end[1] * scale_y
    point_x = coordinate[0] * scale_x
    point_y = coordinate[1] * scale_y
    delta_x = end_x - start_x
    delta_y = end_y - start_y
    length_squared = delta_x * delta_x + delta_y * delta_y
    if length_squared <= 0:
        return sqrt((point_x - start_x) ** 2 + (point_y - start_y) ** 2)
    projection = (
        (point_x - start_x) * delta_x + (point_y - start_y) * delta_y
    ) / length_squared
    projection = max(0.0, min(1.0, projection))
    nearest_x = start_x + projection * delta_x
    nearest_y = start_y + projection * delta_y
    return sqrt((point_x - nearest_x) ** 2 + (point_y - nearest_y) ** 2)


def _polygon_hazard_intersections(
    polygon: Sequence[Point], hazards: Sequence[Hazard]
) -> int:
    return sum(
        _polygons_intersect(polygon, hazard.geometry.coordinates[0])
        for hazard in hazards
    )


def _polygons_intersect(first: Sequence[Point], second: Sequence[Point]) -> bool:
    if len(first) < 3 or len(second) < 3:
        return False
    if _point_in_polygon(first[0], second) or _point_in_polygon(second[0], first):
        return True
    first_edges = tuple(zip(first, first[1:], strict=False))
    second_edges = tuple(zip(second, second[1:], strict=False))
    if first[0] != first[-1]:
        first_edges += ((first[-1], first[0]),)
    if second[0] != second[-1]:
        second_edges += ((second[-1], second[0]),)
    return any(
        _segments_intersect(first_start, first_end, second_start, second_end)
        for first_start, first_end in first_edges
        for second_start, second_end in second_edges
    )


def _segments_intersect(
    first_start: Point,
    first_end: Point,
    second_start: Point,
    second_end: Point,
) -> bool:
    first_orientation = _orientation(first_start, first_end, second_start)
    second_orientation = _orientation(first_start, first_end, second_end)
    third_orientation = _orientation(second_start, second_end, first_start)
    fourth_orientation = _orientation(second_start, second_end, first_end)
    if (
        first_orientation != second_orientation
        and third_orientation != fourth_orientation
    ):
        return True
    return (
        (first_orientation == 0 and _on_segment(first_start, second_start, first_end))
        or (second_orientation == 0 and _on_segment(first_start, second_end, first_end))
        or (
            third_orientation == 0
            and _on_segment(second_start, first_start, second_end)
        )
        or (
            fourth_orientation == 0 and _on_segment(second_start, first_end, second_end)
        )
    )


def _orientation(start: Point, end: Point, point: Point) -> int:
    cross = (end[0] - start[0]) * (point[1] - start[1]) - (end[1] - start[1]) * (
        point[0] - start[0]
    )
    if abs(cross) <= 1e-12:
        return 0
    return 1 if cross > 0 else -1


def _on_segment(start: Point, point: Point, end: Point) -> bool:
    return (
        _orientation(start, end, point) == 0
        and min(start[0], end[0]) - 1e-12 <= point[0] <= max(start[0], end[0]) + 1e-12
        and min(start[1], end[1]) - 1e-12 <= point[1] <= max(start[1], end[1]) + 1e-12
    )


def _candidate_allowed(
    disaster_type: str,
    hazard_count: int,
    building_clearance: float | None,
    high_building_clearance: float | None,
    tree_clearance: float | None,
    relative_elevation: float,
) -> bool:
    if hazard_count:
        return False
    if disaster_type == "earthquake":
        return (
            building_clearance is not None
            and high_building_clearance is not None
            and tree_clearance is not None
            and building_clearance >= EARTHQUAKE_BUILDING_CLEARANCE_M
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
    return (
        hazard_count,
        -(building_clearance or 0.0),
        -(tree_clearance or 0.0),
        float(index),
    )


def _rationale(
    disaster_type: str,
    hazard_count: int,
    building_clearance: float | None,
    high_building_clearance: float | None,
    tree_clearance: float | None,
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


def _append_notice(existing: str, addition: str) -> str:
    return f"{existing.strip()} {addition.strip()}".strip()


def _empty_response(
    source: str,
    notice: str,
    *,
    simulation: bool = False,
    data_at: datetime | None = None,
) -> ContextAreaListResponse:
    timestamp = data_at or datetime.now(UTC)
    if timestamp.tzinfo is None or timestamp.utcoffset() is None:
        timestamp = datetime.now(UTC)
    else:
        timestamp = timestamp.astimezone(UTC)
    return ContextAreaListResponse(
        items=[],
        data_at=timestamp,
        source=source,
        simulation=simulation,
        uncertainty_notice=notice,
    )


def _source_data_timestamp(
    hazards: Sequence[Hazard], source_data_at: datetime | None
) -> datetime:
    timestamps = [
        hazard.data_at.astimezone(UTC)
        for hazard in hazards
        if hazard.data_at.tzinfo is not None and hazard.data_at.utcoffset() is not None
    ]
    if (
        source_data_at is not None
        and source_data_at.tzinfo is not None
        and source_data_at.utcoffset() is not None
    ):
        timestamps.append(source_data_at.astimezone(UTC))
    return max(timestamps, default=datetime.now(UTC))


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
) -> float | None:
    distances = (_distance_pair_m(coordinate, point) for point in points)
    return min(distances, default=None)


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
    if len(polygon) < 3:
        return False
    inside = False
    previous_x, previous_y = polygon[-1]
    for current_x, current_y in polygon:
        if _on_segment(
            (previous_x, previous_y),
            point,
            (current_x, current_y),
        ):
            return True
        if (current_y > point[1]) != (previous_y > point[1]):
            crossing_x = (previous_x - current_x) * (point[1] - current_y) / (
                previous_y - current_y
            ) + current_x
            if point[0] < crossing_x:
                inside = not inside
        previous_x, previous_y = current_x, current_y
    return inside
