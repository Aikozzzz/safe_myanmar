import json
from datetime import UTC, datetime

import pytest

from app.services.real_navigation_data import (
    NavigationSnapshotStale,
    YangonNavigationData,
)

RETRIEVED_AT = datetime(2026, 8, 17, 13, 42, tzinfo=UTC)


def write_snapshot(directory, shelters):
    directory.mkdir()
    (directory / "manifest.json").write_text(
        json.dumps(
            {
                "retrieved_at": RETRIEVED_AT.isoformat(),
                "validation_status": "passed",
            }
        ),
        encoding="utf-8",
    )
    (directory / "hazards.json").write_text("[]", encoding="utf-8")
    (directory / "shelters.json").write_text(json.dumps(shelters), encoding="utf-8")


def shelter(identifier, is_stale):
    return {
        "id": identifier,
        "name": f"Shelter {identifier}",
        "latitude": 16.85,
        "longitude": 96.13,
        "address": "Test address",
        "source": "Test source",
        "is_stale": is_stale,
    }


def test_stale_shelters_are_not_exposed(tmp_path):
    write_snapshot(
        tmp_path / "snapshot",
        [shelter("fresh", False), shelter("stale", True), shelter("unknown", None)],
    )

    snapshot = YangonNavigationData.load(
        tmp_path / "snapshot",
        now=datetime(2026, 8, 18, tzinfo=UTC),
    )

    assert [item.id for item in snapshot.shelters] == ["fresh"]


def test_snapshot_older_than_runtime_policy_is_rejected(tmp_path):
    write_snapshot(tmp_path / "snapshot", [])

    with pytest.raises(NavigationSnapshotStale):
        YangonNavigationData.load(
            tmp_path / "snapshot",
            now=datetime(2026, 8, 18, tzinfo=UTC),
            max_age_seconds=60,
        )
