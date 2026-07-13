# SafeMyanmar Mobile

Android-only Flutter application for the current SafeMyanmar live-earthquake
vertical slice. It displays backend-normalized USGS earthquake information in
list/detail screens and preserves the last successful response in Drift for
cache-first and stale/offline presentation.

## Development

```powershell
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`API_BASE_URL` is a compile-time setting. Android emulator debug builds may use
`http://10.0.2.2:8000`. A physical device may deliberately use
`adb reverse tcp:8000 tcp:8000` with `http://127.0.0.1:8000` during debug
development. Production/release builds reject HTTP and require HTTPS; the
Android cleartext exception exists only under `android/app/src/debug` and is
limited to `localhost`, `127.0.0.1`, and `10.0.2.2`.

The app is earthquake information only. It is not an official warning or
prediction system and does not guarantee safety. See the root `README.md` for
backend setup, complete verification commands, current limitations, and the
deferred roadmap.
