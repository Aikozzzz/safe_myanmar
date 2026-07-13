from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def test_api_image_contains_alembic_configuration_and_migrations():
    dockerfile = (ROOT / "backend" / "Dockerfile").read_text(encoding="utf-8")

    assert "COPY alembic.ini ." in dockerfile
    assert "COPY alembic ./alembic" in dockerfile


def test_root_environment_example_matches_cross_layer_contract():
    expected = """API_BASE_URL=http://localhost:8000
DATABASE_URL=postgresql+psycopg://safemyanmar_dev:safemyanmar_dev_password@localhost:5432/safemyanmar
USGS_FEED_URL=https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson
ENVIRONMENT=development
# Future map increment only; unused by the current application:
MAPBOX_ACCESS_TOKEN=replace_when_map_feature_is_implemented
"""

    example = ROOT / ".env.example"
    assert example.is_file(), "root environment contract must exist"
    assert example.read_text(encoding="utf-8") == expected


def test_backend_environment_example_lists_only_consumed_settings():
    backend_example = (ROOT / "backend" / ".env.example").read_text(encoding="utf-8")

    assert "DATABASE_URL=" in backend_example
    assert "USGS_FEED_URL=" in backend_example
    assert "PROVIDER_TIMEOUT_SECONDS=10.0" in backend_example
    assert "REFRESH_MINIMUM_SECONDS=60" in backend_example
    assert "CURRENT_MAX_AGE_SECONDS=300" in backend_example
    assert "ENVIRONMENT=development" in backend_example
    assert "API_BASE_URL" not in backend_example
    assert "MAPBOX_ACCESS_TOKEN" not in backend_example


def test_integration_harness_waits_for_controlled_provider_before_api():
    harness = (ROOT / "tools" / "run-live-alerts-integration.ps1").read_text(
        encoding="utf-8"
    )

    provider_ready = 'Wait-ForEndpoint "http://127.0.0.1:8001/feed"'
    api_start = "$api = Start-Process"
    assert provider_ready in harness
    assert harness.index(provider_ready) < harness.index(api_start)


def test_integration_harness_removes_dedicated_database_container():
    harness = (ROOT / "tools" / "run-live-alerts-integration.ps1").read_text(
        encoding="utf-8"
    )

    assert "docker compose --profile integration rm -f -s integration-db" in harness


def test_integration_harness_supports_configurable_emulator_and_physical_urls():
    harness = (ROOT / "tools" / "run-live-alerts-integration.ps1").read_text(
        encoding="utf-8"
    )

    assert "[string]$ApiBaseUrl" in harness
    assert '"http://10.0.2.2:8000"' in harness
    assert '"http://127.0.0.1:8000"' in harness
    assert "reverse tcp:8000 tcp:8000" in harness
    assert "--dart-define=API_BASE_URL=$ApiBaseUrl" in harness


def test_integration_harness_restores_process_environment():
    harness = (ROOT / "tools" / "run-live-alerts-integration.ps1").read_text(
        encoding="utf-8"
    )

    for name in ("PATH", "DATABASE_URL", "USGS_FEED_URL"):
        assert f"$original{name.title().replace('_', '')}Exists" in harness
        assert f"$original{name.title().replace('_', '')}Value" in harness
        assert f'Restore-EnvironmentVariable "{name}"' in harness


def test_integration_harness_bounds_waits_and_validates_android_cleanup():
    harness = (ROOT / "tools" / "run-live-alerts-integration.ps1").read_text(
        encoding="utf-8"
    )

    assert "[int]$TimeoutSeconds" in harness
    assert "Stop-ChildProcess" in harness
    assert "pm clear org.safemyanmar.mobile" in harness
    assert '$clearOutput -ne "Success"' in harness
    assert "reverse --remove tcp:8000" in harness
    assert "$cleanupErrors" in harness
