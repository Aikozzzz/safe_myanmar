Use three terminals: backend, health checks, and Flutter.
1. Start Docker
Open Docker Desktop and wait until it is running.
From D:\SafeMyanmar:
docker compose up -d db
2. Prepare The Backend
First-time setup:
Set-Location D:\SafeMyanmar

python -m venv backend\.venv
backend\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
Copy-Item backend\.env.example backend\.env
backend\.venv\Scripts\python.exe -m alembic -c backend\alembic.ini upgrade head
Start FastAPI:
Set-Location D:\SafeMyanmar\backend
.venv\Scripts\python.exe -m uvicorn app.main:app --reload
Keep this terminal open.
3. Verify The Backend
In another terminal:
Invoke-RestMethod http://localhost:8000/health/live
Invoke-RestMethod http://localhost:8000/health/ready
Invoke-RestMethod http://localhost:8000/api/v1/alerts
The health endpoints should return successful responses.
4. Start The Emulator
Open Android Studio, then:
1. Open Device Manager.
2. Start the Pixel API 36.1 emulator.
3. Wait until Android finishes booting.
Check its ID:
flutter devices
It should appear as something similar to:
emulator-5554
Do not select Chrome or Edge.
5. Run Flutter
Set-Location D:\SafeMyanmar\mobile

flutter pub get

flutter run -d emulator-5554 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
Replace emulator-5554 if flutter devices shows another ID.
The first Android build downloads SQLite’s native library from GitHub. If it times out, confirm connectivity:
curl.exe -I -L "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.5.0/libsqlite3.x64.android.so"
Then retry flutter run without running flutter clean.
6. Optional Mapbox Tiles
To enable the visual map, use a restricted Mapbox public token:
flutter run -d emulator-5554 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 `
  --dart-define=MAPBOX_PUBLIC_ACCESS_TOKEN=pk.replace_with_your_public_token
Without this token, alerts, SOS, Guide, profile, contacts, location states, and cached information still work. The Map tab displays a configuration message instead of map tiles.
Expected Warning
This warning is currently expected and does not prevent the build:
mapbox_maps_flutter applies Kotlin Gradle Plugin
Mapbox must remain pinned to 2.26.0 until its AGP 9 compatibility issue is resolved.