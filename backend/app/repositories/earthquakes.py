from collections.abc import Sequence
from datetime import datetime

from sqlalchemy import delete, select, text
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.models.earthquake import Earthquake
from app.models.provider_sync import ProviderSync
from app.schemas.earthquakes import NormalizedEarthquake

# Stable 64-bit key encoded from ASCII "SAFEUSGS"; never derive lock keys with hash().
USGS_REFRESH_ADVISORY_LOCK_KEY = 0x5341464555534753


class EarthquakeRepository:
    def upsert_many(
        self,
        session: Session,
        events: Sequence[NormalizedEarthquake],
    ) -> None:
        if not events:
            return

        values = [
            {
                "id": event.id,
                "provider": event.provider,
                "provider_event_id": event.provider_event_id,
                "kind": event.kind,
                "title": event.title,
                "place": event.place,
                "magnitude": event.magnitude,
                "depth_km": event.depth_km,
                "latitude": event.latitude,
                "longitude": event.longitude,
                "event_at": event.event_at,
                "provider_updated_at": event.provider_updated_at,
                "retrieved_at": event.retrieved_at,
                "review_status": event.review_status,
                "source_url": event.source_url,
                "version": event.version,
            }
            for event in events
        ]
        statement = insert(Earthquake).values(values)
        excluded = statement.excluded
        mutable_columns = (
            "kind",
            "title",
            "place",
            "magnitude",
            "depth_km",
            "latitude",
            "longitude",
            "event_at",
            "provider_updated_at",
            "retrieved_at",
            "review_status",
            "source_url",
            "version",
        )
        statement = statement.on_conflict_do_update(
            constraint="uq_earthquakes_provider_event",
            set_={column: getattr(excluded, column) for column in mutable_columns},
            where=excluded.provider_updated_at > Earthquake.provider_updated_at,
        )
        session.execute(statement)
        session.flush()

    def list_recent(self, session: Session, provider: str) -> list[Earthquake]:
        statement = (
            select(Earthquake)
            .where(Earthquake.provider == provider)
            .order_by(Earthquake.event_at.desc(), Earthquake.id)
        )
        return list(session.scalars(statement))

    def get(self, session: Session, provider: str, event_id: str) -> Earthquake | None:
        statement = select(Earthquake).where(
            Earthquake.provider == provider,
            Earthquake.id == event_id,
        )
        return session.scalar(statement)

    def delete_absent(
        self,
        session: Session,
        provider: str,
        retained_provider_event_ids: set[str],
    ) -> None:
        statement = delete(Earthquake).where(Earthquake.provider == provider)
        if retained_provider_event_ids:
            statement = statement.where(
                Earthquake.provider_event_id.not_in(retained_provider_event_ids)
            )
        session.execute(statement)
        session.flush()


class ProviderSyncRepository:
    def get(
        self, session: Session, provider: str, *, refresh: bool = False
    ) -> ProviderSync | None:
        return session.get(ProviderSync, provider, populate_existing=refresh)

    def acquire_refresh_lock(self, session: Session, provider: str) -> None:
        if provider != "usgs":
            raise ValueError("unsupported provider refresh lock")
        session.execute(
            text("SELECT pg_advisory_xact_lock(:lock_key)"),
            {"lock_key": USGS_REFRESH_ADVISORY_LOCK_KEY},
        )

    def record_attempt(
        self,
        session: Session,
        provider: str,
        attempted_at: datetime,
        error_code: str | None,
    ) -> ProviderSync:
        record = self.get(session, provider)
        if record is None:
            record = ProviderSync(
                provider=provider,
                last_attempt_at=attempted_at,
                last_successful_refresh_at=None,
                last_error_code=error_code,
            )
            session.add(record)
        else:
            record.last_attempt_at = attempted_at
            record.last_error_code = error_code
        session.flush()
        return record

    def record_success(
        self,
        session: Session,
        provider: str,
        succeeded_at: datetime,
        attempted_at: datetime | None = None,
    ) -> ProviderSync:
        attempted_at = attempted_at or succeeded_at
        record = self.get(session, provider)
        if record is None:
            record = ProviderSync(
                provider=provider,
                last_attempt_at=attempted_at,
                last_successful_refresh_at=succeeded_at,
                last_error_code=None,
            )
            session.add(record)
        else:
            record.last_attempt_at = attempted_at
            record.last_successful_refresh_at = succeeded_at
            record.last_error_code = None
        session.flush()
        return record
