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
    source: Literal["SafeMyanmar Demo"] = "SafeMyanmar Demo"
    data_at: datetime
    simulation: Literal[True] = True


class ShelterListResponse(ExactModel):
    items: list[Shelter]
    data_at: datetime
    source: Literal["SafeMyanmar Demo"] = "SafeMyanmar Demo"
    simulation: Literal[True] = True
    uncertainty_notice: str


class Hazard(ExactModel):
    id: str
    name: str
    disaster_type: DisasterType
    geometry: PolygonGeometry
    source: Literal["SafeMyanmar Demo"] = "SafeMyanmar Demo"
    data_at: datetime
    simulation: Literal[True] = True


class HazardListResponse(ExactModel):
    items: list[Hazard]
    data_at: datetime
    source: Literal["SafeMyanmar Demo"] = "SafeMyanmar Demo"
    simulation: Literal[True] = True
    uncertainty_notice: str


class RouteSuggestionRequest(ExactModel):
    origin: Coordinate
    shelter_id: str = Field(min_length=1, max_length=100)
    disaster_type: DisasterType
    profile: RouteProfile | None = None


class RouteOption(ExactModel):
    id: str
    generated_at: datetime
    hazard_data_at: datetime
    profile: RouteProfile
    source: Literal["SafeMyanmar Demo"] = "SafeMyanmar Demo"
    directions_provider: Literal["Mapbox Directions"] = "Mapbox Directions"
    simulation: Literal[True] = True
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
    source: Literal["SafeMyanmar Demo"] = "SafeMyanmar Demo"
    directions_provider: Literal["Mapbox Directions"] = "Mapbox Directions"
    simulation: Literal[True] = True
    uncertainty_notice: str
