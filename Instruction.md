# SafeMyanmar Run Instructions

These instructions run the Android Flutter app, FastAPI backend, and PostgreSQL
database on Windows PowerShell.

SafeMyanmar is an academic prototype. Live USGS earthquake observations are
informational. Shelters, hazards, and route suggestions are fictional
**SIMULATION** data and must not be used as official emergency guidance.

## 1. Prerequisites

Install and configure:

- Git
- Python 3.13
- Flutter 3.44.6 or a compatible newer stable release
- Android Studio and Android SDK
- An Android emulator or physical Android device
- Docker Desktop with Docker Compose
- A Mapbox account only when map tiles or route suggestions are required

Verify the main tools from the repository root:

```powershell
py -3.13 --version
flutter --version
flutter doctor -v
docker --version
docker compose version
```

## 2. First-Time Backend Setup

Run these commands from the repository root:

```powershell
py -3.13 -m venv backend/.venv
backend/.venv/Scripts/python -m pip install -r backend/requirements.txt
Copy-Item backend/.env.example backend/.env
docker compose up -d db
backend/.venv/Scripts/python -m alembic -c backend/alembic.ini upgrade head
```

The default development database is exposed at `localhost:5432`.

## 3. Configure The Backend

Open `backend/.env`.

### Basic Mode

Basic mode provides live USGS earthquake information and all offline mobile
features. Keep simulation disabled:

```env
DATABASE_URL=postgresql+psycopg://safemyanmar_dev:safemyanmar_dev_password@localhost:5432/safemyanmar
ENVIRONMENT=development
USGS_FEED_URL=https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson
PROVIDER_TIMEOUT_SECONDS=10.0
REFRESH_MINIMUM_SECONDS=60
CURRENT_MAX_AGE_SECONDS=300
ENABLE_SIMULATION_DATA=false
MAPBOX_DIRECTIONS_ACCESS_TOKEN=
```

### Simulation Navigation Mode

To expose fictional shelters, hazards, and route endpoints, set:

```env
ENABLE_SIMULATION_DATA=true
MAPBOX_DIRECTIONS_ACCESS_TOKEN=replace_with_backend_mapbox_token
```

`MAPBOX_DIRECTIONS_ACCESS_TOKEN` stays on the backend. Never pass it to Flutter
or commit it. Restrict the token to the required Mapbox APIs.

The simulation API is registered only when the backend starts with
`ENABLE_SIMULATION_DATA=true`. Restart the API after changing this value.

Simulation navigation is limited to this fictional Mandalay demonstration area:

```text
Latitude:  21.9300 to 21.9900
Longitude: 96.0600 to 96.1200
```

For an Android emulator demonstration, set the emulator location near:

```text
Latitude:  21.9500
Longitude: 96.0800
```

Use Android Emulator **Extended controls > Location** to set these coordinates.
Requests outside the demonstration area are rejected.

## 4. Start The Backend

Keep PostgreSQL running:

```powershell
docker compose up -d db
```

Open a separate PowerShell terminal and run:

```powershell
Set-Location backend
.venv/Scripts/python -m uvicorn app.main:app --reload
```

The API should start at `http://localhost:8000`.

Check it in another terminal:

```powershell
Invoke-RestMethod http://localhost:8000/health/live
Invoke-RestMethod http://localhost:8000/health/ready
Invoke-RestMethod http://localhost:8000/api/v1/alerts
```

When simulation is enabled, these endpoints are also available:

```powershell
Invoke-RestMethod http://localhost:8000/api/v1/shelters
Invoke-RestMethod http://localhost:8000/api/v1/hazards
```

Interactive API documentation is available at:

```text
http://localhost:8000/docs
```

## 5. Prepare The Flutter App

Open another PowerShell terminal:

```powershell
Set-Location mobile
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter devices
```

## 6. Run On An Android Emulator

The Android emulator reaches the host backend through `10.0.2.2`.

### Without Map Tiles

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Location, cached shelters, route controls, SOS, Guide, and More remain usable,
but the Map tab displays a map-configuration message instead of Mapbox tiles.

### With Mapbox Map Tiles

Use a restricted public Mapbox `pk.*` token:

```powershell
flutter run `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 `
  --dart-define=MAPBOX_PUBLIC_ACCESS_TOKEN=pk.replace_with_restricted_public_token
```

The public token is embedded in the APK and is not a secret. Restrict it by
Android package/application and allowed APIs. Do not use the backend Directions
token here.

For three route alternatives, both mobile map configuration and backend
simulation configuration must be active.

## 7. Run On A Physical Android Device

Connect the device with USB debugging enabled, then verify it:

```powershell
adb devices
flutter devices
```

Forward the device port to the host backend:

```powershell
adb reverse tcp:8000 tcp:8000
```

Run the app with:

```powershell
Set-Location mobile
flutter run `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000 `
  --dart-define=MAPBOX_PUBLIC_ACCESS_TOKEN=pk.replace_with_restricted_public_token
```

Omit `MAPBOX_PUBLIC_ACCESS_TOKEN` when map tiles are not needed.

## 8. First App Use

1. Open **Home** to view current or cached USGS earthquake observations.
2. Open **Map** and select **Use my location** only if location use is wanted.
3. Grant approximate or precise foreground location permission.
4. In simulation mode, select a fictional shelter, disaster type, and walking
   or driving profile, then request routes.
5. Open **More** to add a local profile and emergency contacts.
6. Select contacts for SOS use.
7. Open **SOS**, review the exact SMS body, and hold the confirmation control for
   three seconds. SafeMyanmar opens the phone messaging app; the user must send
   the SMS there.
8. Open **Guide** for source-backed offline articles and deterministic emergency
   question matching.

Opening the SOS tab does not send, prepare, or queue a message. SafeMyanmar
cannot verify SMS sent or delivered status because the external messaging app
controls transmission.

## 9. Optional On-Device AI Models

No ONNX or Gemma model is required to run SafeMyanmar. The deterministic offline
assistant works without model files.

Optional models must be separately licensed, checksum validated, and provisioned
under the Android app-private `filesDir/ai` directory. Do not commit models or
credentials. See:

```text
docs/architecture/optional-ai-model-provisioning.md
```

## 10. Run Tests

### Mobile

From `mobile/`:

```powershell
flutter gen-l10n
dart run build_runner build
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Build a debug APK:

```powershell
flutter build apk --debug `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

The APK is written to:

```text
mobile/build/app/outputs/flutter-apk/app-debug.apk
```

### Backend

From the repository root, start the isolated test database:

```powershell
docker compose --profile integration up -d integration-db
$env:TEST_DATABASE_URL = "postgresql+psycopg://safemyanmar_test:safemyanmar_test_password@localhost:5433/safemyanmar_test"
backend/.venv/Scripts/python -m ruff format --check backend
backend/.venv/Scripts/python -m ruff check backend
backend/.venv/Scripts/python -m pytest backend/tests -v
```

Remove the isolated test database afterward:

```powershell
docker compose --profile integration stop integration-db
docker compose --profile integration rm -f integration-db
Remove-Item Env:TEST_DATABASE_URL -ErrorAction SilentlyContinue
```

The live USGS network smoke test is intentionally opt-in:

```powershell
$env:RUN_LIVE_USGS_TESTS = "1"
backend/.venv/Scripts/python -m pytest backend/tests/integration/test_live_usgs_smoke.py -v
Remove-Item Env:RUN_LIVE_USGS_TESTS -ErrorAction SilentlyContinue
```

## 11. Stop The Project

Stop `uvicorn` and `flutter run` with `Ctrl+C` in their terminals.

Stop PostgreSQL while preserving its named data volume:

```powershell
docker compose down
```

Do not add `-v` unless deleting the local PostgreSQL data is intentional.

## 12. Troubleshooting

### `API_BASE_URL` is missing

Flutter does not load `.env` files. Always pass `API_BASE_URL` with
`--dart-define`.

### Emulator cannot reach the backend

Use `http://10.0.2.2:8000`, not `localhost`. Confirm that Uvicorn and PostgreSQL
are running and that `/health/ready` responds on the host.

### Physical device cannot reach the backend

Run `adb reverse tcp:8000 tcp:8000` and use
`http://127.0.0.1:8000` as `API_BASE_URL`.

### Simulation endpoints return `404`

Set `ENABLE_SIMULATION_DATA=true` in `backend/.env` and restart Uvicorn. The
routes are not registered when simulation is disabled.

### Route suggestions return `503`

Confirm `MAPBOX_DIRECTIONS_ACCESS_TOKEN` is configured on the backend, allowed
to call Directions, and not expired or restricted incorrectly.

### Route request is outside the simulation area

Set the emulator location within latitude `21.9300-21.9900` and longitude
`96.0600-96.1200`.

### Map says configuration is unavailable

Pass a valid restricted public `pk.*` token as
`MAPBOX_PUBLIC_ACCESS_TOKEN` when running Flutter.

### Location is unavailable

Enable device location services, set an emulator location, and grant foreground
location permission. If permission was permanently denied, open Android app
settings from the Map screen.

### Generated Dart files are stale

Run:

```powershell
Set-Location mobile
flutter gen-l10n
dart run build_runner build
```

### Mapbox Kotlin warning appears during build

The current Mapbox Flutter plugin can emit a future Kotlin Gradle compatibility
warning. It does not currently block the debug build, but the plugin should be
upgraded when a compatible release is available.

### App cannot install on an older Android device

The Mapbox Android SDK can make GLES 3 support an installation requirement. A
future no-map product flavor is required for older devices; it is not currently
implemented.
