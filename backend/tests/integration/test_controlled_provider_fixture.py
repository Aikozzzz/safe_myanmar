import importlib.util
import json
import threading
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

from app.providers.usgs.normalizer import normalize_feed
from app.schemas.earthquakes import AlertItem, AlertListResponse

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"
FEED_PATH = FIXTURES / "usgs_integration_feed.json"
SERVER_PATH = FIXTURES / "usgs_integration_server.py"
MOBILE_CONTRACT_PATH = (
    Path(__file__).resolve().parents[3]
    / "mobile"
    / "test"
    / "fixtures"
    / "live_alerts_response.json"
)


def test_controlled_provider_serves_fixture_and_switches_failure_mode():
    assert FEED_PATH.is_file(), "controlled integration feed must exist"
    assert SERVER_PATH.is_file(), "controlled integration server must exist"

    payload = json.loads(FEED_PATH.read_text(encoding="utf-8"))
    assert payload["type"] == "FeatureCollection"
    assert [feature["id"] for feature in payload["features"]] == [
        "integration-fixture-001"
    ]

    spec = importlib.util.spec_from_file_location(
        "usgs_integration_server", SERVER_PATH
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    server = module.create_server("127.0.0.1", 0, FEED_PATH)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    base_url = f"http://127.0.0.1:{server.server_port}"
    try:
        with urllib.request.urlopen(f"{base_url}/feed", timeout=2) as response:
            assert response.status == 200
            assert json.load(response)["features"][0]["id"] == (
                "integration-fixture-001"
            )

        request = urllib.request.Request(f"{base_url}/control/fail", method="POST")
        with urllib.request.urlopen(request, timeout=2) as response:
            assert response.status == 204
        try:
            urllib.request.urlopen(f"{base_url}/feed", timeout=2)
        except urllib.error.HTTPError as error:
            assert error.code == 503
        else:
            raise AssertionError("failure mode must return HTTP 503")

        request = urllib.request.Request(f"{base_url}/control/ok", method="POST")
        with urllib.request.urlopen(request, timeout=2) as response:
            assert response.status == 204
        with urllib.request.urlopen(f"{base_url}/feed", timeout=2) as response:
            assert response.status == 200
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)


def test_mobile_contract_fixture_is_an_exact_backend_response():
    assert MOBILE_CONTRACT_PATH.is_file(), "normalized mobile contract must exist"
    raw = json.loads(MOBILE_CONTRACT_PATH.read_text(encoding="utf-8"))
    provider_payload = json.loads(FEED_PATH.read_text(encoding="utf-8"))
    normalized = normalize_feed(
        provider_payload,
        datetime.fromisoformat(raw["last_successful_refresh_at"]),
    )
    response = AlertListResponse(
        items=[AlertItem.model_validate(event) for event in normalized.events],
        data_status="current",
        last_successful_refresh_at=datetime.fromisoformat(
            raw["last_successful_refresh_at"]
        ),
        provider="usgs",
    )

    assert response.model_dump(mode="json") == raw
    assert response.items[0].id == "usgs:integration-fixture-001"
