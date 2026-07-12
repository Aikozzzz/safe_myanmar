from dataclasses import dataclass

from app.schemas.earthquakes import NormalizedEarthquake


@dataclass(frozen=True, slots=True)
class NormalizationResult:
    events: tuple[NormalizedEarthquake, ...]
    rejected_count: int
