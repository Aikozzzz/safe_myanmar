# SafeMyanmar

SafeMyanmar is an academic Android disaster-information application for the
Mobile and Ubiquitous Computing subject. The implemented app combines live USGS
earthquake observations, explicit foreground location use, a validated Yangon
navigation snapshot, offline emergency guidance, local SOS preparation, and
constrained on-device assistance.

SafeMyanmar is not an official warning, earthquake-prediction, emergency
dispatch, medical, or guaranteed-safety service. USGS observations are
informational and preliminary values may change. Navigation records include
their source, timestamp, and uncertainty notice; empty data is not replaced by
fictional recommendations. Follow authorized local instructions and contact
official emergency or medical services when available.

## Implemented Scope

- Material 3 five-tab shell: Home, Map, SOS, Guide, and More. The earthquake
  list and detail screens are opened from Home.
- Backend-only retrieval of the live USGS `all_day.geojson` feed, strict
  normalization into PostgreSQL, and versioned list/detail APIs with USGS
  attribution and UTC timestamps.
- Cache-first earthquake states for live, cached, stale, successful empty, and
  unavailable data. Alert detail preserves magnitude, depth, coordinates, event
  time, provider update and retrieval times, review status, version, and the
  trusted USGS source link.
- Explicit foreground location flow with approximate/precise, denied,
  permanently denied, disabled-service, retry, and last-known-location states.
  The app requests no background location permission.
- Mapbox map rendering when an optional public mobile token is supplied.
  The default navigation data is the validated Yangon snapshot configured by
  `NAVIGATION_DATA_PATH`; it exposes only records present in that snapshot and
  does not invent shelters. Explicit nearby analysis can score offset points
  using separately retrieved mapped environment data.
- Current hazard records include source and retrieval timestamps. Route
  guidance is an explicit two-step flow: the user reviews up to three
  lower-exposure context-area suggestions, selects one, and then requests up to
  three Mapbox alternatives. Each route includes its destination source,
  directions provider, generated time, hazard-data time, profile, ranking
  rationale, and uncertainty notice. Missing or stale destination, directions
  configuration, or provider data leaves route guidance unavailable; no
  straight-line fallback or guaranteed-safe route is presented.
- Drift schema v6 for earthquake, shelter, hazard, and route caches plus
  versioned, source-backed emergency Guide content.
- Device-local profile and up to ten emergency contacts in Android secure
  storage. Contacts must be explicitly selected for SOS use.
- Persisted SOS drafts with recipient and optional location snapshots,
  five-minute duplicate suppression, hold-to-confirm, and an accessible
  confirmation path. Android direct SMS sending is available after explicit
  confirmation and runtime SMS permission; device acceptance is recorded, but
  carrier delivery is not guaranteed or verified.
- Explicit opt-in Android background SOS receiving. A connected-device
  foreground service validates, deduplicates, encrypts, and retains temporary
  BLE frames for offline display, replaces older frames from the same sender,
  and sends an unverified alert notification. Foreground receiving and relay
  remain session-scoped opt-ins; background receiving never relays or uploads
  frames.
- Nearby SOS broadcasts use a daily rotating sender token and require explicit
  per-SOS location-sharing consent. The Map tab can display and select all
  retained located SOS sources without treating peer data as verified.
- Bilingual English/Myanmar offline Guide articles with source, review date,
  content version, translation warning, category filtering, and search.
- A deterministic offline intent classifier and structured SOS text extraction.
   Optional checksum-gated ONNX intent refinement and LiteRT-LM Gemma 3 answers
   can be provisioned separately; no model artifacts are bundled.
- Riverpod state management, `go_router` navigation, localization-ready UI,
  light/dark themes, semantic status announcements, and 48dp touch targets.

See [the context-aware mobile flow](docs/architecture/context-aware-mobile-flow.md),
[the live-alert subsystem architecture](docs/architecture/live-earthquake-slice.md),
[optional AI model provisioning](docs/architecture/optional-ai-model-provisioning.md),
[the step-by-step run instructions](Instruction.md),
[the implemented mobile design](DESIGN.md),
[the alert API](docs/api/alerts.md), and
[the navigation API](backend/docs/api/simulation-navigation.md).

The archived Figma zip is a design reference only. It is not included as app
assets and is not loaded by the shipped runtime.

## Data And Safety Boundaries

### Live earthquake observations

The backend includes USGS events whose coordinates are within these inclusive
coarse coverage bounds:

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
not shown as an empty result. There are no simulated earthquake alerts in the
runtime path; controlled alert fixtures remain test-only.

### Navigation data

The default runtime loads the validated snapshot named by `NAVIGATION_DATA_PATH`.
The current Yangon snapshot contains no verified shelters. Nearby analysis can
use OpenStreetMap/Overpass building and tree features for earthquake criteria
and OpenTopoData terrain elevation for flood criteria. Stale or geometry-less
records are excluded. `ENABLE_SIMULATION_DATA=true` remains an explicitly
separate development mode and is rejected in production.
`ENABLE_SIMULATION_ANALYSIS=true` can be enabled outside production to augment
real context-area analysis with clearly labeled fictional hazard geometry; it
does not alter the hazard or shelter lists.

Real nearby-area analysis uses full OpenStreetMap geometry retrieved through
Overpass: named open spaces, building footprints/heights, trees or woodland,
power infrastructure, and (for flood analysis) mapped water features. Flood
terrain samples use the configured `ELEVATION_API_URL`, which defaults to
OpenTopoData ASTER30m. This is terrain elevation rather than a flood forecast;
a deployment may provide a compatible approved DEM or Copernicus-derived
service. Public-provider availability, tagging, geometry, and height coverage
can be incomplete, and a missing mapped feature is not evidence of absence.

Environment observations are retained only in a bounded process-local coarse
cache (up to 128 entries, five-minute freshness, and no database persistence).
Provider failures may show a matching stale observation with its original
source timestamp and an explicit warning. SafeMyanmar does not log or persist
the user's exact origin, although the configured upstream GIS service receives
the requested location during collection. OSM-derived user-facing content must
credit `© OpenStreetMap contributors`. Nearby results remain comparative
lower-exposure suggestions, not official shelters, evacuation orders, or
guarantees of safe places or routes.

Route requests may target a verified shelter record from the current snapshot
or the exact `context_area_id` selected from the current analysis response.
When a context area is selected, the backend recomputes that candidate for the
same origin, disaster type, scenario, and search radius before calling
Directions. A valid destination alone is not evidence that its access,
conditions, or route are safe.

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

The API listens at `http://localhost:8000`. Implemented endpoints are:

```text
GET  /health/live
GET  /health/ready
GET  /api/v1/alerts
GET  /api/v1/alerts/{id}
GET  /api/v1/shelters
GET  /api/v1/hazards
POST /api/v1/context-areas
POST /api/v1/route-suggestions
```

With the validated navigation snapshot, the shelter, hazard, and context-area
endpoints use collected data. They return `404` only when neither a navigation
snapshot nor simulation mode is available. `ENABLE_SIMULATION_ANALYSIS=true`
augments context-area analysis only and does not change the shelter or hazard
lists. Route suggestions additionally require a verified snapshot destination
or a selected context area and the backend-only Mapbox Directions token. The
runtime accepts the validated snapshot for up to 30 days after its retrieval
timestamp; route responses retain the hazard-data timestamp and generated
timestamp so clients can show data age. A missing, invalid, or older snapshot
keeps `/health/ready` unavailable with a safe navigation-data error. See the
linked API references for exact schemas, validation, and safe error envelopes.

To run the API in Docker instead:

```powershell
docker compose build api
docker compose up -d db
docker compose run --rm api alembic upgrade head
docker compose up api
```

The API image is built from the repository root and packages the validated
Yangon snapshot. Do not remove that snapshot from the build context unless
`NAVIGATION_DATA_PATH` points to another packaged snapshot.

## Mobile Setup

```powershell
Set-Location mobile
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

To render the Mapbox map, add a restricted public token:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 `
  --dart-define=MAPBOX_PUBLIC_ACCESS_TOKEN=pk.replace_with_restricted_public_token
```

`10.0.2.2` reaches the host from the standard Android emulator. Cleartext HTTP
to that host is permitted only by the Android debug network-security policy.
Release API communication must use HTTPS. For deliberate debug development on a
physical device, run `adb reverse tcp:8000 tcp:8000` and use
`http://127.0.0.1:8000`; otherwise use a reachable HTTPS endpoint. Device
`localhost` does not refer to the development computer without `adb reverse`.

### Test an already-installed app over wireless ADB

The repository includes a PowerShell launcher that starts the backend, starts
the local PostgreSQL container, applies migrations, and creates a temporary
`adb reverse` tunnel. It does not install the APK, clear app data, or start
Flutter:

```powershell
# Pair and connect the phone once from Android wireless debugging settings.
adb pair 192.168.1.50:37099
adb connect 192.168.1.50:42137
adb devices

# From the repository root:
.\tools\run-backend-wireless.ps1 -DeviceId 192.168.1.50:42137
```

The already-installed debug APK must have been built with
`--dart-define=API_BASE_URL=http://127.0.0.1:8000`; `adb reverse` maps that
device loopback address to the backend on this computer. If only one Android
device is online, `-DeviceId` may be omitted. Use `-SkipDatabase` when
PostgreSQL is already running and `-SkipMigration` when its schema is already
current. Press `Ctrl+C` to stop the backend and remove the temporary tunnel.
The script leaves the Docker database running. It does not expose the API to
the local network, and it cannot change the compile-time API URL in an APK
that is already installed.

## Configuration

Root `.env.example` documents the cross-layer contract. Flutter values are
compile-time `--dart-define` values; Flutter does not load the `.env` file.
Backend values are read from `backend/.env` when the API starts in `backend/`.

| Variable | Consumer | Requirement and default |
|---|---|---|
| `API_BASE_URL` | Flutter | Required compile-time value; HTTPS in release. Emulator debug example: `http://10.0.2.2:8000` |
| `MAPBOX_PUBLIC_ACCESS_TOKEN` | Flutter | Optional restricted `pk.*` public token supplied with `--dart-define`; without it the map shows a configuration state |
| `DATABASE_URL` | FastAPI, Alembic | Required `postgresql+psycopg` URL; production requires non-placeholder values, a non-loopback host, and `sslmode=require` |
| `ENVIRONMENT` | FastAPI, Alembic | `development` by default; also accepts `test` or `production` |
| `USGS_FEED_URL` | FastAPI | Defaults to the live USGS all-day feed |
| `PROVIDER_TIMEOUT_SECONDS` | FastAPI | Defaults to `10.0`; used by USGS and Mapbox requests |
| `REFRESH_MINIMUM_SECONDS` | FastAPI | Defaults to `60` |
| `CURRENT_MAX_AGE_SECONDS` | FastAPI | Defaults to `300` |
| `ENABLE_SIMULATION_DATA` | FastAPI; Flutter | Backend defaults to `false` and must remain false in production; mobile must also receive the compile-time define to display fictional or mixed analysis responses |
| `ENABLE_SIMULATION_ANALYSIS` | FastAPI | Defaults to `false`; development-only backend analysis augmentation; must remain false in production |
| `NAVIGATION_DATA_PATH` | FastAPI | Defaults to the validated Yangon snapshot directory |
| `OVERPASS_API_URL` | FastAPI | OpenStreetMap building/tree lookup used by earthquake analysis |
| `ELEVATION_API_URL` | FastAPI | OpenTopoData elevation lookup used by flood analysis |
| `MAPBOX_DIRECTIONS_ACCESS_TOKEN` | FastAPI | Optional secret; required for real or simulation route suggestions when a verified/selected destination is requested |

Never commit a real `.env` file or Mapbox secret. Restrict the public mobile
token by application/package and allowed APIs. The mobile public token is
embedded in the built app and must not be treated as a secret. The backend
Directions token must never be passed to Flutter.

## Testing

The tracked
[live-earthquake verification record](docs/verification/live-earthquake-vertical-slice.md)
is historical evidence for the original alert slice. It records the exact
results, commands, security checks, Android E2E blocker, and APK/toolchain state
at that point; it is not a claim about later feature test totals.

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
```

For a reproducible Windows debug APK build, run the following block from the
repository root. If Flutter is installed outside
`$env:USERPROFILE\develop\flutter`, adjust `$flutterBin`. The block deliberately
removes process-local `GRADLE_USER_HOME`; do not point it at an empty isolated
directory because the existing wrapper download in `%USERPROFILE%\.gradle` must
be reused.

```powershell
$repoRoot = (Get-Location).Path
$mobileRoot = Join-Path $repoRoot "mobile"
$buildEnvironmentRoot = Join-Path $repoRoot ".superpowers\android-build"
$flutterBin = Join-Path $env:USERPROFILE "develop\flutter\bin"

if (-not (Test-Path -LiteralPath $flutterBin)) {
    throw "Update `$flutterBin to the local Flutter bin directory."
}
foreach ($directory in @(
    $buildEnvironmentRoot,
    (Join-Path $buildEnvironmentRoot "pub-cache"),
    (Join-Path $buildEnvironmentRoot "temp"),
    (Join-Path $buildEnvironmentRoot "tmp")
)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

$env:PATH = "$flutterBin;$env:PATH"
$env:PUB_CACHE = Join-Path $buildEnvironmentRoot "pub-cache"
$env:TEMP = Join-Path $buildEnvironmentRoot "temp"
$env:TMP = Join-Path $buildEnvironmentRoot "tmp"
Remove-Item Env:GRADLE_USER_HOME -ErrorAction SilentlyContinue

Push-Location (Join-Path $mobileRoot "android")
try {
    & ".\gradlew.bat" --stop
    if ($LASTEXITCODE -ne 0) { throw "Could not stop Gradle." }
} finally {
    Pop-Location
}

Push-Location $mobileRoot
try {
    flutter clean
    if ($LASTEXITCODE -ne 0) { throw "Flutter clean failed." }
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "Flutter pub get failed." }
    dart run build_runner build
    if ($LASTEXITCODE -ne 0) { throw "Build runner failed." }
    flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
    if ($LASTEXITCODE -ne 0) { throw "Debug APK build failed." }
} finally {
    Pop-Location
}
```

The deterministic alert end-to-end test uses an ephemeral PostgreSQL database,
a local test-only USGS-protocol server, the real FastAPI process, real mobile
wiring, and persisted Drift storage. It verifies populated list/detail content,
then stops the API and verifies stale cached content and safe failure copy. With
an Android target listed by `flutter devices`, run:

```powershell
tools/run-live-alerts-integration.ps1 -DeviceId <android-device-id>
```

The harness auto-selects `10.0.2.2` for an emulator and configures `adb reverse`
with `127.0.0.1` for a physical device. Its `-ApiBaseUrl` option accepts only the
locally orchestrated API; it rejects remote hosts, credentials, query strings,
fragments, and non-root paths. It never calls emergency services, Mapbox, or a
remote API. Only the separate opt-in live smoke calls USGS.

## Repository Structure

```text
SafeMyanmar/
|-- backend/
|   |-- alembic/                 PostgreSQL migrations
|   |-- app/                     FastAPI runtime and providers
|   |-- docs/api/                simulation navigation API reference
|   `-- tests/                   unit, API, integration, security tests
|-- mobile/
|   |-- android/                 Android config and optional native AI bridge
|   |-- integration_test/        real app/API/Drift alert scenario
|   |-- lib/                     Flutter app and feature modules
|   `-- test/                    unit, widget, contract, security tests
|-- docs/
|   |-- api/                     live alert API reference
|   |-- architecture/            alert, context, and AI provisioning notes
|   `-- verification/            dated verification records
|-- tools/run-live-alerts-integration.ps1
|-- DESIGN.md
|-- docker-compose.yml
|-- .env.example
`-- README.md
```

## Deferred And Explicit Limitations

- Live provider coverage remains USGS earthquakes only. There are no official
  Myanmar warnings, evacuation orders, impact/severity classification, push
  notifications, or additional live disaster providers.
- Context-aware navigation defaults to the validated collected navigation
  snapshot. Earthquake analysis can compare mapped building/tree exposure
  outdoors after shaking; flood analysis can compare terrain elevation and
  current hazard polygons. The separate simulation mode generates fictional
  candidates, while `ENABLE_SIMULATION_ANALYSIS` can add fictional hazard
  geometry to real context analysis for development evaluation only. None of
  these outputs are verified field conditions, official shelters, evacuation
  orders, or guaranteed safe routes.
- The app has no authentication, cloud profile synchronization, rescue-team
  dashboard, damage reporting, official rescue-service integration, Rescue
  Beacon Mode, iOS Bluetooth support, or background location tracking.
- Android BLE SOS sharing is limited to nearby SafeMyanmar users who have opted
   into receiving peer alerts. It broadcasts a temporary event ID, UTC timestamp,
   fixed-point coordinates when available, location status, and battery value for up to ten
   minutes. The active sender frame is shown locally with its decoded details;
   peer events are unverified and do not confirm delivery or rescue.
- SOS remains a local draft and transport handoff workflow. SMS is reviewed and
  sent in an external app; optional Android BLE sharing broadcasts limited,
  unverified peer data for ten minutes. SafeMyanmar has no sent, delivered,
  dispatch, retry, or rescue acknowledgement signal.
- Guide content is a small reviewed offline set, not diagnosis or comprehensive
  medical care. Myanmar translations carry a review warning.
- Deterministic guidance remains available without models. Optional ONNX and
  LiteRT-LM artifacts require separate licensed provisioning, exact manifests,
  matching checksums, and supported device resources. No artifact download,
  credential handling, or model update service is implemented.
