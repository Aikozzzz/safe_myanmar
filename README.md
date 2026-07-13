# SafeMyanmar

SafeMyanmar is an academic Android disaster-information application for the
Mobile and Ubiquitous Computing subject. The current implemented vertical slice
shows live USGS earthquake observations for an approximate Myanmar coverage
area through a Flutter app, FastAPI API, PostgreSQL server snapshot, and offline
Drift cache.

This is not an official warning or earthquake-prediction system. It does not
provide complete all-disaster coverage or guarantee safety. USGS values are
informational and preliminary values may change. Follow authorized local
instructions and official emergency services when available.

## Implemented Scope

- Android Flutter list and detail screens with localization-ready, accessible
  Material light/dark presentation.
- Live USGS `all_day.geojson` retrieval by the backend only.
- Strict validation and normalization into PostgreSQL.
- Exact versioned list/detail API with USGS source attribution and UTC times.
- Drift/SQLite cache-first mobile behavior with live, cached, stale, successful
  empty, and unavailable states.
- Riverpod state management and `go_router` navigation.
- Backend unit, API, migration, repository, provider, security, live-network,
  and integration tests; mobile unit, DTO, Drift, Riverpod, widget,
  accessibility, security-configuration, contract, and Android integration
  tests.

There are no runtime demo or simulated records. Controlled
`integration-fixture` data exists only under test paths and is never referenced
by `backend/app` or `mobile/lib`.

## Data Boundaries

The backend includes events whose coordinates are within these inclusive coarse
coverage bounds:

| Boundary | Value |
|---|---:|
| Minimum latitude | `8.284` |
| Maximum latitude | `30.043` |
| Minimum longitude | `90.689` |
| Maximum longitude | `102.676` |

The box includes a 1.5-degree border buffer. It is not a political border,
affected-area assessment, or claim that places outside it are safe. Provider
refresh attempts are throttled to 60 seconds. A successful server snapshot is
current for five minutes, then explicitly stale. A provider failure preserves
the last successful server and mobile snapshots; failure before any success is
not shown as an empty result.

See [the slice architecture](docs/architecture/live-earthquake-slice.md) and
[alert API reference](docs/api/alerts.md) for exact behavior.

## Prerequisites

- Git.
- Python 3.13 (the backend currently targets Python 3.13).
- Flutter stable 3.44.6 or a compatible newer stable release.
- Android SDK and an Android emulator/device for app launch and integration.
- Docker Desktop with Docker Compose for PostgreSQL and container checks, or a
  compatible local PostgreSQL 16 instance.

Ensure `python`, `flutter`, `adb`, and `docker` are available on `PATH` as needed.

## Backend Setup

From the repository root:

```powershell
py -3.13 -m venv backend/.venv
backend/.venv/Scripts/python -m pip install -r backend/requirements.txt
Copy-Item backend/.env.example backend/.env
docker compose up -d db
backend/.venv/Scripts/python -m alembic -c backend/alembic.ini upgrade head
```

Start the API from `backend/` so Pydantic loads `backend/.env`:

```powershell
Set-Location backend
.venv/Scripts/python -m uvicorn app.main:app --reload
```

The API listens at `http://localhost:8000`. Useful endpoints are:

```text
GET /health/live
GET /health/ready
GET /api/v1/alerts
GET /api/v1/alerts/{id}
```

To run the API in Docker instead:

```powershell
docker compose build api
docker compose up -d db
docker compose run --rm api alembic upgrade head
docker compose up api
```

## Mobile Setup

```powershell
Set-Location mobile
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` reaches the host from the standard Android emulator. Cleartext HTTP
to that host is permitted only by the Android debug network-security policy.
Release API communication must use HTTPS. For deliberate debug development on a
physical device, run `adb reverse tcp:8000 tcp:8000` and use
`http://127.0.0.1:8000`; otherwise use a reachable HTTPS endpoint. Do not assume
device `localhost` points to the development computer without `adb reverse`.

## Configuration

Root `.env.example` documents the cross-layer contract. Runtime consumers are:

| Variable | Consumer | Requirement and default |
|---|---|---|
| `API_BASE_URL` | Flutter compile-time `--dart-define` | Required; HTTPS in release. Emulator debug example: `http://10.0.2.2:8000` |
| `DATABASE_URL` | FastAPI, Alembic | Required `postgresql+psycopg` URL. Production requires non-loopback, non-placeholder values and `sslmode=require` |
| `USGS_FEED_URL` | FastAPI | Optional; defaults to the live USGS all-day feed |
| `PROVIDER_TIMEOUT_SECONDS` | FastAPI | Optional; default `10.0` |
| `REFRESH_MINIMUM_SECONDS` | FastAPI | Optional; default `60` |
| `CURRENT_MAX_AGE_SECONDS` | FastAPI | Optional; default `300` |
| `ENVIRONMENT` | FastAPI, Alembic | Optional: `development` (default), `test`, or `production`; controls production database validation |
| `MAPBOX_ACCESS_TOKEN` | None in this slice | Future maps increment only; not read, required, or validated |

Never commit a real `.env` file. Mapbox is selected for a future map, geocoding,
and directions increment; no Mapbox package or request exists now.

## Testing

Start an ephemeral dedicated PostgreSQL test database:

```powershell
docker compose --profile integration up -d integration-db
$env:TEST_DATABASE_URL = "postgresql+psycopg://safemyanmar_test:safemyanmar_test_password@localhost:5433/safemyanmar_test"
```

Run backend checks from the root:

```powershell
backend/.venv/Scripts/python -m ruff format --check backend
backend/.venv/Scripts/python -m ruff check backend
backend/.venv/Scripts/python -m pytest backend/tests -v
```

The external-network smoke is opt-in and uses the default live USGS URL:

```powershell
$env:RUN_LIVE_USGS_TESTS = "1"
backend/.venv/Scripts/python -m pytest backend/tests/integration/test_live_usgs_smoke.py -v
```

Run mobile checks from `mobile/`:

```powershell
flutter gen-l10n
dart run build_runner build
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

The deterministic end-to-end test uses an ephemeral PostgreSQL test database,
a local test-only USGS-protocol server, the real FastAPI process, real mobile
wiring, and persisted Drift storage. It first verifies populated list/detail
content, then stops the API and verifies stale cached content and safe failure
copy. With an Android target listed by `flutter devices`, run from the root. The
harness auto-selects `10.0.2.2` for an emulator and configures `adb reverse` with
`127.0.0.1` for a physical device:

```powershell
tools/run-live-alerts-integration.ps1 -DeviceId <android-device-id>
```

Use `-ApiBaseUrl <url>` to override the detected debug URL and `-FlutterBin
<directory>` only when Flutter is not already on `PATH`.

The harness bounds readiness/process waits, stops its API/provider processes,
validates Android application-data cleanup, removes any `adb reverse` rule,
stops the ephemeral integration database, and restores `PATH`, `DATABASE_URL`,
and `USGS_FEED_URL`. It never calls emergency services, Mapbox, or a remote API;
only the separate opt-in live smoke calls USGS.

## Repository Structure

```text
SafeMyanmar/
|-- backend/
|   |-- alembic/                 PostgreSQL migrations
|   |-- app/                     FastAPI runtime source
|   `-- tests/                   unit/API/integration/security fixtures
|-- mobile/
|   |-- android/                 Android main/debug configuration
|   |-- integration_test/        real app/API/Drift scenario
|   |-- lib/                     Flutter runtime source
|   `-- test/                    unit/widget/contract tests
|-- docs/
|   |-- api/alerts.md
|   `-- architecture/live-earthquake-slice.md
|-- tools/run-live-alerts-integration.ps1
|-- docker-compose.yml
|-- .env.example
`-- README.md
```

## Deferred Features

Authentication, user location, maps and Mapbox, shelters, hazard zones, route
suggestions, SOS and emergency contacts, Rescue Beacon Mode, reviewed first-aid
content, AI assistance, notifications, damage reporting, additional disaster
providers, and official rescue-service integration are later increments. Future
route suggestions must remain timestamped and uncertain, never guaranteed safe.
