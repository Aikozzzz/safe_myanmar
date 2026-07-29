from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def test_api_image_contains_alembic_configuration_and_migrations():
    dockerfile = (ROOT / "backend" / "Dockerfile").read_text(encoding="utf-8")

    assert "COPY alembic.ini ." in dockerfile
    assert "COPY alembic ./alembic" in dockerfile


def test_root_environment_example_matches_cross_layer_contract():
    expected = (
        "# Flutter compile-time contract. Flutter does not load this file; pass "
        "these as\n"
        "# --dart-define values. The public Mapbox token is embedded in the app "
        "and is not\n"
        "# a secret; restrict it by application/package and allowed APIs.\n"
        "API_BASE_URL=http://localhost:8000\n"
        "MAPBOX_PUBLIC_ACCESS_TOKEN=pk.replace_with_restricted_public_token\n"
        "\n"
        "# Backend runtime contract. Copy backend/.env.example to backend/.env.\n"
        "DATABASE_URL=postgresql+psycopg://safemyanmar_dev:"
        "safemyanmar_dev_password@localhost:5432/safemyanmar\n"
        "ENVIRONMENT=development\n"
        "USGS_FEED_URL=https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/"
        "all_day.geojson\n"
        "PROVIDER_TIMEOUT_SECONDS=10.0\n"
        "REFRESH_MINIMUM_SECONDS=60\n"
        "CURRENT_MAX_AGE_SECONDS=300\n"
        "ENABLE_SIMULATION_DATA=false\n"
        "# Optional backend secret. Required only for route suggestions when "
        "simulation\n"
        "# data is enabled. Never pass this token to Flutter.\n"
        "MAPBOX_DIRECTIONS_ACCESS_TOKEN=\n"
    )

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
    assert "ENABLE_SIMULATION_DATA=false" in backend_example
    assert "MAPBOX_DIRECTIONS_ACCESS_TOKEN=" in backend_example
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

    assert (
        'Arguments @("compose", "--profile", "integration", "rm", "-f", "-s", '
        '"integration-db")' in harness
    )


def test_integration_harness_supports_configurable_emulator_and_physical_urls():
    harness = (ROOT / "tools" / "run-live-alerts-integration.ps1").read_text(
        encoding="utf-8"
    )

    assert "[string]$ApiBaseUrl" in harness
    assert '"http://10.0.2.2:8000"' in harness
    assert '"http://127.0.0.1:8000"' in harness
    assert '"reverse", "tcp:$devicePort", "tcp:8000"' in harness
    assert "--dart-define=API_BASE_URL=$ApiBaseUrl" in harness


def test_integration_harness_restores_process_environment():
    harness = (ROOT / "tools" / "run-live-alerts-integration.ps1").read_text(
        encoding="utf-8"
    )

    for name in (
        "PATH",
        "DATABASE_URL",
        "USGS_FEED_URL",
        "ENVIRONMENT",
        "CURRENT_MAX_AGE_SECONDS",
        "REFRESH_MINIMUM_SECONDS",
        "PROVIDER_TIMEOUT_SECONDS",
    ):
        assert f"$original{name.title().replace('_', '')}Exists" in harness
        assert f"$original{name.title().replace('_', '')}Value" in harness
        assert f'Restore-EnvironmentVariable "{name}"' in harness


def test_integration_harness_overrides_inherited_runtime_settings():
    harness = (ROOT / "tools" / "run-live-alerts-integration.ps1").read_text(
        encoding="utf-8"
    )

    expected = {
        "ENVIRONMENT": "test",
        "CURRENT_MAX_AGE_SECONDS": "300",
        "REFRESH_MINIMUM_SECONDS": "60",
        "PROVIDER_TIMEOUT_SECONDS": "10.0",
    }
    for name, value in expected.items():
        assignment = f'$env:{name} = "{value}"'
        assert assignment in harness
        assert harness.index(assignment) < harness.index("$api = Start-Process")


def test_integration_harness_restricts_api_url_to_orchestrated_local_api():
    harness = (ROOT / "tools" / "run-live-alerts-integration.ps1").read_text(
        encoding="utf-8"
    )

    assert '$ApiBaseUrl -cne "http://10.0.2.2:8000"' in harness
    assert "127\\.0\\.0\\.1|localhost" in harness
    assert "(?<port>[0-9]{1,5})" in harness
    assert "$devicePort -lt 1 -or $devicePort -gt 65535" in harness
    assert '"tcp:$devicePort"' in harness
    assert '"tcp:8000"' in harness
    assert "https://" not in harness


def test_integration_harness_bounds_native_adb_and_cleanup_commands():
    harness = (ROOT / "tools" / "run-live-alerts-integration.ps1").read_text(
        encoding="utf-8"
    )

    assert "function Invoke-NativeCommand" in harness
    assert "$null = $process.Handle" in harness
    assert ".WaitForExit($TimeoutMilliseconds)" in harness
    assert ".Kill()" in harness
    assert "Native command timed out" in harness
    assert harness.count("Invoke-NativeCommand") >= 8
    assert "pm clear org.safemyanmar.mobile" not in harness
    assert "reverse --remove tcp:8000" not in harness
    assert (
        'Arguments @("compose", "--profile", "integration", "rm", "-f", "-s", '
        '"integration-db")' in harness
    )


def test_architecture_distinguishes_debug_device_transport_from_release_https():
    architecture = (
        ROOT / "docs" / "architecture" / "live-earthquake-slice.md"
    ).read_text(encoding="utf-8")

    assert "`10.0.2.2:8000`" in architecture
    assert "`localhost`" in architecture
    assert "`127.0.0.1`" in architecture
    assert "`adb reverse`" in architecture
    assert "Release API endpoints must use HTTPS" in architecture


def test_integration_harness_bounds_waits_and_validates_android_cleanup():
    harness = (ROOT / "tools" / "run-live-alerts-integration.ps1").read_text(
        encoding="utf-8"
    )

    assert "[int]$TimeoutSeconds" in harness
    assert "Stop-ChildProcess" in harness
    assert '"shell", "pm", "clear", "org.safemyanmar.mobile"' in harness
    assert '$clearOutput -ne "Success"' in harness
    assert '"reverse", "--remove", "tcp:$devicePort"' in harness
    assert "$cleanupErrors" in harness
