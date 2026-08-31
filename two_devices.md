# SafeMyanmar End-to-End Android And Two-Device Test

This runbook starts the SafeMyanmar backend, prepares the Android application,
optionally provisions the ONNX and Gemma models, and tests Nearby SOS BLE
sharing between two physical Android phones.

This is a local development test. Do not select real emergency contacts, send
real emergency SMS messages, or contact emergency services during the test.
All peer SOS frames are unverified and do not dispatch or acknowledge rescue.

## Run Profiles

Choose one profile before starting:

| Profile | Backend | Mapbox public token | AI artifacts | BLE |
|---|---|---|---|---|
| Full run | Required | Recommended | Optional | Yes |
| App and API | Required | Optional | Optional | Optional |
| BLE-only | Not required | Not required | Not required | Yes |

BLE itself does not need the backend, internet, Mapbox, or AI models. The full
run uses them to verify live alerts, navigation, Map rendering, and on-device
assistant capability before the two-phone BLE test.

## Requirements

- Windows PowerShell.
- Git.
- Python 3.13.
- Flutter stable 3.44.6 or a compatible newer stable release.
- Android Studio, Android SDK, platform-tools, and two physical Android phones.
- Docker Desktop with Docker Compose for PostgreSQL.
- Bluetooth Low Energy support on both phones.
- A restricted public Mapbox `pk.*` token only when Mapbox tiles are required.
- An authorized Gemma artifact and manifest only when testing Gemma.

Verify the tools from the repository root:

```powershell
py -3.13 --version
flutter --version
flutter doctor -v
docker --version
docker compose version
```

## Start The Backend

Keep this terminal open for the API:

```powershell
py -3.13 -m venv backend/.venv
backend/.venv/Scripts/python.exe -m pip install -r backend/requirements.txt
if (-not (Test-Path -LiteralPath "backend/.env")) {
  Copy-Item backend/.env.example backend/.env
}
docker compose up -d db
backend/.venv/Scripts/python.exe -m alembic -c backend/alembic.ini upgrade head
Set-Location backend
.venv/Scripts/python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

In a second terminal, from the repository root, verify the API:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health/live
Invoke-RestMethod http://127.0.0.1:8000/health/ready
Invoke-RestMethod http://127.0.0.1:8000/api/v1/alerts
```

The default `backend/.env` configuration uses:

- live USGS earthquake observations;
- the collected Yangon navigation snapshot;
- simulation data disabled;
- simulation analysis disabled;
- no backend Mapbox Directions secret.

For development-only combined analysis, edit `backend/.env` and restart Uvicorn:

```env
ENABLE_SIMULATION_DATA=false
ENABLE_SIMULATION_ANALYSIS=true
```

This adds clearly labeled fictional hazard geometry only to context analysis. It
does not add simulation shelters or hazards to the normal lists and is rejected
in production.

For the separate fictional navigation demonstration, use a development-only
configuration and a backend-only Mapbox Directions token:

```env
ENABLE_SIMULATION_DATA=true
MAPBOX_DIRECTIONS_ACCESS_TOKEN=replace_with_backend_token
```

Never pass `MAPBOX_DIRECTIONS_ACCESS_TOKEN` to Flutter or commit it. Restart the
API after changing backend configuration.

## Connect Both Phones

Enable **Developer options**, **USB debugging**, and **Install via USB** when
available. Unlock both phones and accept the USB debugging authorization prompt.

```powershell
$adb = "C:\Users\USER\AppData\Local\Android\Sdk\platform-tools\adb.exe"
& $adb devices
```

Set the two serial numbers returned by `adb devices`:

```powershell
$phoneA = "PHONE_A_SERIAL"
$phoneB = "PHONE_B_SERIAL"
```

Both entries must show `device`, not `unauthorized` or `offline`.

## Prepare The Mobile App

Run from the repository root:

```powershell
Set-Location mobile
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter analyze
flutter test
```

For physical phones using the backend over USB, create a reverse tunnel for
each phone:

```powershell
& $adb -s $phoneA reverse tcp:8000 tcp:8000
& $adb -s $phoneB reverse tcp:8000 tcp:8000
& $adb -s $phoneA reverse --list
& $adb -s $phoneB reverse --list
```

The mobile API value for this setup is:

```text
http://127.0.0.1:8000
```

Do not use `10.0.2.2` for a physical phone. That address is for the standard
Android emulator.

## Build And Install The APK

From `mobile/`, build one identical debug APK for both phones. The Mapbox token
is optional; without it, the Map tab shows a configuration state instead of
map tiles.

```powershell
flutter build apk --debug `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000 `
  --dart-define=MAPBOX_PUBLIC_ACCESS_TOKEN=pk.replace_with_restricted_public_token
```

Omit the `MAPBOX_PUBLIC_ACCESS_TOKEN` flag when Mapbox is not being tested. The
APK output is:

```text
mobile/build/app/outputs/flutter-apk/app-debug.apk
```

Install the same APK on both phones:

```powershell
Set-Location ..
& $adb -s $phoneA install -r "mobile\build\app\outputs\flutter-apk\app-debug.apk"
& $adb -s $phoneB install -r "mobile\build\app\outputs\flutter-apk\app-debug.apk"
```

Launch the app if Android does not launch it automatically:

```powershell
& $adb -s $phoneA shell monkey -p org.safemyanmar.mobile 1
& $adb -s $phoneB shell monkey -p org.safemyanmar.mobile 1
```

## Provision Optional AI Models

No ONNX or LiteRT-LM model is bundled in the APK. The app always works with the
deterministic offline classifier and approved Guide content when models are
absent.

Model files must be authorized, must not be committed, and must have matching
schema-v1 SHA-256 manifests. The expected app-private paths are:

```text
files/ai/intent_classifier.onnx
files/ai/intent_classifier.json
files/ai/gemma3-1b-it-int4.litertlm
files/ai/gemma3-1b-it-int4.json
```

### Generate The Demo ONNX Pair

This creates a project-owned development demonstration model. It is not a
production-trained safety model:

```powershell
Set-Location D:\SafeMyanmar
python -m pip install --target "$env:TEMP\safemyanmar-onnx" onnx==1.20.0
$env:PYTHONPATH = "$env:TEMP\safemyanmar-onnx"
python tools/create_demo_onnx_model.py
```

The generator writes the ONNX pair into the ignored `ai_models/` directory.

### Copy Models To Both Phones

The following helper copies any existing model pair to one debug phone. Run it
for both phones. `run-as` requires a debug APK installed by the same package ID.

```powershell
function Copy-SafeMyanmarAiFiles {
  param([string]$DeviceId)

  $remote = "/data/local/tmp/safemyanmar-ai"
  & $adb -s $DeviceId shell run-as org.safemyanmar.mobile mkdir -p files/ai
  & $adb -s $DeviceId shell mkdir -p $remote

  foreach ($file in @(
    "intent_classifier.onnx",
    "intent_classifier.json",
    "gemma3-1b-it-int4.litertlm",
    "gemma3-1b-it-int4.json"
  )) {
    $source = Join-Path "D:\SafeMyanmar\ai_models" $file
    if (Test-Path -LiteralPath $source) {
      & $adb -s $DeviceId push $source "$remote/"
      & $adb -s $DeviceId shell run-as org.safemyanmar.mobile cp "$remote/$file" "files/ai/$file"
    }
  }

  & $adb -s $DeviceId shell run-as org.safemyanmar.mobile ls -lh files/ai
  & $adb -s $DeviceId shell am force-stop org.safemyanmar.mobile
}

Copy-SafeMyanmarAiFiles $phoneA
Copy-SafeMyanmarAiFiles $phoneB
```

If the Gemma files do not exist in `ai_models/`, obtain them through an
authorized channel and place the exact model and manifest there before running
the helper. Do not create a fake Gemma manifest or use a checksum from another
artifact. Gemma requires supported ABI/resources and approximately 557 MB of
storage for the current `gemma3-1b-it-int4` artifact.

Open **Guide**, then **Offline assistant**. With valid Gemma files, the
capability banner should report local Gemma 3 availability. Test a general
question such as:

```text
What is the difference between a flood and an earthquake?
```

Critical first-aid, trapped-person, SOS, and safer-route questions remain
deterministic by design. If an optional model is absent or invalid, the app
should safely fall back to deterministic content.

## Verify Backend And Map On Both Phones

1. Open **Map**.
2. Select **Use my location** and grant foreground location permission.
3. Grant precise location when exact local positioning is required. Approximate
   permission or last-known location produces a correspondingly approximate
   position.
4. Confirm the Mapbox map loads when a public token was supplied.
5. Confirm cached or live alert/navigation status is shown honestly.

The backend API and Mapbox token are independent. The mobile app receives
`API_BASE_URL` through `--dart-define`; it does not load `.env` files. The
backend Directions token is never placed in the mobile build.

## Phone B: BLE Receiver

1. Enable Bluetooth on Phone B.
2. Open SafeMyanmar and the **SOS** screen.
3. Enable **Receive nearby SOS**.
4. Grant Nearby Devices and notification permissions.
5. Optionally enable nearby SOS sound.
6. Leave SafeMyanmar visible in the foreground.

The receiver is currently foreground-only. On some Android versions, Location
Services must also be enabled for BLE scanning even though the app does not
request background location.

## Phone A: BLE Sender

For a BLE-only test, do not select emergency contacts. This prevents a real SMS
attempt.

1. Enable Bluetooth on Phone A.
2. Open the **SOS** screen.
3. Create or select a local profile if required.
4. Do not select emergency contacts.
5. Enable **Share SOS data with nearby SafeMyanmar users**.
6. Hold the SOS confirmation control for three seconds.
7. Grant Nearby Devices and notification permissions.

Expected sender status:

```text
Nearby SOS broadcasting
```

The sender status appears only after Android confirms that BLE advertising
started. The frame broadcasts for up to ten minutes and can be stopped earlier
with **Stop**.

## Expected Results

Phone B should display one nearby, peer-received, unverified SOS alert. The
alert should include exact fixed-point coordinates when Phone A had a usable
location, a Google Maps query link, battery/status data, timestamp, protocol,
and RSSI. The Map tab should plot the peer marker at the received coordinates.

Phone A shows its active frame and its own current location locally. It does not
retain its own advertisement as a nearby alert, even when foreground or
background receiving is enabled. Stopping Phone A removes the local active
frame immediately, and delayed scan callbacks remain suppressed for the
advertisement lifetime. Phone B cannot receive a BLE stop signal, so its copy
remains until the ten-minute TTL expires or the user dismisses it.

The BLE payload contains only:

- temporary event ID;
- daily rotating sender token and event sequence;
- UTC creation timestamp;
- fixed-point latitude and longitude when available;
- current or last-known location status;
- battery percentage when available.

It does not contain names, phone numbers, or message text. Peer coordinates are
unverified and are not a guarantee of safety or rescue response.

## Test Checklist

- Backend `/health/live` and `/health/ready` respond successfully.
- Both phones have the same debug APK build.
- Both phones have Bluetooth enabled and Nearby Devices permission granted.
- Phone B has **Receive nearby SOS** enabled before Phone A starts.
- Phone A shows the active broadcasting state.
- Phone B shows one nearby SOS alert.
- Repeated advertisements do not create duplicate alert cards.
- Exact coordinates are shown when Phone A has precise/current location.
- The peer SOS marker appears at the received coordinates on the Map tab.
- Google Maps opens the received coordinate query.
- Phone A does not show its own frame as a nearby alert.
- Phone A does not restore its own frame from the background event queue.
- Phone B can keep background receiving enabled and receive while the app is
  not open, subject to Android service and battery restrictions.
- A third phone can receive the same SOS without replacing Phone B's separate
  sender event.
- A relay-enabled phone rebroadcasts a peer frame at most once and does not
  create a second local alert for that relay.
- Phone A's **Stop** control removes the local active frame.
- Phone B's frame expires after its ten-minute TTL or can be dismissed.
- No SMS is sent when no emergency contacts are selected.
- Optional Gemma capability is shown only when a valid model pair is provisioned.
- Deterministic Guide behavior remains available without optional models.

## Troubleshooting

### Backend is not ready

- Confirm Docker Desktop is running.
- Run `docker compose ps` and confirm `db` is healthy.
- Re-run the Alembic migration command.
- Confirm Uvicorn was started from `backend/`.
- Check `backend/.env` for a valid `DATABASE_URL`.
- Test `Invoke-RestMethod http://127.0.0.1:8000/health/ready` on the host.

### Phone cannot reach the backend

- Reconnect USB debugging and run `adb devices`.
- Recreate `adb reverse tcp:8000 tcp:8000` for each phone.
- Confirm the APK was built with `API_BASE_URL=http://127.0.0.1:8000`.
- Do not use `localhost` without reverse forwarding.
- Do not use `10.0.2.2` on a physical phone.

### Map is unavailable

- Confirm the APK was built with a restricted public `pk.*` Mapbox token.
- Confirm the token allows the application package and required APIs.
- Remember that the backend Directions token is not a mobile Mapbox token.
- Map data and tiles need network access; cached navigation data may still show
  with a stale/offline notice.

### Gemma is unavailable

- Confirm both model files exist under `files/ai` on the device.
- Confirm the manifest SHA-256 matches the exact model file.
- Confirm the model ID is `gemma3-1b-it-int4.litertlm`.
- Confirm the phone uses a supported ABI and has sufficient memory/storage.
- Force-stop and relaunch the app after copying models.
- Use deterministic Guide content if provisioning is unavailable.

### ONNX refinement is unavailable

- Regenerate the demo pair with `tools/create_demo_onnx_model.py`.
- Copy both `intent_classifier.onnx` and `intent_classifier.json`.
- Confirm the manifest contracts and checksum are valid.
- Remember that ONNX only refines unknown deterministic intents; it does not
  generate emergency guidance.

### No BLE alert appears

- Confirm both phones support BLE advertising and scanning.
- Confirm Bluetooth is enabled on both phones.
- Confirm Phone B enabled **Receive nearby SOS** before Phone A started.
- Keep Phone B's SOS screen in the foreground.
- Recheck Nearby Devices and Notifications permissions in Android settings.
- Move the phones closer together and retry.
- Disable battery optimization for SafeMyanmar if Android stops its foreground
  work.
- Install a fresh APK after any BLE protocol or native bridge change.

Inspect the native logs:

```powershell
$appPidA = & $adb -s $phoneA shell pidof org.safemyanmar.mobile
$appPidB = & $adb -s $phoneB shell pidof org.safemyanmar.mobile
& $adb -s $phoneA logcat --pid=$appPidA -d | findstr /I "SosBleBroadcastService BLE SOS advertising"
& $adb -s $phoneB logcat --pid=$appPidB -d | findstr /I "SosBleBridge BLE SOS scanning advertisement"
```

Expected log messages include:

```text
BLE SOS advertising started
BLE SOS scanning started
BLE SOS advertisement received
```

If the sender logs `BLE SOS advertising failed`, the Android error code must be
resolved before treating the broadcast as active.

### Permission was permanently denied

Open Android app settings for SafeMyanmar and manually enable Nearby Devices,
Notifications, and foreground Location when needed. Restart the test after
changing permissions.

### `run-as` cannot access the model directory

- Confirm the installed APK is a debug build.
- Confirm the package ID is `org.safemyanmar.mobile`.
- Uninstall and reinstall the debug APK if the package was previously signed
  differently.
- Do not use a release APK for local `run-as` provisioning.

## Cleanup

Stop the API with `Ctrl+C`, then stop local containers when they are no longer
needed:

```powershell
docker compose down
```

Remove the optional model files from a debug phone when required:

```powershell
& $adb -s $phoneA shell run-as org.safemyanmar.mobile rm -rf files/ai
& $adb -s $phoneB shell run-as org.safemyanmar.mobile rm -rf files/ai
```

Do not commit `backend/.env`, authorized model artifacts, model manifests, or
real emergency contact data.
