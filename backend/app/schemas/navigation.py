from datetime import datetime
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field

Latitude = Annotated[float, Field(strict=True, ge=-90.0, le=90.0, allow_inf_nan=False)]
Longitude = Annotated[
    float, Field(strict=True, ge=-180.0, le=180.0, allow_inf_nan=False)
]
CoordinatePair = tuple[Longitude, Latitude]
DisasterType = Literal[
    "earthquake",
    "flood",
    "fire",
    "cyclone",
    "landslide",
    "severe_weather",
]
RouteProfile = Literal["walking", "driving"]
ContextScenario = Literal["outdoors_after_shaking", "general"]


class ExactModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class Coordinate(ExactModel):
    latitude: Latitude
    longitude: Longitude


class PolygonGeometry(ExactModel):
    type: Literal["Polygon"] = "Polygon"
    coordinates: Annotated[list[list[CoordinatePair]], Field(min_length=1)]


class LineStringGeometry(ExactModel):
    type: Literal["LineString"] = "LineString"
    coordinates: Annotated[list[CoordinatePair], Field(min_length=2)]


class Shelter(ExactModel):
    id: str
    name: str
    coordinate: Coordinate
    description: str
    source: str = "SafeMyanmar Demo"
    data_at: datetime
    simulation: bool = True


class ShelterListResponse(ExactModel):
    items: list[Shelter]
    data_at: datetime
    source: str = "SafeMyanmar Demo"
    simulation: bool = True
    uncertainty_notice: str


class ContextAreaRequest(ExactModel):
    origin: Coordinate
    disaster_type: DisasterType
    scenario: ContextScenario = "general"
    search_radius_m: float = Field(default=1000.0, ge=250.0, le=1500.0)


class ContextMetrics(ExactModel):
    building_clearance_m: float = Field(ge=0, allow_inf_nan=False)
    tree_clearance_m: float = Field(ge=0, allow_inf_nan=False)
    relative_elevation_m: float = Field(allow_inf_nan=False)
    building_density: float = Field(ge=0, le=1, allow_inf_nan=False)
    tree_density: float = Field(ge=0, le=1, allow_inf_nan=False)
    hazard_intersections: int = Field(ge=0)


class ContextArea(ExactModel):
    id: str = Field(min_length=1, max_length=150)
    name: str
    coordinate: Coordinate
    disaster_type: DisasterType
    scenario: ContextScenario
    classification: Literal["lower_exposure"] = "lower_exposure"
    distance_m: float = Field(ge=0, allow_inf_nan=False)
    metrics: ContextMetrics
    rationale: list[str] = Field(min_length=1, max_length=6)
    source: str = "SafeMyanmar Demo"
    data_at: datetime
    simulation: bool = True
    uncertainty_notice: str


class ContextAreaListResponse(ExactModel):
    items: list[ContextArea]
    data_at: datetime
    source: str = "SafeMyanmar Demo"
    simulation: bool = True
    uncertainty_notice: str


class Hazard(ExactModel):
    id: str
    name: str
    disaster_type: DisasterType
    geometry: PolygonGeometry
    source: str = "SafeMyanmar Demo"
    data_at: datetime
    simulation: bool = True


class HazardListResponse(ExactModel):
    items: list[Hazard]
    data_at: datetime
    source: str = "SafeMyanmar Demo"
    simulation: bool = True
    uncertainty_notice: str


class RouteSuggestionRequest(ExactModel):
    origin: Coordinate
    # Context-area identifiers use the same transport field for compatibility
    # with clients that already send a required shelter_id.
    shelter_id: str = Field(min_length=1, max_length=150)
    context_area_id: str | None = Field(default=None, min_length=1, max_length=150)
    disaster_type: DisasterType
    scenario: ContextScenario = "general"
    search_radius_m: float = Field(default=1000.0, ge=250.0, le=1500.0)
    profile: RouteProfile | None = None


class RouteOption(ExactModel):
    id: str
    generated_at: datetime
    hazard_data_at: datetime
    profile: RouteProfile
    source: str = "SafeMyanmar Demo"
    directions_provider: Literal["Mapbox Directions"] = "Mapbox Directions"
    simulation: bool = True
    geometry: LineStringGeometry
    distance_m: float = Field(ge=0, allow_inf_nan=False)
    duration_seconds: float = Field(ge=0, allow_inf_nan=False)
    hazard_intersection_count: int = Field(ge=0)
    rationale: str
    recommended: bool
    uncertainty_notice: str


class RouteSuggestionsResponse(ExactModel):
    options: list[RouteOption]
    generated_at: datetime
    hazard_data_at: datetime
    profile: RouteProfile
    profile_selection_reason: str
    source: str = "SafeMyanmar Demo"
    directions_provider: Literal["Mapbox Directions"] = "Mapbox Directions"
    simulation: bool = True
    uncertainty_notice: str
