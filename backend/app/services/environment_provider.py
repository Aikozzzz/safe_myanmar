from __future__ import annotations

from collections import OrderedDict
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass, replace
from datetime import UTC, datetime
from math import ceil, cos, floor, isfinite, radians
from re import search
from threading import RLock
from typing import Any, Literal, Protocol

import httpx

from app.schemas.navigation import Coordinate

type Point = tuple[float, float]
type CacheStatus = Literal["live", "fresh", "stale"]

MAX_ENVIRONMENT_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_ENVIRONMENT_RADIUS_M = 1500.0
MAX_ELEVATION_POINTS = 128
MAX_OSM_FEATURES = 10_000
DEFAULT_ENVIRONMENT_CACHE_MAX_ENTRIES = 128
DEFAULT_ENVIRONMENT_CACHE_TTL_SECONDS = 300.0
COARSE_CACHE_GRID_DEGREES = 0.01
COARSE_CACHE_RADIUS_BUCKET_M = 250.0
HIGH_BUILDING_HEIGHT_M = 10.0
DEFAULT_ELEVATION_API_URL = "https://api.opentopodata.org/v1/aster30m"


class ContextAnalysisUnavailable(Exception):
    """Raised when an environment provider cannot return a valid observation."""


@dataclass(frozen=True)
class GeometryFeature:
    """A mapped OSM geometry with the tags needed by candidate selection."""

    points: tuple[Point, ...]
    name: str | None = None
    access: str | None = None
    indoor: str | None = None
    covered: str | None = None
    feature_type: str = "geometry"
    osm_type: str | None = None
    osm_id: int | None = None
    area_m2: float | None = None
    geometry_complete: bool = True

    @property
    def geometry(self) -> tuple[Point, ...]:
        return self.points

    @property
    def is_clearly_inaccessible(self) -> bool:
        return (self.access or "").casefold() in {
            "customers",
            "members",
            "no",
            "permit",
            "private",
            "restricted",
        }

    @property
    def is_indoor_or_covered(self) -> bool:
        return (self.indoor or "").casefold() in {
            "1",
            "building",
            "room",
            "true",
            "yes",
        } or (self.covered or "").casefold() in {"1", "building", "true", "yes"}


@dataclass(frozen=True)
class OpenSpaceFeature(GeometryFeature):
    feature_type: str = "open_space"


@dataclass(frozen=True)
class WoodedAreaFeature(GeometryFeature):
    feature_type: str = "wooded_area"


@dataclass(frozen=True)
class PowerFeature(GeometryFeature):
    feature_type: str = "power"


@dataclass(frozen=True)
class WaterFeature(GeometryFeature):
    feature_type: str = "water"


# More descriptive aliases keep later selection code readable without creating
# duplicate representations for the same mapped geometry.
PowerInfrastructureFeature = PowerFeature
WaterBodyFeature = WaterFeature


@dataclass(frozen=True)
class BuildingFeature:
    """An OSM building footprint and its conservatively parsed height."""

    points: tuple[Point, ...]
    height_m: float | None
    name: str | None = None
    access: str | None = None
    indoor: str | None = None
    covered: str | None = None
    osm_type: str | None = None
    osm_id: int | None = None
    area_m2: float | None = None
    geometry_complete: bool = True

    @property
    def footprint(self) -> tuple[Point, ...]:
        return self.points

    @property
    def is_high(self) -> bool:
        return self.height_m is not None and self.height_m >= HIGH_BUILDING_HEIGHT_M

    @property
    def is_clearly_inaccessible(self) -> bool:
        return (self.access or "").casefold() in {
            "customers",
            "members",
            "no",
            "permit",
            "private",
            "restricted",
        }

    @property
    def is_indoor_or_covered(self) -> bool:
        return (self.indoor or "").casefold() in {
            "1",
            "building",
            "room",
            "true",
            "yes",
        } or (self.covered or "").casefold() in {"1", "building", "true", "yes"}


@dataclass(frozen=True)
class OSMEnvironmentObservation:
    buildings: tuple[BuildingFeature, ...] = ()
    open_spaces: tuple[OpenSpaceFeature, ...] = ()
    trees: tuple[Point, ...] = ()
    wooded_areas: tuple[WoodedAreaFeature, ...] = ()
    power_features: tuple[PowerFeature, ...] = ()
    water_features: tuple[WaterFeature, ...] = ()
    data_complete: bool = True
    uncertainty_notice: str = (
        "OpenStreetMap coverage may be incomplete; missing mapped features are "
        "not confirmed absent."
    )

    @property
    def power_infrastructure(self) -> tuple[PowerFeature, ...]:
        return self.power_features

    @property
    def open_space_features(self) -> tuple[OpenSpaceFeature, ...]:
        return self.open_spaces

    @property
    def wooded_area_features(self) -> tuple[WoodedAreaFeature, ...]:
        return self.wooded_areas

    @property
    def power_lines(self) -> tuple[PowerFeature, ...]:
        return tuple(
            feature
            for feature in self.power_features
            if feature.feature_type in {"power:line", "power:minor_line"}
        )

    @property
    def water_bodies(self) -> tuple[WaterFeature, ...]:
        return self.water_features

    @property
    def waterways(self) -> tuple[WaterFeature, ...]:
        return tuple(
            feature
            for feature in self.water_features
            if feature.feature_type.startswith("waterway:")
        )


@dataclass(frozen=True)
class EnvironmentSnapshot:
    """Provider observations retained by the analyzer and its coarse cache.

    The first five fields intentionally preserve the original constructor and
    provider contract. Additional collections are optional so existing
    providers and tests can continue returning the original shape.
    """

    buildings: tuple[BuildingFeature, ...]
    trees: tuple[Point, ...]
    elevations_m: tuple[float, ...]
    observed_at: datetime
    source: str
    open_spaces: tuple[OpenSpaceFeature, ...] = ()
    wooded_areas: tuple[WoodedAreaFeature, ...] = ()
    power_features: tuple[PowerFeature, ...] = ()
    water_features: tuple[WaterFeature, ...] = ()
    data_complete: bool = True
    cache_status: CacheStatus = "live"
    uncertainty_notice: str = ""

    @property
    def power_infrastructure(self) -> tuple[PowerFeature, ...]:
        return self.power_features

    @property
    def open_space_features(self) -> tuple[OpenSpaceFeature, ...]:
        return self.open_spaces

    @property
    def wooded_area_features(self) -> tuple[WoodedAreaFeature, ...]:
        return self.wooded_areas

    @property
    def power_lines(self) -> tuple[PowerFeature, ...]:
        return tuple(
            feature
            for feature in self.power_features
            if feature.feature_type in {"power:line", "power:minor_line"}
        )

    @property
    def water_bodies(self) -> tuple[WaterFeature, ...]:
        return self.water_features

    @property
    def waterways(self) -> tuple[WaterFeature, ...]:
        return tuple(
            feature
            for feature in self.water_features
            if feature.feature_type.startswith("waterway:")
        )


class EnvironmentProvider(Protocol):
    def observe(
        self,
        origin: Coordinate,
        candidates: Sequence[Coordinate],
        radius_m: float,
        *,
        include_obstacles: bool,
        include_elevation: bool,
        include_water: bool = False,
    ) -> EnvironmentSnapshot: ...

    def close(self) -> None: ...


def build_overpass_query(
    origin: Coordinate, radius_m: float, timeout_seconds: float
) -> str:
    """Build a bounded full-geometry Overpass query for one coarse analysis area."""

    _validate_radius(radius_m)
    timeout = max(1, round(timeout_seconds))
    around = f"{radius_m:.1f},{origin.latitude:.6f},{origin.longitude:.6f}"
    return f"""[out:json][timeout:{timeout}];
(
  way[building](around:{around});
  relation[building](around:{around});
  node[building](around:{around});
  nwr[leisure~"^(park|pitch|sports_centre|recreation_ground|playground|garden|common|stadium|track|golf_course|sports_hall)$"](around:{around});
  nwr[place=square](around:{around});
  nwr[emergency=assembly_point](around:{around});
  nwr[amenity=assembly_point](around:{around});
  nwr[assembly_point~"^(yes|designated)$"](around:{around});
  node[natural=tree](around:{around});
  way[natural=tree](around:{around});
  relation[natural=tree](around:{around});
  nwr[natural~"^(tree_row|wood|scrub|heath)$"](around:{around});
  nwr[landuse=forest](around:{around});
  nwr[power](around:{around});
  nwr[natural=water](around:{around});
  nwr[natural=wetland](around:{around});
  nwr[waterway](around:{around});
  nwr[landuse~"^(reservoir|basin|salt_pond)$"](around:{around});
);
out tags geom;"""


def parse_overpass_response(payload: Mapping[str, Any]) -> OSMEnvironmentObservation:
    """Parse only bounded, validated OSM geometry and selection-relevant tags."""

    if not isinstance(payload, Mapping):
        raise ContextAnalysisUnavailable
    elements = payload.get("elements")
    if not isinstance(elements, list):
        raise ContextAnalysisUnavailable

    buildings: list[BuildingFeature] = []
    open_spaces: list[OpenSpaceFeature] = []
    trees: list[Point] = []
    wooded_areas: list[WoodedAreaFeature] = []
    power_features: list[PowerFeature] = []
    water_features: list[WaterFeature] = []
    geometry_incomplete = len(elements) > MAX_OSM_FEATURES
    height_incomplete = False

    for element in elements[:MAX_OSM_FEATURES]:
        if not isinstance(element, Mapping):
            geometry_incomplete = True
            continue
        tags = _element_tags(element)
        points, geometry_complete = _element_points(element)
        if not points:
            if _is_recognized_element(tags):
                geometry_incomplete = True
            continue
        common = _feature_kwargs(element, tags, points, geometry_complete)
        area_m2 = _polygon_area_m2(points) if _is_area_geometry(tags) else None

        if "building" in tags:
            height_m = _building_height_m(tags)
            building_geometry_complete = geometry_complete and (
                _tag_text(element, "type") != "node"
            )
            building_common = {
                **common,
                "geometry_complete": building_geometry_complete,
            }
            buildings.append(
                BuildingFeature(
                    points=points,
                    height_m=height_m,
                    area_m2=area_m2,
                    **building_common,
                )
            )
            if height_m is None:
                height_incomplete = True

        if _is_open_space(tags):
            feature = OpenSpaceFeature(
                points=points,
                area_m2=area_m2,
                feature_type=_open_space_type(tags),
                **common,
            )
            if not feature.is_clearly_inaccessible:
                open_spaces.append(feature)

        if tags.get("natural") == "tree":
            trees.extend(points)

        if _is_wooded_area(tags):
            wooded_areas.append(
                WoodedAreaFeature(
                    points=points,
                    area_m2=area_m2,
                    feature_type=_wooded_area_type(tags),
                    **common,
                )
            )

        if "power" in tags and _tag_text(tags, "power") is not None:
            power_features.append(
                PowerFeature(
                    points=points,
                    area_m2=area_m2,
                    feature_type=f"power:{_tag_text(tags, 'power')}",
                    **common,
                )
            )

        if _is_water_feature(tags):
            water_features.append(
                WaterFeature(
                    points=points,
                    area_m2=area_m2,
                    feature_type=_water_feature_type(tags),
                    **common,
                )
            )

        if not geometry_complete and _is_recognized_element(tags):
            geometry_incomplete = True

    notice = (
        "OpenStreetMap coverage may be incomplete; missing mapped features are "
        "not confirmed absent."
    )
    if geometry_incomplete:
        notice += (
            " Some mapped features had missing or partial geometry and were "
            "omitted or represented approximately."
        )
    if height_incomplete:
        notice += " Some mapped building heights were unavailable."
    return OSMEnvironmentObservation(
        buildings=tuple(buildings),
        open_spaces=tuple(open_spaces),
        trees=tuple(trees),
        wooded_areas=tuple(wooded_areas),
        power_features=tuple(power_features),
        water_features=tuple(water_features),
        data_complete=not geometry_incomplete and not height_incomplete,
        uncertainty_notice=notice,
    )


class LiveEnvironmentProvider:
    def __init__(
        self,
        *,
        overpass_url: str,
        elevation_url: str,
        timeout_seconds: float,
        http_client: httpx.Client | None = None,
        clock: Callable[[], datetime] | None = None,
    ) -> None:
        self._overpass_url = overpass_url
        self._elevation_url = elevation_url
        self._elevation_source = _elevation_source(elevation_url)
        self._timeout_seconds = timeout_seconds
        self._clock = clock or (lambda: datetime.now(UTC))
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
        include_water: bool = False,
    ) -> EnvironmentSnapshot:
        _validate_radius(radius_m)
        osm_observation: OSMEnvironmentObservation | None = None
        sources: list[str] = []
        notices: list[str] = []
        if include_obstacles or include_water:
            osm_observation = self._load_osm_environment(origin, radius_m)
            sources.append("OpenStreetMap via Overpass")
            notices.append(osm_observation.uncertainty_notice)

        elevations: tuple[float, ...] = ()
        if include_elevation:
            elevations = self._load_elevations(candidates)
            sources.append(self._elevation_source)
            notices.append(
                f"{self._elevation_source} terrain elevation may be incomplete "
                "or stale; it is not a flood forecast."
            )

        if not sources:
            raise ContextAnalysisUnavailable

        observed_at = _utc_datetime(self._clock())
        return EnvironmentSnapshot(
            buildings=osm_observation.buildings if osm_observation else (),
            trees=osm_observation.trees if osm_observation else (),
            elevations_m=elevations,
            observed_at=observed_at,
            source=" + ".join(sources),
            open_spaces=osm_observation.open_spaces if osm_observation else (),
            wooded_areas=osm_observation.wooded_areas if osm_observation else (),
            power_features=osm_observation.power_features if osm_observation else (),
            water_features=osm_observation.water_features if osm_observation else (),
            data_complete=osm_observation.data_complete
            if osm_observation is not None
            else True,
            uncertainty_notice=" ".join(notices),
        )

    def _load_osm_environment(
        self, origin: Coordinate, radius_m: float
    ) -> OSMEnvironmentObservation:
        query = build_overpass_query(origin, radius_m, self._timeout_seconds)
        payload = self._request_json(
            self._http_client.get,
            self._overpass_url,
            params={"data": query},
        )
        return parse_overpass_response(payload)

    def _load_obstacles(
        self, origin: Coordinate, radius_m: float
    ) -> tuple[tuple[BuildingFeature, ...], tuple[Point, ...]]:
        """Retain the original helper for callers that only need obstacles."""

        observation = self._load_osm_environment(origin, radius_m)
        return observation.buildings, observation.trees

    def _load_elevations(self, candidates: Sequence[Coordinate]) -> tuple[float, ...]:
        if len(candidates) > MAX_ELEVATION_POINTS:
            raise ContextAnalysisUnavailable
        if not candidates:
            return ()
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
            if not isinstance(result, Mapping):
                raise ContextAnalysisUnavailable
            elevation = result.get("elevation")
            if (
                not isinstance(elevation, (int, float))
                or isinstance(elevation, bool)
                or not isfinite(float(elevation))
            ):
                raise ContextAnalysisUnavailable
            elevations.append(float(elevation))
        return tuple(elevations)

    def _request_json(self, request: Any, url: str, **kwargs: Any) -> dict[str, Any]:
        try:
            response = request(
                url,
                timeout=self._timeout_seconds,
                headers={"User-Agent": "SafeMyanmar/1.0"},
                **kwargs,
            )
            response.raise_for_status()
            content_length = response.headers.get("content-length")
            if content_length is not None:
                try:
                    declared_length = int(content_length)
                except ValueError:
                    raise ContextAnalysisUnavailable from None
                if (
                    declared_length < 0
                    or declared_length > MAX_ENVIRONMENT_RESPONSE_BYTES
                ):
                    raise ContextAnalysisUnavailable
            content = response.content
            if len(content) > MAX_ENVIRONMENT_RESPONSE_BYTES:
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


@dataclass(frozen=True)
class _EnvironmentCacheKey:
    origin_cell: tuple[int, int]
    candidate_cells: tuple[tuple[int, int], ...]
    radius_bucket: int
    include_obstacles: bool
    include_elevation: bool
    include_water: bool


@dataclass(frozen=True)
class _EnvironmentCacheEntry:
    snapshot: EnvironmentSnapshot
    stored_at: datetime


class CachedEnvironmentProvider:
    """Bounded, process-local cache that never keys observations by exact GPS."""

    def __init__(
        self,
        provider: EnvironmentProvider,
        *,
        max_entries: int = DEFAULT_ENVIRONMENT_CACHE_MAX_ENTRIES,
        fresh_ttl_seconds: float = DEFAULT_ENVIRONMENT_CACHE_TTL_SECONDS,
        clock: Callable[[], datetime] | None = None,
    ) -> None:
        if (
            isinstance(max_entries, bool)
            or not isinstance(max_entries, int)
            or max_entries < 1
        ):
            raise ValueError("max_entries must be a positive integer")
        if (
            isinstance(fresh_ttl_seconds, bool)
            or not isinstance(fresh_ttl_seconds, (int, float))
            or not isfinite(float(fresh_ttl_seconds))
            or fresh_ttl_seconds < 0
        ):
            raise ValueError("fresh_ttl_seconds must be a non-negative finite number")
        self._provider = provider
        self._max_entries = max_entries
        self._fresh_ttl_seconds = float(fresh_ttl_seconds)
        self._clock = clock or (lambda: datetime.now(UTC))
        self._cache: OrderedDict[_EnvironmentCacheKey, _EnvironmentCacheEntry] = (
            OrderedDict()
        )
        self._cache_lock = RLock()

    @property
    def cache_size(self) -> int:
        with self._cache_lock:
            return len(self._cache)

    def observe(
        self,
        origin: Coordinate,
        candidates: Sequence[Coordinate],
        radius_m: float,
        *,
        include_obstacles: bool,
        include_elevation: bool,
        include_water: bool = False,
    ) -> EnvironmentSnapshot:
        cache_radius_m = _cache_radius(radius_m)
        key = _cache_key(
            origin,
            candidates,
            cache_radius_m,
            include_obstacles=include_obstacles,
            include_elevation=include_elevation,
            include_water=include_water,
        )
        now = _utc_datetime(self._clock())
        with self._cache_lock:
            entry = self._cache.get(key)
            if entry is not None:
                self._cache.move_to_end(key)
                age_seconds = (now - entry.stored_at).total_seconds()
                if age_seconds < self._fresh_ttl_seconds:
                    return _cached_snapshot(entry.snapshot, "fresh")

        try:
            snapshot = self._observe_upstream(
                origin,
                candidates,
                cache_radius_m,
                include_obstacles=include_obstacles,
                include_elevation=include_elevation,
                include_water=include_water,
            )
            snapshot = _normalise_snapshot(snapshot)
        except (
            ContextAnalysisUnavailable,
            httpx.HTTPError,
            OSError,
            TimeoutError,
            ValueError,
        ):
            if entry is not None:
                return _cached_snapshot(entry.snapshot, "stale")
            raise ContextAnalysisUnavailable from None

        stored_at = _utc_datetime(self._clock())
        with self._cache_lock:
            self._cache[key] = _EnvironmentCacheEntry(snapshot, stored_at)
            self._cache.move_to_end(key)
            while len(self._cache) > self._max_entries:
                self._cache.popitem(last=False)
        return snapshot

    def _observe_upstream(
        self,
        origin: Coordinate,
        candidates: Sequence[Coordinate],
        radius_m: float,
        *,
        include_obstacles: bool,
        include_elevation: bool,
        include_water: bool,
    ) -> EnvironmentSnapshot:
        kwargs: dict[str, Any] = {
            "include_obstacles": include_obstacles,
            "include_elevation": include_elevation,
        }
        # Omitting the optional keyword preserves compatibility with existing
        # third-party/test providers that implement the original interface.
        if include_water:
            kwargs["include_water"] = True
        return self._provider.observe(origin, candidates, radius_m, **kwargs)

    def close(self) -> None:
        self._provider.close()


def _cache_key(
    origin: Coordinate,
    candidates: Sequence[Coordinate],
    radius_m: float,
    *,
    include_obstacles: bool,
    include_elevation: bool,
    include_water: bool,
) -> _EnvironmentCacheKey:
    _validate_radius(radius_m)
    if len(candidates) > MAX_ELEVATION_POINTS:
        raise ContextAnalysisUnavailable
    return _EnvironmentCacheKey(
        origin_cell=_coarse_cell(origin),
        candidate_cells=tuple(_coarse_cell(candidate) for candidate in candidates),
        radius_bucket=ceil(radius_m / COARSE_CACHE_RADIUS_BUCKET_M),
        include_obstacles=include_obstacles,
        include_elevation=include_elevation,
        include_water=include_water,
    )


def _cache_radius(radius_m: float) -> float:
    _validate_radius(radius_m)
    return min(
        MAX_ENVIRONMENT_RADIUS_M,
        ceil(radius_m / COARSE_CACHE_RADIUS_BUCKET_M) * COARSE_CACHE_RADIUS_BUCKET_M,
    )


def _cached_snapshot(
    snapshot: EnvironmentSnapshot, status: Literal["fresh", "stale"]
) -> EnvironmentSnapshot:
    timestamp = _utc_datetime(snapshot.observed_at)
    if status == "fresh":
        return replace(
            snapshot,
            observed_at=timestamp,
            cache_status="fresh",
            source=f"{snapshot.source}; coarse-area cache hit",
            uncertainty_notice=_append_notice(
                snapshot.uncertainty_notice,
                "Using a cached coarse-area observation; its source timestamp "
                f"remains {timestamp.isoformat()}.",
            ),
        )
    return replace(
        snapshot,
        observed_at=timestamp,
        cache_status="stale",
        source=f"{snapshot.source}; stale coarse-area cache fallback",
        uncertainty_notice=_append_notice(
            snapshot.uncertainty_notice,
            "The live environment provider failed, so this stale cached "
            "observation is being shown from "
            f"{timestamp.isoformat()}; mapped conditions may have changed.",
        ),
    )


def _normalise_snapshot(snapshot: EnvironmentSnapshot) -> EnvironmentSnapshot:
    if not isinstance(snapshot, EnvironmentSnapshot):
        raise ContextAnalysisUnavailable
    return replace(
        snapshot,
        observed_at=_utc_datetime(snapshot.observed_at),
        cache_status="live",
    )


def _append_notice(existing: str, addition: str) -> str:
    return f"{existing.strip()} {addition}".strip()


def _elevation_source(url: str) -> str:
    if url.rstrip("/") == DEFAULT_ELEVATION_API_URL.rstrip("/"):
        return "OpenTopoData"
    return "Configured elevation provider"


def _coarse_cell(coordinate: Coordinate) -> tuple[int, int]:
    return (
        floor(coordinate.latitude / COARSE_CACHE_GRID_DEGREES),
        floor(coordinate.longitude / COARSE_CACHE_GRID_DEGREES),
    )


def _validate_radius(radius_m: float) -> None:
    if (
        isinstance(radius_m, bool)
        or not isinstance(radius_m, (int, float))
        or not isfinite(float(radius_m))
        or radius_m <= 0
        or radius_m > MAX_ENVIRONMENT_RADIUS_M
    ):
        raise ContextAnalysisUnavailable


def _utc_datetime(value: datetime) -> datetime:
    if value.tzinfo is None or value.utcoffset() is None:
        raise ContextAnalysisUnavailable
    return value.astimezone(UTC)


def _element_tags(element: Mapping[str, Any]) -> dict[str, Any]:
    tags = element.get("tags")
    if not isinstance(tags, Mapping):
        return {}
    return {str(key): value for key, value in tags.items()}


def _feature_kwargs(
    element: Mapping[str, Any],
    tags: Mapping[str, Any],
    points: tuple[Point, ...],
    geometry_complete: bool,
) -> dict[str, Any]:
    return {
        "name": _tag_text(tags, "name") or _tag_text(tags, "name:en"),
        "access": _tag_text(tags, "access"),
        "indoor": _tag_text(tags, "indoor"),
        "covered": _tag_text(tags, "covered"),
        "osm_type": _tag_text(element, "type"),
        "osm_id": _element_id(element),
        "geometry_complete": geometry_complete,
    }


def _element_points(element: Mapping[str, Any]) -> tuple[tuple[Point, ...], bool]:
    geometry = element.get("geometry")
    if not geometry:
        geometry = element.get("members")
    points, complete = _geometry_points(geometry)
    if points:
        return points, complete

    if _valid_coordinate(element.get("lat"), element.get("lon")):
        return (
            ((float(element["lon"]), float(element["lat"])),),
            True if geometry is None else complete,
        )

    center = element.get("center")
    if isinstance(center, Mapping) and _valid_coordinate(
        center.get("lat"), center.get("lon")
    ):
        # Center data is retained only as an explicitly incomplete fallback.
        return ((float(center["lon"]), float(center["lat"])),), False
    return (), False


def _geometry_points(value: Any) -> tuple[tuple[Point, ...], bool]:
    points: list[Point] = []
    complete = True

    def collect(item: Any) -> None:
        nonlocal complete
        if isinstance(item, Mapping):
            if "lat" in item or "lon" in item:
                if _valid_coordinate(item.get("lat"), item.get("lon")):
                    point = (float(item["lon"]), float(item["lat"]))
                    if not points or point != points[-1]:
                        points.append(point)
                else:
                    complete = False
                return
            nested = False
            for key in ("geometry", "members"):
                if key in item:
                    nested = True
                    collect(item[key])
            if not nested:
                complete = False
            return
        if isinstance(item, list):
            for child in item:
                collect(child)
            return
        complete = False

    if value is None:
        return (), False
    collect(value)
    return tuple(points), complete


def _element_id(element: Mapping[str, Any]) -> int | None:
    identifier = element.get("id")
    if (
        isinstance(identifier, int)
        and not isinstance(identifier, bool)
        and identifier > 0
    ):
        return identifier
    return None


def _tag_text(tags: Mapping[str, Any], key: str) -> str | None:
    value = tags.get(key)
    if not isinstance(value, str):
        return None
    value = value.strip()
    if not value:
        return None
    return value[:200]


def _is_recognized_element(tags: Mapping[str, Any]) -> bool:
    return (
        "building" in tags
        or _is_open_space(tags)
        or tags.get("natural") == "tree"
        or _is_wooded_area(tags)
        or ("power" in tags and _tag_text(tags, "power") is not None)
        or _is_water_feature(tags)
    )


def _is_open_space(tags: Mapping[str, Any]) -> bool:
    return (
        _tag_text(tags, "leisure")
        in {
            "common",
            "garden",
            "golf_course",
            "park",
            "pitch",
            "playground",
            "recreation_ground",
            "sports_centre",
            "sports_hall",
            "stadium",
            "track",
        }
        or _tag_text(tags, "place") == "square"
        or _tag_text(tags, "emergency") == "assembly_point"
        or _tag_text(tags, "amenity") == "assembly_point"
        or _tag_text(tags, "assembly_point") in {"designated", "yes"}
    )


def _open_space_type(tags: Mapping[str, Any]) -> str:
    return _tag_text(tags, "leisure") or _tag_text(tags, "place") or "assembly_point"


def _is_wooded_area(tags: Mapping[str, Any]) -> bool:
    return (
        _tag_text(tags, "natural") in {"heath", "scrub", "tree_row", "wood"}
        or _tag_text(tags, "landuse") == "forest"
    )


def _wooded_area_type(tags: Mapping[str, Any]) -> str:
    return _tag_text(tags, "natural") or _tag_text(tags, "landuse") or "wooded_area"


def _is_water_feature(tags: Mapping[str, Any]) -> bool:
    return (
        _tag_text(tags, "natural") in {"water", "wetland"}
        or _tag_text(tags, "waterway") is not None
        or _tag_text(tags, "landuse") in {"basin", "reservoir", "salt_pond"}
    )


def _is_area_geometry(tags: Mapping[str, Any]) -> bool:
    if "building" in tags or _is_open_space(tags) or _is_wooded_area(tags):
        return True
    if _is_water_feature(tags):
        return _tag_text(tags, "waterway") is None
    return _tag_text(tags, "power") in {
        "plant",
        "substation",
        "transformer",
    }


def _water_feature_type(tags: Mapping[str, Any]) -> str:
    if _tag_text(tags, "waterway") is not None:
        return f"waterway:{_tag_text(tags, 'waterway')}"
    return _tag_text(tags, "water") or _tag_text(tags, "natural") or "water_body"


def _building_height_m(tags: Mapping[str, Any]) -> float | None:
    height_value = tags.get("height")
    height = _measurement_m(height_value)
    if height is not None:
        return height
    levels = _number(tags.get("building:levels"))
    if levels is not None and levels > 0:
        return levels * 3.0
    if _tag_text(tags, "building") in {"apartments", "highrise", "tower"}:
        return HIGH_BUILDING_HEIGHT_M
    return None


def _measurement_m(value: Any) -> float | None:
    number = _number(value)
    if number is None:
        return None
    if isinstance(value, str) and any(
        unit in value.casefold() for unit in ("ft", "feet", "'")
    ):
        number *= 0.3048
    return number if number > 0 else None


def _number(value: Any) -> float | None:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        number = float(value)
        return number if isfinite(number) else None
    if not isinstance(value, str):
        return None
    match = search(r"[-+]?\d+(?:\.\d+)?", value)
    if match is None:
        return None
    number = float(match.group())
    return number if isfinite(number) else None


def _polygon_area_m2(points: Sequence[Point]) -> float | None:
    if len(points) < 3:
        return None
    mean_latitude = sum(point[1] for point in points) / len(points)
    scale_x = 111_320.0 * cos(radians(mean_latitude))
    scale_y = 110_540.0
    area = 0.0
    for first, second in zip(points, (*points[1:], points[0]), strict=False):
        first_x, first_y = first[0] * scale_x, first[1] * scale_y
        second_x, second_y = second[0] * scale_x, second[1] * scale_y
        area += first_x * second_y - second_x * first_y
    area = abs(area) / 2.0
    return area if isfinite(area) and area > 0 else None


def _valid_coordinate(latitude: Any, longitude: Any) -> bool:
    return (
        isinstance(latitude, (int, float))
        and not isinstance(latitude, bool)
        and isfinite(float(latitude))
        and -90 <= latitude <= 90
        and isinstance(longitude, (int, float))
        and not isinstance(longitude, bool)
        and isfinite(float(longitude))
        and -180 <= longitude <= 180
    )
