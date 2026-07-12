"""Create earthquake cache and provider refresh metadata."""

import sqlalchemy as sa

from alembic import op

revision = "0001_earthquake_cache"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "earthquakes",
        sa.Column("id", sa.String(255), primary_key=True),
        sa.Column("provider", sa.String(32), nullable=False),
        sa.Column("provider_event_id", sa.String(255), nullable=False),
        sa.Column("kind", sa.String(64), nullable=False),
        sa.Column("title", sa.String(500), nullable=False),
        sa.Column("place", sa.String(500), nullable=False),
        sa.Column("magnitude", sa.Double(), nullable=False),
        sa.Column("depth_km", sa.Double(), nullable=False),
        sa.Column("latitude", sa.Double(), nullable=False),
        sa.Column("longitude", sa.Double(), nullable=False),
        sa.Column("event_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("provider_updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("retrieved_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("review_status", sa.String(64), nullable=True),
        sa.Column("source_url", sa.Text(), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.UniqueConstraint(
            "provider",
            "provider_event_id",
            name="uq_earthquakes_provider_event",
        ),
        sa.CheckConstraint(
            "latitude >= -90 AND latitude <= 90",
            name="ck_earthquakes_latitude",
        ),
        sa.CheckConstraint(
            "longitude >= -180 AND longitude <= 180",
            name="ck_earthquakes_longitude",
        ),
        sa.CheckConstraint("version > 0", name="ck_earthquakes_version_positive"),
    )
    op.create_index("ix_earthquakes_event_at", "earthquakes", ["event_at"])
    op.create_index(
        "ix_earthquakes_provider_updated_at",
        "earthquakes",
        ["provider_updated_at"],
    )
    op.create_table(
        "provider_sync",
        sa.Column("provider", sa.String(32), primary_key=True),
        sa.Column("last_attempt_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "last_successful_refresh_at", sa.DateTime(timezone=True), nullable=True
        ),
        sa.Column("last_error_code", sa.String(64), nullable=True),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )


def downgrade() -> None:
    op.drop_table("provider_sync")
    op.drop_index("ix_earthquakes_provider_updated_at", table_name="earthquakes")
    op.drop_index("ix_earthquakes_event_at", table_name="earthquakes")
    op.drop_table("earthquakes")
