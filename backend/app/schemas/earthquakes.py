from dataclasses import dataclass
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict


@dataclass(frozen=True, slots=True)
class NormalizedEarthquake:
    id: str
    provider: Literal["usgs"]
    provider_event_id: str
    kind: Literal["earthquake_information"]
    title: str
    place: str
    magnitude: float
    depth_km: float
    latitude: float
    longitude: float
    event_at: datetime
    provider_updated_at: datetime
    retrieved_at: datetime
    review_status: str | None
    source_url: str
    version: int


class AlertItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    provider: Literal["usgs"]
    provider_event_id: str
    kind: Literal["earthquake_information"]
    title: str
    place: str
    magnitude: float
    depth_km: float
    latitude: float
    longitude: float
    event_at: datetime
    provider_updated_at: datetime
    retrieved_at: datetime
    review_status: str | None
    source_url: str
    version: int


class AlertListResponse(BaseModel):
    items: list[AlertItem]
    data_status: Literal["current", "stale"]
    last_successful_refresh_at: datetime
    provider: Literal["usgs"]
