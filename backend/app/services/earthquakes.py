from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Literal

from sqlalchemy.orm import Session

from app.models.earthquake import Earthquake
from app.providers.usgs.client import ProviderClientError, UsgsClient
from app.providers.usgs.models import NormalizationResult
from app.providers.usgs.normalizer import InvalidProviderPayload
from app.repositories.earthquakes import EarthquakeRepository, ProviderSyncRepository

PROVIDER = "usgs"
SAFE_PROVIDER_ERROR_CODES = {
    "provider_timeout",
    "provider_unavailable",
    "invalid_provider_payload",
}


class LiveDataUnavailable(Exception):
    code = "live_data_unavailable"

    def __init__(self) -> None:
        super().__init__(self.code)


@dataclass(frozen=True, slots=True)
class AlertCollection:
    items: tuple[Earthquake, ...]
    data_status: Literal["current", "stale"]
    last_successful_refresh_at: datetime


class EarthquakeService:
    def __init__(
        self,
        client: UsgsClient,
        earthquake_repository: EarthquakeRepository,
        provider_sync_repository: ProviderSyncRepository,
        normalizer: Callable[[dict[str, object], datetime], NormalizationResult],
        refresh_minimum_seconds: int,
        current_max_age_seconds: int,
    ) -> None:
        self._client = client
        self._earthquakes = earthquake_repository
        self._provider_sync = provider_sync_repository
        self._normalizer = normalizer
        self._refresh_minimum = timedelta(seconds=refresh_minimum_seconds)
        self._current_max_age = timedelta(seconds=current_max_age_seconds)

    def list_alerts(self, session: Session, now: datetime) -> AlertCollection:
        if now.tzinfo is None or now.utcoffset() is None:
            raise ValueError("now must be timezone-aware")
        now = now.astimezone(UTC)

        sync = self._provider_sync.get(session, PROVIDER)
        if sync is None or now - sync.last_attempt_at >= self._refresh_minimum:
            self._provider_sync.acquire_refresh_lock(session, PROVIDER)
            sync = self._provider_sync.get(session, PROVIDER, refresh=True)
            if sync is None or now - sync.last_attempt_at >= self._refresh_minimum:
                self._refresh(session, now)

        items = tuple(self._earthquakes.list_recent(session, PROVIDER))
        sync = self._provider_sync.get(session, PROVIDER)
        if sync is None or sync.last_successful_refresh_at is None:
            raise LiveDataUnavailable

        successful_at = sync.last_successful_refresh_at.astimezone(UTC)
        age = now - successful_at
        data_status: Literal["current", "stale"] = (
            "current" if age <= self._current_max_age else "stale"
        )
        return AlertCollection(items, data_status, successful_at)

    def get_alert(self, session: Session, alert_id: str) -> Earthquake | None:
        return self._earthquakes.get(session, PROVIDER, alert_id)

    def _refresh(self, session: Session, attempted_at: datetime) -> None:
        self._provider_sync.record_attempt(session, PROVIDER, attempted_at, None)
        try:
            payload, retrieved_at = self._client.fetch()
            result = self._normalizer(payload, retrieved_at)
        except ProviderClientError as error:
            code = (
                error.code
                if error.code in SAFE_PROVIDER_ERROR_CODES
                else "provider_unavailable"
            )
            self._provider_sync.record_attempt(session, PROVIDER, attempted_at, code)
            return
        except InvalidProviderPayload:
            self._provider_sync.record_attempt(
                session, PROVIDER, attempted_at, "invalid_provider_payload"
            )
            return

        self._earthquakes.upsert_many(session, result.events)
        self._earthquakes.delete_absent(
            session,
            PROVIDER,
            {event.provider_event_id for event in result.events},
        )
        self._provider_sync.record_success(
            session,
            PROVIDER,
            retrieved_at.astimezone(UTC),
            attempted_at=attempted_at,
        )
