# Live Earthquake Vertical Slice Verification

## Current Status

Verification was recorded on 2026-07-13 for the SafeMyanmar live-earthquake
vertical slice. The latest authoritative backend suite result is **181 passed,
1 skipped** at commit `7de1ffb`; the skipped test is the separately invoked
opt-in live USGS smoke. The latest full mobile suite result is **171 passed**.
Flutter analysis passed, and a clean debug APK now builds successfully with the
tracked Kotlin reliability settings described below.

Backend, mobile non-device, Docker, live-USGS, startup, contract, security, and
debug APK checks passed as recorded below. Android device E2E did **not** run and
remains blocked for the exact reasons in [Android Blockers](#android-blockers).

This record is derived from the Task 10 verification report. It contains no
production secrets, raw credential-bearing database URLs, or test-provider
process details.

## Environment

| Item | Recorded environment |
|---|---|
| Date | 2026-07-13 |
| Host | Windows development host |
| Git workspace | Linked worktree on `feature/live-earthquake` |
| Flutter | Stable 3.44.6 |
| Dart | 3.12.2 |
| Docker | Docker Desktop 4.49.0, Engine 28.5.1 |
| Database verification | Dedicated PostgreSQL test database through Docker Compose |
| Android availability | No Android device and no available AVD |

## Commits Covered

| Commit | Material verification stage |
|---|---|
| `a57fcf3` | Initial end-to-end tooling, documentation, Docker, live-provider, startup, security, and mobile non-device verification |
| `dd7111d` | Release/configuration hardening, exact OpenAPI provenance, Alembic precedence, and latest full mobile suite |
| `7de1ffb` | Production credential denial, deterministic integration environment, local-only API targeting, and bounded native-command cleanup |
| `33169d6` | Tracked verification record for the vertical slice evidence available before the APK stabilization |

## Commands Run

The dedicated test database URL used by backend tests is intentionally omitted.
Only the environment value is redacted; executable paths and command arguments
below match the report.

### Repository And Backend

```powershell
git rev-parse --git-dir
git rev-parse --git-common-dir
git branch --show-current

backend/.venv/Scripts/python -m ruff format --check backend
backend/.venv/Scripts/python -m ruff check backend

docker compose --profile integration up -d --wait integration-db
# TEST_DATABASE_URL was set to the dedicated test database before this command.
backend/.venv/Scripts/python -m pytest backend/tests -v

docker compose build api
docker compose up -d --wait db
docker compose run --rm api alembic upgrade head
docker compose config --quiet
```

### Live USGS Smoke

```powershell
$env:RUN_LIVE_USGS_TESTS = "1"
backend/.venv/Scripts/python -m pytest backend/tests/integration/test_live_usgs_smoke.py -v
```

### Mobile Non-Device Verification

```powershell
flutter gen-l10n
dart run build_runner build
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

### Clean Debug APK Verification

The normal existing Gradle home was retained. The following copy-paste block is
run from the repository root. If Flutter is installed outside
`$env:USERPROFILE\develop\flutter`, `$flutterBin` must be adjusted. The block
deliberately removes process-local `GRADLE_USER_HOME`; it must not point to an
empty isolated directory because the existing wrapper download in
`%USERPROFILE%\.gradle` is reused.

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

### Docker Cleanup

```powershell
docker compose --profile integration rm -f -s integration-db
docker compose down
```

Additional recorded checks used the Windows PowerShell 5.1 parser, exercised the
bounded native-command helper for success, timeout, exit-code, output, and
`docker compose config --quiet`, and checked accepted/rejected physical-device
URL boundaries. These checks passed. Their long inline shell expressions are not
reproduced because the report records results rather than stable standalone
commands.

## Latest Evidence

### Backend

- Full suite: **181 passed, 1 skipped** at `7de1ffb`.
- Focused configuration/security/harness suite: **32 passed**.
- Ruff formatting and lint checks passed.
- The production settings tests reject known Compose development credentials
  without including the URL, username, or password in validation output.
- Alembic honored `DATABASE_URL` when no explicit URL was configured, while an
  explicit Alembic URL retained precedence over the environment.
- Exact OpenAPI checks pinned the list envelope, alert item, endpoint response
  references, `provider=usgs`, and `kind=earthquake_information`, with no
  severity or freshness fields.

### Mobile And APK

- Latest full suite: **171 passed**.
- Localization generation and build-runner generation passed.
- Dart format completed with no changes and Flutter analysis reported no issues.
- The mobile contract test parsed the normalized backend response with the
  production DTO.
- Main/release Android configuration has no cleartext exception. Debug
  cleartext access is limited to `localhost`, `127.0.0.1`, and `10.0.2.2`.
- Android configuration tests require exact `kotlin.incremental=false` and
  `kotlin.compiler.execution.strategy=in-process` settings with their Windows
  cross-drive reliability rationale.
- After stopping Gradle and cleaning Flutter output, the debug APK build passed
  in 69.1 seconds and produced `build/app/outputs/flutter-apk/app-debug.apk`.

### Docker, Live, And Startup

- `docker compose config --quiet` passed.
- The API image built successfully.
- The development database became healthy and the API container ran Alembic to
  `head` successfully.
- The opt-in live USGS smoke passed **2 tests** against the default live feed and
  returned no controlled fixture records.
- Startup checks for `/health/live`, `/health/ready`, and `/api/v1/alerts`
  passed against migrated PostgreSQL.
- The startup alert response reported `provider=usgs` and
  `data_status=current`, contained zero in-bounds items at check time, and
  contained no fixture, simulation, or demo-record marker.
- Integration and development containers and the Compose network were removed
  after verification.

### Security And Scope

- Runtime isolation checks found no test fixture/server references, fixture ID,
  local fixture URL, simulation records, or Mapbox token access in
  `backend/app` or `mobile/lib`.
- At the time of this historical verification, the backend runtime default was
  the live USGS all-day feed. The current implementation uses the USGS FDSN
  catalog query for the Yangon Region latest-ten behavior.
- Real `.env` files remain ignored and untracked.
- Android main requests only Internet permission; it requests no location, SMS,
  call, camera, microphone, contacts, notification, or background permission.
- The integration harness accepts only the local emulator endpoint or local
  physical-device loopback endpoints mapped with `adb reverse`; remote API
  targets are rejected.
- Native adb and Compose integration calls have explicit timeouts, and cleanup
  continues after individual cleanup failures.

## Material Chronology

- Initial Docker checks were blocked until Docker Desktop was started; Docker
  verification then ran successfully.
- Initial container migration exposed that Alembic ignored the Compose database
  environment. The fix passed container migration, and a later precedence
  regression was corrected before the full backend suite passed.
- Release/configuration review added production HTTPS enforcement, deployment
  database validation, exact OpenAPI provenance, and local debug-only Android
  transport. The backend reached 175 passed with 1 skipped, and the latest full
  mobile suite reached 170 passed.
- Integration-isolation review added known development credential rejection,
  deterministic environment restoration, local-only API validation, dynamic
  physical-device reverse ports, and bounded native cleanup. The backend then
  reached the current 181 passed with 1 skipped.
- A native-helper smoke exposed an unset exit code for short-lived processes on
  Windows PowerShell 5.1. Materializing the process handle fixed it; subsequent
  bounded success, timeout, output, exit-code, Docker, and URL-boundary checks
  passed.
- A clean APK experiment isolated the remaining Kotlin failure to incremental
  cross-drive cache behavior. Disabling Kotlin incremental compilation and
  running the compiler in-process produced a successful clean debug APK while
  retaining the normal Gradle home.

## Android Blockers

### Device E2E

- `flutter devices` listed only Windows, Chrome, and Edge; no Android target was
  available.
- `flutter emulators` returned `No emulators available`.
- Therefore `tools/run-live-alerts-integration.ps1 -DeviceId <android-id>` was
  **not run**. The real Android app/API/Drift online-to-stale transition remains
  unverified on a device.

### Toolchain Warnings And APK Result

- `flutter doctor -v` reported missing Android `cmdline-tools`, unknown Android
  license status, and no Android device. It also reported missing Visual Studio
  desktop tooling, which is unrelated to this Android-only increment.
- The `cmdline-tools` and license warnings remain, but they did not block the
  clean debug build after the Kotlin reliability settings were tracked.
- The following required build command now **passes**:

  ```powershell
  flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
  ```

- Earlier attempts failed in `:url_launcher_android:compileDebugKotlin` with
  Kotlin 2.3.20 incremental-cache errors spanning the system Pub cache and
  worktree drives. The minimal tracked fix is now covered by an Android
  configuration regression test.
- The successful build used the normal Gradle home and placed `PUB_CACHE`,
  `TEMP`, and `TMP` under `.superpowers/android-build` on the worktree drive.
- APK assembly is verified; installation and execution remain unverified because
  no Android device or AVD is available.

## Limitations

- Android hardware/emulator execution is still required to verify persisted
  Drift continuity across process relaunch.
- The successful live startup snapshot was empty within the configured Myanmar
  bounds, so it does not demonstrate a populated live device UI.
- This slice provides earthquake information only. It is not an official
  warning or prediction system and does not guarantee safety.
