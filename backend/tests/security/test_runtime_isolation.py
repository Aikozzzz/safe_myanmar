import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RUNTIME_ROOTS = (ROOT / "backend" / "app", ROOT / "mobile" / "lib")


def runtime_text() -> str:
    files = [
        path
        for root in RUNTIME_ROOTS
        for path in root.rglob("*")
        if path.suffix in {".py", ".dart"}
    ]
    return "\n".join(path.read_text(encoding="utf-8") for path in files)


def test_runtime_has_no_integration_fixture_or_test_server_references():
    text = runtime_text().lower()

    assert "integration-fixture" not in text
    assert "usgs_integration_server" not in text
    assert "tests/fixtures" not in text
    assert "localhost:8001" not in text


def test_runtime_simulation_data_is_explicitly_gated_and_attributed():
    text = runtime_text()

    assert "MAPBOX_ACCESS_TOKEN" not in text
    assert "mapbox_directions_access_token" in text
    assert "enable_simulation_data" in text
    assert "SafeMyanmar Demo" in text
    assert "SIMULATION:" in text
    assert "https://api.mapbox.com/directions/v5/mapbox" in text


def test_runtime_backend_default_is_only_the_live_usgs_catalog():
    config = (ROOT / "backend" / "app" / "core" / "config.py").read_text(
        encoding="utf-8"
    )

    assert "https://earthquake.usgs.gov/fdsnws/event/1/query" in config
    assert "usgs_lookback_days: int = 3650" in config
    assert "integration" not in config.lower()


def test_real_env_files_are_ignored_and_untracked():
    ignored = subprocess.run(
        ["git", "check-ignore", ".env", "backend/.env"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    tracked = subprocess.run(
        ["git", "ls-files", "*.env", "**/.env"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )

    assert set(ignored.stdout.splitlines()) == {".env", "backend/.env"}
    assert tracked.stdout.strip() == ""
