import math
from datetime import UTC, datetime
from urllib.parse import urlparse

from app.providers.usgs.models import NormalizationResult
from app.schemas.earthquakes import NormalizedEarthquake

MIN_LATITUDE = 8.284
MAX_LATITUDE = 30.043
MIN_LONGITUDE = 90.689
MAX_LONGITUDE = 102.676
PROVIDER = "usgs"
KIND = "earthquake_information"


class InvalidProviderPayload(ValueError):
    pass


def normalize_feed(payload: object, retrieved_at: datetime) -> NormalizationResult:
    if retrieved_at.tzinfo is None or retrieved_at.utcoffset() is None:
        raise InvalidProviderPayload("retrieved_at must be timezone-aware")
    if (
        not isinstance(payload, dict)
        or payload.get("type") != "FeatureCollection"
        or not isinstance(payload.get("features"), list)
    ):
        raise InvalidProviderPayload("invalid USGS feature collection")

    normalized_retrieved_at = retrieved_at.astimezone(UTC)
    events: list[NormalizedEarthquake] = []
    rejected_count = 0
    for feature in payload["features"]:
        try:
            event = _normalize_feature(feature, normalized_retrieved_at)
        except (KeyError, TypeError, ValueError, OverflowError, OSError):
            rejected_count += 1
            continue
        if event is not None:
            events.append(event)

    return NormalizationResult(events=tuple(events), rejected_count=rejected_count)


def _normalize_feature(
    feature: object, retrieved_at: datetime
) -> NormalizedEarthquake | None:
    if not isinstance(feature, dict):
        raise ValueError("feature must be an object")

    provider_event_id = _non_empty_string(feature.get("id"))
    properties = feature.get("properties")
    geometry = feature.get("geometry")
    if not isinstance(properties, dict) or not isinstance(geometry, dict):
        raise ValueError("properties and geometry must be objects")
    if geometry.get("type") != "Point":
        raise ValueError("geometry must be a point")

    coordinates = geometry.get("coordinates")
    if not isinstance(coordinates, list) or len(coordinates) != 3:
        raise ValueError("point must have three coordinates")
    longitude, latitude, depth_km = map(_finite_number, coordinates)
    if not -180 <= longitude <= 180 or not -90 <= latitude <= 90:
        raise ValueError("coordinates are outside global ranges")

    magnitude = _finite_number(properties.get("mag"))
    event_at = _millisecond_datetime(properties.get("time"))
    provider_updated_at = _millisecond_datetime(properties.get("updated"))
    title = _non_empty_string(properties.get("title"))
    place = _non_empty_string(properties.get("place"))
    source_url = _usgs_url(properties.get("url"))
    status = properties.get("status")
    if status is not None:
        status = _non_empty_string(status)

    if not (
        MIN_LONGITUDE <= longitude <= MAX_LONGITUDE
        and MIN_LATITUDE <= latitude <= MAX_LATITUDE
    ):
        return None

    return NormalizedEarthquake(
        id=f"{PROVIDER}:{provider_event_id}",
        provider=PROVIDER,
        provider_event_id=provider_event_id,
        kind=KIND,
        title=title,
        place=place,
        magnitude=magnitude,
        depth_km=depth_km,
        latitude=latitude,
        longitude=longitude,
        event_at=event_at,
        provider_updated_at=provider_updated_at,
        retrieved_at=retrieved_at,
        review_status=status,
        source_url=source_url,
        version=1,
    )


def _finite_number(value: object) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError("value must be numeric")
    number = float(value)
    if not math.isfinite(number):
        raise ValueError("value must be finite")
    return number


def _millisecond_datetime(value: object) -> datetime:
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValueError("timestamp must be an integer")
    return datetime.fromtimestamp(value / 1000, tz=UTC)


def _non_empty_string(value: object) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError("value must be a non-empty string")
    return value


def _usgs_url(value: object) -> str:
    url = _non_empty_string(value)
    parsed = urlparse(url)
    host = parsed.hostname
    if (
        parsed.scheme != "https"
        or host is None
        or not (host == "earthquake.usgs.gov" or host.endswith(".earthquake.usgs.gov"))
    ):
        raise ValueError("URL must use an approved USGS host")
    return url
