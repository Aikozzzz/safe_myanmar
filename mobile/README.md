# SafeMyanmar Mobile

Android-only Flutter client for SafeMyanmar. It provides a five-tab Material 3
shell, live USGS earthquake list/detail screens, explicit foreground location,
an optional Mapbox map with validated navigation data, local SOS draft
preparation, bilingual offline Guide content, constrained assistance, secure
local profile/contact store, and Android-first Bluetooth SOS sharing.

Home presents a Safety Center of explicit navigation cards. SOS uses a
setup-and-review sequence with a readiness summary and exact outgoing preview.
Guide offers deterministic quick actions, while Map pairs its visible layers
with a legend and source-, timestamp-, cache-, and uncertainty-aware summaries.

This app is not an official warning, prediction, dispatch, medical, or
guaranteed-safety service. Navigation records are source-backed and may be
empty or stale; they do not guarantee safe places or routes. Follow authorized
local instructions and contact official emergency or medical services when
available.

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
with `--dart-define`. The backend must separately receive
`MAPBOX_DIRECTIONS_ACCESS_TOKEN` to generate route alternatives; it is a secret,
is never sent to Flutter, and an unset or invalid value leaves routing
unavailable while map and cached navigation screens remain usable.

## Language And Reviewed Content

Open **More > Language** to choose English or မြန်မာ. The explicit choice is
stored as only `en` or `my` in Android secure storage under the separate
`app_language_v1` key. It does not change the encrypted profile payload,
request location, require network access, or invalidate cached alerts,
navigation data, Guide records, or existing SOS draft bodies. Missing,
invalid, or temporarily unreadable preferences fall back to English; a failed
write keeps the previously active language and exposes a retry action.

The Burmese locale covers app-owned chrome, safety labels, reviewed Guide
titles/answers, deterministic assistant responses, and SOS/map controls.
Guide Burmese text is reviewed content stored with the article version. The
optional Gemma path receives the selected language and is discarded when its
output is empty, unsafe, English-only, or not reliably Burmese; deterministic
reviewed content remains the fallback. Gemma is never used to decide critical
medical, trapped-person, SOS, or route actions.

Live provider names, places, alert descriptions, map-derived candidate names,
and other unreviewed dynamic fields remain in their original form. Burmese
screens identify that boundary instead of silently machine-translating
safety-critical provider text. Proper names, URLs, phone numbers, coordinates,
and model identifiers are preserved.

## Permissions And Privacy

- The app manifest declares Internet, coarse/fine location, Android BLE
  scan/advertise/connect, notification, and connected-device foreground-service
  permissions. BLE permissions are requested only when the user enables nearby
  SOS sharing or receiving.
  The merged Android manifest also includes transitive
  `ACCESS_NETWORK_STATE` and `ACCESS_WIFI_STATE` permissions used by Mapbox and
  supporting SDKs to detect connectivity and Wi-Fi state. These do not grant
  access to Wi-Fi credentials or device location.
- Location is requested only after the user selects **Use my location** on Map.
  That choice is remembered; later launches restore location when OS permission
  remains granted, without a new in-app or system prompt.
- The Mapbox view uses a readable street-map style with a floating location
  action. Tapping the action or the user marker recenters the map and shows
  precision, coordinates, and capture-time details in a bottom sheet.
- The map legend lists only visible layers and never relies on color alone.
  Hazard and context summaries remain readable without map tiles and retain
  source, timestamp, cached-data, simulation, and uncertainty labels.
- The flow distinguishes not requested, requesting, approximate, precise,
  denied, permanently denied, service disabled, last known, and recoverable
  error states. Permanent denial and disabled services link to settings.
- No background location permission is declared or requested. Location is not
  continuously tracked.
- Mapbox SDK components can initialize and send SDK, device, and usage telemetry
  to Mapbox when the app starts, before location permission. SafeMyanmar does
  not provide device location to Mapbox at that point. Before the first
  **Use my location** choice, the Mapbox platform view is not constructed or
  centered; simulation shelter and hazard refreshes may still use the network
  without device location. Later launches reuse that choice while OS permission
  remains granted. Enabling location constructs and centers the remote map,
  disclosing the viewed map area to Mapbox. Exact origin coordinates are sent
  to the SafeMyanmar backend and
  then Mapbox Directions only after the user explicitly requests a route.
- The app requests Android `READ_PHONE_STATE` to identify active SIMs and
  `SEND_SMS` after explicit SOS confirmation. It does not request contacts or
  SMS read permissions. It sends the reviewed body through the selected SIM;
  carrier delivery is not verified.
- Optional Bluetooth SOS sharing is separately confirmed for each SOS. Location
  is excluded by default; the user must enable location sharing for that SOS,
  review the preview, and can continue without coordinates if location becomes
  unavailable. The frame broadcasts a structured temporary sender token,
  sequence, UTC timestamp, fixed-point coordinates when available,
  current/last-known location status, and battery value. The sender token is
  stored securely and rotates daily; it is an event correlation identifier, not
  authentication. Names, contacts, and message text are never broadcast.
  Advertising stops after ten minutes and is controlled by a foreground service
  notification. Coordinates received over Bluetooth are peer-supplied and
  unverified; the Map tab plots all retained located sources, supports selecting
  a source and fitting the camera to all markers, and the SOS details provide a
  Google Maps query link.
- Nearby SOS receiving is opt-in. Foreground receiving listens only while the
  app session has enabled it; the separate Android background receiver uses a
  visible connected-device foreground-service notification and restores only
  the persisted background preference. It validates frames natively, encrypts a
  bounded app-private queue, deduplicates event IDs, replaces older frames from
  the same sender, and sends an unverified notification for each new sender
  event. Tapping that notification opens the Map tab and focuses the retained
  event when it has coordinates. Background receiving never relays or uploads
  frames. A separate foreground-only relay opt-in can rebroadcast each valid
  frame once over Bluetooth; frames are limited to one relay hop and are not
  uploaded or dispatched. Optional sound is controlled by the foreground
  receiver.
- Profile, emergency contacts, and SOS drafts are stored locally with
  `flutter_secure_storage`. They are not uploaded by the implemented app.
- Alert/navigation caches and Guide articles use app-private Drift/SQLite
  storage. Exact location is included in an SOS draft only when available and
  disclosed before confirmation.

## Offline Behavior

- Drift schema v6 caches the latest successful earthquake snapshot and
  SIMULATION context-area, hazard, and route responses. Context and route cache
  entries are bound
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
  Drift and remain searchable offline. The selected locale determines which
  reviewed title and answer is shown.
- The deterministic assistant remains available offline and returns only
  approved article content or explicit navigation/SOS actions. Burmese
  questions use Burmese aliases and reviewed Burmese answers; unsupported or
  rejected generated output falls back to localized safe copy.
- Android nearby-SOS foreground notifications receive and persist the selected
  language when a broadcast or background receiver is started; existing
  notification channels may retain the label from their first creation.
- Secure profile, contacts, and SOS drafts remain local and available without a
  network, subject to platform secure-storage availability.
- Map tiles, fresh navigation data, live earthquake refresh, and Mapbox route
  generation need network access. Previously cached map data can still be shown
  with a warning; there is no bundled offline basemap. The map uses Mapbox
  satellite-streets imagery, displays the active broadcast area in orange, and
  displays nearby SOS sources as unverified red markers at the coordinates
  received in the BLE frame when location data is available. The source list
  below the map exposes timestamp, location status, battery, signal, protocol,
  and relay details for the selected event. RSSI is only an approximate
  proximity signal.
- Background SOS events are retained only until their advertised TTL and are
  capped at 64 encrypted app-private frames. Same-sender sequence high-water
  marks prevent delayed older frames from returning after replacement. Android
  may stop background scanning after force-stop, Bluetooth disablement,
  permission revocation, or device-specific battery restrictions; SafeMyanmar
  does not claim continuous detection.

## Feature Boundaries

- Home links to live USGS earthquake observations and details. These are
  informational, preliminary, and not a complete all-disaster warning feed.
- Map uses an explicit foreground or last-known location. The backend exposes
  the configured real snapshot with source and timestamp metadata. The current
  Yangon snapshot has no verified shelters. Nearby analysis requires a current
  hazard geometry for the selected disaster type, can use mapped building/tree
  data for earthquakes and terrain elevation for floods, and otherwise only
  excludes points intersecting current hazard geometry. It does not claim any
  area or route is safe. The UI presents up to three candidates, requires an
  explicit selection, and then displays up to three route alternatives. The
  selected context-area ID is sent explicitly; the backend revalidates it
  before requesting directions. Route cards show source, directions provider,
  profile, generated time, hazard-data time, ranking rationale, simulation
  state, and uncertainty. Missing token, stale data, unavailable destinations,
  and empty route results remain unavailable rather than becoming straight-line
  guidance. Fictional navigation records remain separately gated behind
  `ENABLE_SIMULATION_DATA=true`; `ENABLE_SIMULATION_ANALYSIS=true` is a
  backend-only development option that augments context-area analysis without
  adding simulation records to mobile hazard or shelter lists.
- Navigation DTOs preserve the backend's explicit `simulation` marker,
  including mixed real-plus-simulation analysis responses. The client displays
  the simulation label and accepts such responses only when the development
  `--dart-define=ENABLE_SIMULATION_DATA=true` opt-in is also supplied; real
  responses remain usable by default.
- SOS persists at most five drafts, suppresses equivalent active drafts within
  five minutes, previews shared data, and requires hold/accessibility
  confirmation. Status means prepared, SMS sending, SMS accepted by the device,
  SMS failed, composer opened, failed to open, or cancelled. Bluetooth sharing
  has independent broadcast status. Dual-SIM devices can select the sending SIM
  after confirmation and optionally remember the preferred subscription. Device
  acceptance does not verify carrier delivery.
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
checks ABI/resources, and initializes LiteRT-LM with CPU only. It falls back to
the deterministic Dart classifier whenever an artifact is missing, invalid,
unsupported, below threshold, or fails at runtime. Provisioning commands are
documented in the optional AI model provisioning guide.

Optional tiers are:

- Tier 1: always-available deterministic classifier and approved Drift content.
- Tier 2: optional ONNX refinement only when Tier 1 returns unknown.
- Tier 3: optional LiteRT-LM Gemma 3 answers for general questions and
  rewording of supplied verified English content; disaster context is supplied
  when available, while critical first-aid, trapped-person, SOS, and safer-route
  intents remain deterministic.

Provisioning details and manifest contracts are documented in
[`docs/architecture/optional-ai-model-provisioning.md`](../docs/architecture/optional-ai-model-provisioning.md).
Backend setup, simulation controls, complete test commands, and other limits are
in the root [`README.md`](../README.md).
