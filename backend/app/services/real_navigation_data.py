import json
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from app.schemas.navigation import (
    Coordinate,
    Hazard,
    HazardListResponse,
    PolygonGeometry,
    Shelter,
    ShelterListResponse,
)


@dataclass(frozen=True)
class YangonNavigationData:
    source: str
    retrieved_at: datetime
    shelters: tuple[Shelter, ...]
    hazards: tuple[Hazard, ...]
    uncertainty_notice: str

    @classmethod
    def load(cls, directory: Path) -> "YangonNavigationData":
        manifest = _read_json(directory / "manifest.json")
        if manifest.get("validation_status") != "passed":
            raise ValueError("The navigation data snapshot did not pass validation.")
        retrieved_at = _timestamp(manifest["retrieved_at"])
        hazards = _load_hazards(directory / "hazards.json", retrieved_at)
        shelters = _load_shelters(directory / "shelters.json", retrieved_at)
        return cls(
            source=f"SafeMyanmar Yangon snapshot {retrieved_at.date().isoformat()}",
            retrieved_at=retrieved_at,
            shelters=shelters,
            hazards=hazards,
            uncertainty_notice=(
                "Real Yangon data snapshot. No verified current shelter list or "
                "lower-exposure destination dataset was found. Nearby analysis "
                "requires a current hazard geometry for the selected disaster "
                "type; earthquake and flood analysis may additionally use mapped "
                "environment data. Current hazard records are informational, "
                "time-limited, and do not guarantee that any place or route is "
                "safe."
            ),
        )

    def shelter_response(self) -> ShelterListResponse:
        return ShelterListResponse(
            items=list(self.shelters),
            data_at=self.retrieved_at,
            source=self.source,
            simulation=False,
            uncertainty_notice=self.uncertainty_notice,
        )

    def hazard_response(self) -> HazardListResponse:
        return HazardListResponse(
            items=list(self.hazards),
            data_at=self.retrieved_at,
            source=self.source,
            simulation=False,
            uncertainty_notice=self.uncertainty_notice,
        )


def _load_shelters(path: Path, data_at: datetime) -> tuple[Shelter, ...]:
    records = _read_json(path)
    if not isinstance(records, list):
        raise ValueError("Shelter snapshot must be a JSON array.")
    shelters = []
    for record in records:
        if not isinstance(record, dict):
            raise ValueError("Shelter record must be an object.")
        shelters.append(
            Shelter(
                id=_string(record["id"]),
                name=_string(record["name"]),
                coordinate=Coordinate(
                    latitude=float(record["latitude"]),
                    longitude=float(record["longitude"]),
                ),
                description=_string(record.get("address", "")),
                source=_string(record["source"]),
                data_at=data_at,
                simulation=False,
            )
        )
    return tuple(shelters)


def _load_hazards(path: Path, data_at: datetime) -> tuple[Hazard, ...]:
    records = _read_json(path)
    if not isinstance(records, list):
        raise ValueError("Hazard snapshot must be a JSON array.")
    hazards = []
    for record in records:
        if not isinstance(record, dict) or record.get("is_stale") is not False:
            continue
        geometry = record.get("geometry")
        if not isinstance(geometry, dict):
            continue
        for index, rings in enumerate(_polygon_rings(geometry)):
            hazards.append(
                Hazard(
                    id=record["id"] if index == 0 else f"{record['id']}-{index}",
                    name=_string(record["name"]),
                    disaster_type=_string(record["hazard_type"]),
                    geometry=PolygonGeometry(coordinates=rings),
                    source=_string(record["source"]),
                    data_at=data_at,
                    simulation=False,
                )
            )
    return tuple(hazards)


def _polygon_rings(geometry: dict[str, Any]) -> list[list[tuple[float, float]]]:
    geometry_type = geometry.get("type")
    coordinates = geometry.get("coordinates")
    if geometry_type == "Polygon":
        polygons = [coordinates]
    elif geometry_type == "MultiPolygon":
        polygons = coordinates
    else:
        return []
    if not isinstance(polygons, list):
        return []
    result = []
    for polygon in polygons:
        if not isinstance(polygon, list) or not polygon:
            continue
        rings = []
        for ring in polygon:
            if not isinstance(ring, list) or len(ring) < 4:
                continue
            points: list[tuple[float, float]] = []
            for point in ring:
                if not isinstance(point, list) or len(point) < 2:
                    points = []
                    break
                points.append((float(point[0]), float(point[1])))
            if points and points[0] == points[-1]:
                rings.append(points)
        if rings:
            result.append(rings)
    return result


def _read_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def _timestamp(value: str) -> datetime:
    result = datetime.fromisoformat(value)
    if result.tzinfo is None or result.utcoffset() is None:
        raise ValueError("Snapshot timestamps must include a timezone.")
    return result.astimezone(UTC)


def _string(value: Any) -> str:
    if not isinstance(value, str) or not value:
        raise ValueError("Snapshot string fields must be non-empty strings.")
    return value
