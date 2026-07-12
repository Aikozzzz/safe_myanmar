# Task 5 Report

## Status

Complete. The versioned alert list/detail API exposes only persisted normalized
USGS earthquake information, owns request transactions, reconciles successful
provider snapshots, and retains prior data on provider failure.

## Files

- `README.md`
- `backend/app/api/health.py`
- `backend/app/api/v1/__init__.py`
- `backend/app/api/v1/alerts.py`
- `backend/app/api/v1/router.py`
- `backend/app/database/session.py`
- `backend/app/main.py`
- `backend/app/repositories/earthquakes.py`
- `backend/app/schemas/earthquakes.py`
- `backend/app/services/earthquakes.py`
- `backend/pyproject.toml`
- `backend/tests/api/test_alerts.py`
- `backend/tests/api/test_health.py`
- `backend/tests/integration/__init__.py`
- `backend/tests/integration/test_live_usgs_smoke.py`
- `backend/tests/repositories/test_earthquake_repository.py`
- `backend/tests/services/test_earthquake_service.py`

## RED Evidence

- API test collection failed with `ModuleNotFoundError: No module named
  'app.api.v1'` before the versioned API was implemented.
- Two repository reconciliation tests failed with missing
  `EarthquakeRepository.delete_absent`.
- Two service snapshot tests failed because absent USGS rows remained after a
  successful populated or empty snapshot.
- The runtime readiness reuse test failed because `get_readiness_checker` did
  not accept the request and constructed an independent engine.

## Verification

- `pytest backend/tests/api/test_alerts.py -v`: 9 passed.
- `pytest backend/tests -v`: 134 passed, 1 skipped (opt-in live test).
- Opt-in live USGS smoke: 1 passed against the dedicated test database.
- `ruff format --check backend`: 46 files already formatted.
- `ruff check backend`: all checks passed.
- `docker compose build api`: built `live-earthquake-api:latest` successfully.

## Commit

`feat: expose live earthquake alerts` (this report is included in that commit;
the hash is reported after Git creates it).

## Self-Review

- Public list and detail models contain only the required keys; neither
  severity nor item-level freshness is present.
- API IDs remain `usgs:<provider_event_id>` and UTC timestamps serialize with
  `Z`.
- List success and safe never-success metadata are committed by the route;
  unexpected failures roll back. Detail reads roll back and never refresh.
- Snapshot deletion is parameterized and provider-scoped, including valid
  empty snapshots, so future-provider rows are retained.
- Engine, session factory, USGS client, repositories, and service are reused
  from application state. Owned client and engine resources close at shutdown.
- Existing health paths and safe error behavior remain unchanged, with
  readiness now sharing the application engine.
- Runtime data has no seed, fixture, fallback, simulation, or demo records.

## Concerns

None. Live behavior remains dependent on USGS and network availability; the API
returns the specified safe unavailable response when no successful snapshot
exists.
