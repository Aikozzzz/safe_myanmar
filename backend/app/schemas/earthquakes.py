from dataclasses import dataclass
from datetime import datetime
from typing import Literal


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
