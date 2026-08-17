# Run SafeMyanmar With Android USB Debugging

This guide runs the SafeMyanmar backend on Windows and the Flutter app on a
physical Android phone connected through USB debugging.

## Prerequisites

- Android phone with Developer Options and USB debugging enabled.
- USB cable that supports data transfer.
- Android Studio and Flutter installed.
- Docker Desktop running for the PostgreSQL database.
- A debug build of the app. `adb shell run-as` does not work with a release APK.

## 1. Start The Backend

Open a PowerShell terminal and run these commands from the project root:

```powershell
Set-Location D:\SafeMyanmar
docker compose up -d db
```

For first-time setup only:

```powershell
python -m venv backend\.venv
backend\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
Copy-Item backend\.env.example backend\.env
backend\.venv\Scripts\python.exe -m alembic -c backend\alembic.ini upgrade head
```

Start FastAPI and keep this terminal open:

```powershell
Set-Location D:\SafeMyanmar\backend
.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

In another terminal, verify the backend:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health/live
Invoke-RestMethod http://127.0.0.1:8000/health/ready
```

## 2. Connect The Android Phone

Enable **Developer options**, **USB debugging**, and **Install via USB** when
available. Unlock the phone and accept the USB debugging authorization prompt.

If `adb` is not in `PATH`, use the Android SDK executable directly:

```powershell
$adb = "C:\Users\USER\AppData\Local\Android\Sdk\platform-tools\adb.exe"
& $adb devices
```

Expected output:

```text
List of devices attached
YOUR_PHONE_SERIAL    device
```

If the phone is `unauthorized`, unlock it and accept the prompt on the phone.
If no device appears, reconnect the cable and confirm that it supports data.

Store the serial for later commands:

```powershell
$deviceId = "YOUR_PHONE_SERIAL"
```

You can also confirm the Flutter device ID:

```powershell
flutter devices
```

## 3. Forward The Backend Over USB

Create a USB tunnel from the phone's port `8000` to the computer's port `8000`:

```powershell
& $adb -s $deviceId reverse tcp:8000 tcp:8000
& $adb -s $deviceId reverse --list
```

Expected mapping:

```text
8000 8000
```

Because of this tunnel, the Android app must use:

```text
http://127.0.0.1:8000
```

Do not use `10.0.2.2` for a physical phone. That address is for the standard
Android emulator.

## 4. Run The Flutter App

From `D:\SafeMyanmar\mobile`, replace the device ID with the ID shown by
`flutter devices`:

```powershell
Set-Location D:\SafeMyanmar\mobile
flutter run -d YOUR_PHONE_SERIAL `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000 `
  --dart-define=MAPBOX_PUBLIC_ACCESS_TOKEN=YOUR_PUBLIC_MAPBOX_TOKEN
```

Every `--dart-define` must use this format:

```text
--dart-define=NAME=VALUE
```

The Mapbox token is optional. Omit that flag if map tiles are not needed.

## 5. Provision Gemma On The Phone

The Gemma model is not bundled into the APK. Install the debug app first, then
copy the authorized model pair into the app-private directory:

```powershell
& $adb -s $deviceId shell run-as org.safemyanmar.mobile mkdir -p files/ai
& $adb -s $deviceId shell mkdir -p /data/local/tmp/safemyanmar-ai

& $adb -s $deviceId push `
  "D:\SafeMyanmar\ai_models\gemma3-1b-it-int4.litertlm" `
  /data/local/tmp/safemyanmar-ai/
& $adb -s $deviceId push `
  "D:\SafeMyanmar\ai_models\gemma3-1b-it-int4.json" `
  /data/local/tmp/safemyanmar-ai/

& $adb -s $deviceId shell run-as org.safemyanmar.mobile cp `
  /data/local/tmp/safemyanmar-ai/gemma3-1b-it-int4.litertlm files/ai/
& $adb -s $deviceId shell run-as org.safemyanmar.mobile cp `
  /data/local/tmp/safemyanmar-ai/gemma3-1b-it-int4.json files/ai/

& $adb -s $deviceId shell run-as org.safemyanmar.mobile ls -lh files/ai
& $adb -s $deviceId shell am force-stop org.safemyanmar.mobile
```

The expected files are:

```text
files/ai/gemma3-1b-it-int4.litertlm
files/ai/gemma3-1b-it-int4.json
```

The model is approximately 557 MB. Keep the phone connected during transfer.
The manifest must contain the SHA-256 checksum of the exact model file.

## 6. Provision The ONNX Demo Model

Generate the project-owned development classifier from the repository root:

```powershell
python -m pip install --target "$env:TEMP\safemyanmar-onnx" onnx==1.20.0
$env:PYTHONPATH = "$env:TEMP\safemyanmar-onnx"
python tools/create_demo_onnx_model.py
```

Copy the generated pair into the same app-private directory:

```powershell
& $adb -s $deviceId push `
  "D:\SafeMyanmar\ai_models\intent_classifier.onnx" `
  /data/local/tmp/safemyanmar-ai/
& $adb -s $deviceId push `
  "D:\SafeMyanmar\ai_models\intent_classifier.json" `
  /data/local/tmp/safemyanmar-ai/
& $adb -s $deviceId shell run-as org.safemyanmar.mobile cp `
  /data/local/tmp/safemyanmar-ai/intent_classifier.onnx files/ai/
& $adb -s $deviceId shell run-as org.safemyanmar.mobile cp `
  /data/local/tmp/safemyanmar-ai/intent_classifier.json files/ai/
& $adb -s $deviceId shell am force-stop org.safemyanmar.mobile
```

This classifier is a development demonstration only. It refines unknown
intent results; it does not generate emergency guidance. Replace it with an
authorized, evaluated model before deployment.

## 7. Test The App

Open **Guide**, then **Offline assistant**. The capability banner should report
that local Gemma 3 is available.

Try these questions:

```text
What is the difference between a flood and an earthquake?
```

```text
What should I pack in an emergency kit?
```

```text
Tell me a joke.
```

The response should show:

```text
Response engine: local Gemma 3 assistant
```

Critical questions about trapped people, first aid, SOS, or safe routes remain
deterministic by design.

## 8. USB Tunnel Behavior

The backend tunnel depends on the USB/ADB connection. If the phone is unplugged,
repeat the reverse command after reconnecting:

```powershell
& $adb -s $deviceId reverse tcp:8000 tcp:8000
```

Gemma itself runs locally on the phone and does not require the backend or USB
after its model files have been provisioned.

## Troubleshooting

### `adb` is not recognized

Use the full path:

```powershell
& "C:\Users\USER\AppData\Local\Android\Sdk\platform-tools\adb.exe" devices
```

### `INSTALL_FAILED_USER_RESTRICTED`

Unlock the phone and enable **Install via USB** in Developer Options. Reconnect
the cable and accept any installation or USB debugging prompt.

### Backend requests fail

Check all three conditions:

- FastAPI is running on `127.0.0.1:8000`.
- `adb reverse tcp:8000 tcp:8000` is active.
- Flutter uses `API_BASE_URL=http://127.0.0.1:8000`.

### Nearby-area analysis says the origin is outside simulation coverage

The current fictional navigation data supports two separate regions:

- Mandalay: latitude `21.9300-21.9900`, longitude `96.0600-96.1200`.
- Yangon: latitude `16.8000-16.9200`, longitude `96.0800-96.2000`.

Real Yangon GPS readings can be analyzed when simulation is enabled. Locations
outside both regions are rejected because the app does not present fictional
data as real nationwide hazard information. Nearby-area analysis does not need a
Mapbox Directions token; route suggestions do.

### Gemma is unavailable

Verify the model files:

```powershell
& $adb -s $deviceId shell run-as org.safemyanmar.mobile ls -lh files/ai
```

The app must be a debug build, both files must be present, and the manifest
checksum must match the model file.

### Mapbox class-loading warnings appear in logcat

Mapbox Maps Flutter 2.26.0 can print `ClassNotFoundException` and
`NoClassDefFoundError` messages for optional `com.mapbox.common` bridge classes
on Android. The resolved dependency tree already includes Mapbox Common, and
the same messages are present in the upstream plugin example. They are not an
application crash when the log continues with Mapbox renderer and surface
initialization messages.

SafeMyanmar uses an AppCompat activity theme because Mapbox's compass, logo, and
attribution platform widgets require an AppCompat theme. The app also enables
Android's back-invoked callback to avoid the related framework warning.

The following messages are normally device or SDK diagnostics rather than
SafeMyanmar failures:

- `MIUIInput`, `Surface`, `BufferQueue`, `gralloc`, and vendor property warnings;
- `userfaultfd` warnings;
- `WindowOnBackDispatcher` warnings from an older installed APK;
- `ApkAssets` cleanup messages when other applications are unloaded.

For a real Mapbox failure, look for a Mapbox map-load error, renderer creation
failure, or a blank map after the AppCompat theme change.
