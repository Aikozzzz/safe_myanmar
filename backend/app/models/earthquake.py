from datetime import datetime

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Double,
    FetchedValue,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base


class Earthquake(Base):
    __tablename__ = "earthquakes"
    __table_args__ = (
        UniqueConstraint(
            "provider", "provider_event_id", name="uq_earthquakes_provider_event"
        ),
        CheckConstraint(
            "latitude >= -90 AND latitude <= 90", name="ck_earthquakes_latitude"
        ),
        CheckConstraint(
            "longitude >= -180 AND longitude <= 180",
            name="ck_earthquakes_longitude",
        ),
        CheckConstraint("version > 0", name="ck_earthquakes_version_positive"),
    )

    id: Mapped[str] = mapped_column(String(255), primary_key=True)
    provider: Mapped[str] = mapped_column(String(32), nullable=False)
    provider_event_id: Mapped[str] = mapped_column(String(255), nullable=False)
    kind: Mapped[str] = mapped_column(String(64), nullable=False)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    place: Mapped[str] = mapped_column(String(500), nullable=False)
    magnitude: Mapped[float] = mapped_column(Double, nullable=False)
    depth_km: Mapped[float] = mapped_column(Double, nullable=False)
    latitude: Mapped[float] = mapped_column(Double, nullable=False)
    longitude: Mapped[float] = mapped_column(Double, nullable=False)
    event_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, index=True
    )
    provider_updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, index=True
    )
    retrieved_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    review_status: Mapped[str | None] = mapped_column(String(64), nullable=True)
    source_url: Mapped[str] = mapped_column(Text, nullable=False)
    version: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        server_onupdate=FetchedValue(),
    )
