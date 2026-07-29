# SafeMyanmar Mobile

Android-only Flutter client for SafeMyanmar. It provides a five-tab Material 3
shell, live USGS earthquake list/detail screens, explicit foreground location,
an optional Mapbox map with opt-in SIMULATION navigation data, local SOS draft
preparation, bilingual offline Guide content, constrained assistance, and a
secure local profile/contact store.

This app is not an official warning, prediction, dispatch, medical, or
guaranteed-safety service. SIMULATION shelters, hazards, and routes are fictional
demonstration data. Follow authorized local instructions and contact official
emergency or medical services when available.

## Run

From `mobile/`:

```powershell
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

The Map tab works without a Mapbox token but shows a configuration-unavailable
state instead of map tiles. To render the map, provide a restricted public
Mapbox token at compile time:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 `
  --dart-define=MAPBOX_PUBLIC_ACCESS_TOKEN=pk.replace_with_restricted_public_token
```

`API_BASE_URL` is required. Android emulator debug builds may use
`http://10.0.2.2:8000`. A physical device may deliberately use
`adb reverse tcp:8000 tcp:8000` with `http://127.0.0.1:8000` during debug
development. Production/release builds reject HTTP and require HTTPS. The
Android cleartext exception exists only under `android/app/src/debug` and is
limited to `localhost`, `127.0.0.1`, and `10.0.2.2`.

`MAPBOX_PUBLIC_ACCESS_TOKEN` is optional and is validated as a `pk.*` public
token. It is embedded in the built app, so restrict it by application/package
and allowed APIs and never substitute the backend Directions secret. Flutter
does not read root or backend `.env` files; both mobile settings must be passed
with `--dart-define`.

## Permissions And Privacy

- The app manifest declares Internet plus coarse and fine location permissions.
  The merged Android manifest also includes transitive
  `ACCESS_NETWORK_STATE` and `ACCESS_WIFI_STATE` permissions used by Mapbox and
  supporting SDKs to detect connectivity and Wi-Fi state. These do not grant
  access to Wi-Fi credentials or device location.
- Location is requested only after the user selects **Use my location** on Map.
- The flow distinguishes not requested, requesting, approximate, precise,
  denied, permanently denied, service disabled, last known, and recoverable
  error states. Permanent denial and disabled services link to settings.
- No background location permission is declared or requested. Location is not
  continuously tracked.
- Mapbox SDK components can initialize and send SDK, device, and usage telemetry
  to Mapbox when the app starts, before location permission. SafeMyanmar does
  not provide device location to Mapbox at that point. Before permission, the
  Mapbox platform view is not constructed or centered; simulation shelter and
  hazard refreshes may still use the network without device location. Enabling
  location constructs and centers the remote map, disclosing the viewed map area
  to Mapbox. Exact origin coordinates are sent to the SafeMyanmar backend and
  then Mapbox Directions only after the user explicitly requests a route.
- The app does not request Android SMS or contacts permission. It opens an
  external `sms:` composer with user-selected recipients and a reviewed body.
- Profile, emergency contacts, and SOS drafts are stored locally with
  `flutter_secure_storage`. They are not uploaded by the implemented app.
- Alert/navigation caches and Guide articles use app-private Drift/SQLite
  storage. Exact location is included in an SOS draft only when available and
  disclosed before confirmation.

## Offline Behavior

- Drift schema v4 caches the latest successful earthquake snapshot and
  SIMULATION shelter, hazard, and route responses. Route cache entries are bound
  to a practical-precision origin, shelter, disaster, and travel profile; v3
  route payloads are preserved during migration, then ignored and cleared on
  first access because they have no safe request context. Remote failures retain
  only matching cached data and show cached/stale timestamps and warnings.
- Cached shelter details load before any location request, remain available
  when permission or GPS is unavailable, and refresh in the background when the
  backend is reachable.
- A successful empty earthquake response remains distinct from a provider or
  network failure. Alert data older than the backend freshness threshold is
  shown as stale.
- Guide articles are versioned, source-backed English/Myanmar records seeded in
  Drift and remain searchable offline.
- The deterministic assistant remains available offline and returns only
  approved article content or explicit navigation/SOS actions.
- Secure profile, contacts, and SOS drafts remain local and available without a
  network, subject to platform secure-storage availability.
- Map tiles, fresh simulation data, live earthquake refresh, and Mapbox route
  generation need network access. Previously cached map data can still be shown
  with a warning; there is no bundled offline basemap.

## Feature Boundaries

- Home links to live USGS earthquake observations and details. These are
  informational, preliminary, and not a complete all-disaster warning feed.
- Map uses an explicit foreground or last-known location. The backend's
  shelters and hazards exist only when `ENABLE_SIMULATION_DATA=true`; all are
  fictional and labeled SIMULATION. Route selection displays up to three ranked
  alternatives but does not claim any route is safe.
- SOS persists at most five drafts, suppresses equivalent active drafts within
  five minutes, previews shared data, and requires hold/accessibility
  confirmation. Status means prepared, composer opened, failed to open, or
  cancelled. The app cannot verify SMS sent or delivered status.
- Guide contains a limited reviewed set, not diagnosis or comprehensive medical
  instructions. Source, content version, review date, and translation warning
  remain visible.
- More stores one local display name and up to ten contacts. Selecting a contact
  for SOS does not send or share anything by itself.
- The transitive Mapbox Android SDK declares GLES 3 as a required device
  feature, so Android can treat GLES 3 support as an install requirement even
  though Guide and SOS do not need the map. Supporting those offline features
  on older devices requires a future no-map product flavor; that flavor is not
  implemented in this build.

## Optional AI Artifacts

No ONNX or LiteRT-LM model is bundled and the app contains no model downloader,
model credentials, or remote AI API. Android checks only fixed app-private paths
under `filesDir/ai`, validates schema-v1 manifests and exact SHA-256 checksums,
and falls back to the deterministic Dart classifier whenever an artifact is
missing, invalid, unsupported, below threshold, or fails at runtime.

Optional tiers are:

- Tier 1: always-available deterministic classifier and approved Drift content.
- Tier 2: optional ONNX refinement only when Tier 1 returns unknown.
- Tier 3: optional LiteRT-LM rewording of supplied verified English content;
  critical first-aid, trapped-person, SOS, and safer-route intents are excluded.

Provisioning details and manifest contracts are documented in
[`docs/architecture/optional-ai-model-provisioning.md`](../docs/architecture/optional-ai-model-provisioning.md).
Backend setup, simulation controls, complete test commands, and other limits are
in the root [`README.md`](../README.md).
