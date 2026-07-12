# SafeMyanmar Live Earthquake Vertical Slice Design

## Status

Approved conversational design, awaiting review of this written specification.

## Purpose

The first SafeMyanmar implementation increment will establish a runnable
Flutter Android application and FastAPI/PostgreSQL backend through one complete
vertical slice: live earthquake information for Myanmar.

This increment proves the project architecture, live-provider ingestion,
backend normalization, mobile caching, offline presentation, accessibility,
and automated testing before safety-critical SOS and Rescue Beacon work begins.

## Governing Requirements

The following sources govern this increment:

1. `SafeMyanmar.pdf` defines the academic disaster-response application and
   required mobile, context-aware, edge, cloud, AI, and HPC concepts.
2. `README.md` defines the selected Flutter/FastAPI/PostgreSQL stack and broad
   product scope.
3. `AGENTS.md` defines mandatory safety, privacy, offline, testing, and
   engineering constraints.
4. `DESIGN.md` is an OpenCode marketing-site specification. It is visual
   inspiration only and does not override mobile safety or accessibility.

Where requirements conflict, the assignment requirements govern product scope
and `AGENTS.md` governs safety and privacy.

## Scope

### Included

- Flutter Android application scaffold.
- Riverpod state management and dependency injection.
- `go_router` navigation.
- Localization-ready user-facing strings.
- SafeMyanmar light and dark Material themes.
- Drift/SQLite local alert cache with migrations.
- FastAPI application scaffold.
- Pydantic request and response schemas.
- SQLAlchemy and PostgreSQL persistence.
- Alembic migrations.
- Health and readiness endpoints.
- Live USGS earthquake-feed ingestion.
- Geographic filtering for Myanmar and a documented border buffer.
- Normalized SafeMyanmar alert API.
- Mobile earthquake list and detail screens.
- Source, magnitude, depth, location, event time, update time, review status,
  and source-link presentation.
- Explicit live, cached, stale, empty, and unavailable states.
- Unit, widget, API, migration, and integration tests.
- Setup, architecture, API, and data-source documentation.

### Excluded

- Bundled, seeded, or visible simulated alerts.
- Map rendering, geocoding, and directions.
- Mapbox token configuration.
- Shelters and hazard zones.
- Location permissions or user-location collection.
- SOS and emergency contacts.
- Rescue Beacon Mode.
- First-aid content.
- Cloud AI and the offline assistant.
- Push notifications.
- Authentication.
- Damage reporting.
- Official rescue-service integration.

Automated tests may use local fixtures. Test fixtures must never appear in a
running development or release application.

## External Data Source

The first provider is the USGS Earthquake Hazards Program production GeoJSON
feed:

`https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson`

The backend, not the mobile application, retrieves this feed. It polls no more
frequently than the provider's documented one-minute update interval.

USGS records are earthquake observations. SafeMyanmar must describe them as
"Earthquake information," not official Myanmar warnings, evacuation orders,
or earthquake predictions.

Every displayed record includes:

- USGS as the source;
- the original USGS event URL;
- provider event ID;
- magnitude;
- depth in kilometres;
- provider place description;
- event time;
- provider update time;
- review status where supplied;
- retrieval time;
- a notice that preliminary values may change.

No USGS result is not proof that no danger exists. Empty results and provider
failure are represented differently.

## Geographic Filtering

The backend filters global USGS records using an approximate Myanmar bounding
box plus a 1.5-degree border buffer so nearby cross-border events are not
silently omitted. Sprint 1 uses these inclusive coverage bounds:

- minimum latitude: `8.284`;
- maximum latitude: `30.043`;
- minimum longitude: `90.689`;
- maximum longitude: `102.676`.

These values will be named configuration constants, documented, and covered by
boundary tests. They are a coarse retrieval boundary, not a political border
or an affected-area calculation.

Filtering uses earthquake coordinates only. It does not imply that the event
affected every place within Myanmar or that places outside the box are safe.

## Architecture

### Mobile

```text
mobile/
|-- lib/
|   |-- app/
|   |   |-- app.dart
|   |   |-- router.dart
|   |   |-- localization/
|   |   `-- theme/
|   |-- core/
|   |   |-- database/
|   |   |-- network/
|   |   `-- widgets/
|   |-- features/
|   |   `-- alerts/
|   |       |-- data/
|   |       |-- domain/
|   |       |-- application/
|   |       `-- presentation/
|   `-- main.dart
|-- test/
|-- integration_test/
`-- pubspec.yaml
```

The alert presentation consumes an `AlertRepository` contract. HTTP and Drift
implementations remain behind the repository boundary. Platform, persistence,
and network dependencies are injected so tests can use controlled fakes.

### Backend

```text
backend/
|-- alembic/
|-- app/
|   |-- api/v1/
|   |-- core/
|   |-- database/
|   |-- models/
|   |-- repositories/
|   |-- schemas/
|   |-- services/
|   |-- providers/usgs/
|   `-- main.py
|-- tests/
|-- alembic.ini
|-- Dockerfile
`-- requirements.txt
```

Routers handle HTTP concerns, services coordinate business behavior,
repositories own database operations, provider adapters normalize external
records, and Pydantic schemas define public contracts. ORM models are never
returned directly.

## Alert Contract

The public normalized alert representation contains:

- `id`: stable identifier formatted as `usgs:<provider_event_id>`;
- `provider`: `usgs`;
- `provider_event_id`;
- `kind`: `earthquake_information`;
- `title`;
- `place`;
- `magnitude`;
- `depth_km`;
- `latitude` and `longitude`;
- `event_at`;
- `provider_updated_at`;
- `retrieved_at`;
- `review_status` when available;
- `source_url`;
- `version`.

All timestamps are timezone-aware UTC values serialized as RFC 3339. The API
does not expose a generic severity value inferred from magnitude because that
would imply an impact assessment the first provider does not supply.

The list endpoint wraps records in this metadata envelope:

- `items`;
- `data_status`: `current` or `stale`;
- `last_successful_refresh_at`;
- `provider`: `usgs`.

`last_successful_refresh_at` is present even when `items` is empty, allowing the
client to distinguish a successful empty provider result from an unavailable
provider.

API item objects do not contain a `freshness` field. Mobile freshness is
derived from the envelope's `data_status`, whether records came from local
storage before refresh, and refresh success or failure.

## Data Flow

1. On an alert-list request, the backend refresh service retrieves the USGS
   production feed only when the last refresh attempt was at least 60 seconds
   ago.
2. The provider adapter validates each feature independently.
3. Valid records inside the configured geographic bounds are normalized.
4. Records are upserted by provider and provider event ID.
5. Provider update time prevents an older response from overwriting a newer
   stored record.
6. A successful provider response, including a valid empty response, updates
   `last_successful_refresh_at`.
7. The API returns normalized records and refresh metadata from PostgreSQL.
8. The mobile repository reads Drift first and displays cached records with
   their age.
9. The repository requests current records from SafeMyanmar's API.
10. Valid newer records are persisted transactionally and displayed as live.
11. A failed refresh leaves the previous cache intact and changes the visible
    availability/freshness state.

The API reports `data_status=current` when the last successful provider refresh
is no more than five minutes old. Older persisted results are returned with
`data_status=stale`. If provider refresh fails and no successful refresh has
ever been recorded, the API returns `503 Service Unavailable` rather than an
empty list.

## Mobile States

The alert feature distinguishes:

- initial loading with no cached records;
- live records refreshed successfully;
- cached records while refreshing;
- cached stale records after refresh failure;
- successful live response with no Myanmar events;
- provider or SafeMyanmar API unavailable with no cache;
- malformed local data or a non-recoverable storage failure.

Required wording:

- Empty successful result: "No recent earthquakes were found in the covered
  area. This does not guarantee there is no danger."
- Provider/API failure with no cache: "Live earthquake data unavailable."
- Cached records: identify them as cached and show the last successful update.
- Stale records: identify them as stale and show their age.

The application must never convert a network failure into a reassuring empty
state.

## Error Handling

### Provider Handling

- Use explicit connection and response timeouts.
- Reject invalid top-level responses.
- Reject malformed individual features without discarding other valid
  features.
- Do not coerce invalid coordinates, timestamps, magnitudes, or URLs into
  plausible values.
- Preserve existing PostgreSQL records if retrieval or normalization fails.
- Record safe operational metrics without logging complete provider payloads.

### API Handling

- Use a stable problem-details-style error body.
- Return `503 Service Unavailable` when provider refresh is unavailable and no
  successful provider refresh has ever been recorded.
- Never expose stack traces, database details, credentials, internal paths, or
  full external payloads.
- Include a request ID in errors and structured logs.

### Mobile Handling

- Preserve valid Drift data after HTTP, parsing, or storage refresh failure.
- Never replace cached content with a blank generic error screen.
- Retry only through explicit refresh or a controlled repository policy.
- Keep live, cached, stale, empty, and unavailable wording distinct.

## Visual Design

SafeMyanmar uses Material components and accessibility semantics. The OpenCode
design document contributes only its restrained warm-neutral palette, flat
surfaces, and information-first presentation.

Required deviations from `DESIGN.md`:

- Use a proportional font with verified Myanmar Unicode support.
- Do not require Berkeley Mono.
- Use Material icons with visible labels, not ASCII-only controls.
- Use at least 48 dp touch targets.
- Support text scaling without clipping or truncating essential information.
- Use semantic color together with text and icons.
- Implement complete light and dark themes.
- Use mobile spacing rather than 96 px marketing-page sections.

The earthquake list card presents, in order:

1. "Earthquake information" label and icon;
2. magnitude and place;
3. event time;
4. live/cached/stale status;
5. USGS source attribution.

The detail view adds depth, update/retrieval times, review status, source link,
and preliminary-data disclaimer.

## Mapbox Boundary

Mapbox is the selected provider for future map rendering, geocoding, and
directions. Sprint 1 must not add a Mapbox dependency or require a token because
it contains no map functionality.

Before the map increment, the user will provide `MAPBOX_ACCESS_TOKEN` through
local environment configuration. The token must not be committed. Future map
work must preserve Mapbox attribution and comply with caching and token-scope
requirements. Directions will be described as suggested routes based on
currently available information, never guaranteed safe routes.

## Testing Strategy

Implementation follows red-green-refactor. Each behavior receives a failing
test before production code is added.

### Backend Tests

- USGS feature normalization.
- Myanmar boundary inclusion and exclusion.
- Border-buffer boundary behavior.
- Stable provider ID mapping.
- Provider revision/update behavior.
- Malformed coordinate, timestamp, magnitude, geometry, and URL handling.
- Mixed valid and malformed feature handling.
- Provider timeout and non-success response handling.
- Older provider data cannot overwrite newer stored data.
- Alert list and detail API contracts.
- Empty successful response versus unavailable response.
- Safe error response and request ID.
- Alembic upgrade and downgrade behavior.
- PostgreSQL-backed repository integration.

### Mobile Tests

- Initial loading.
- Live records.
- Cached records shown before refresh.
- Stale cache after failed refresh.
- Empty successful response wording.
- Unavailable response wording.
- Source attribution and preliminary-data notice.
- Event and update timestamps.
- Light and dark theme contrast roles.
- Minimum touch targets.
- Screen-reader semantics.
- Large-text and narrow-screen layout.
- Cached records survive application restart.

### Contract Test

An integration fixture generated from the backend OpenAPI contract verifies
that the mobile DTO accepts the backend alert representation without silently
dropping required fields.

## Security And Privacy

- No location permission or user location is used in Sprint 1.
- No credentials are required for USGS.
- PostgreSQL credentials come from environment configuration.
- Production uses HTTPS.
- Release configuration rejects placeholder secrets and unsafe database URLs.
- Logs omit complete external payloads and any future sensitive data.
- `.env.example` contains placeholders only.

## Documentation

Sprint 1 updates or creates:

- root setup instructions;
- mobile setup and test commands;
- backend setup and test commands;
- environment-variable reference;
- architecture and data-flow documentation;
- normalized alert API documentation;
- USGS attribution and safety limitations;
- known limitations and deferred features.

## Acceptance Criteria

- Flutter Android app and FastAPI backend start using documented commands.
- PostgreSQL schema can be built from zero through Alembic.
- Backend retrieves and normalizes live USGS earthquake data.
- Running application contains no seeded or simulated alert records.
- Mobile displays Myanmar-area earthquake information from SafeMyanmar's API.
- Every record displays USGS attribution and relevant timestamps.
- Provider failure is not displayed as "no alerts."
- Cached records remain available after network or server failure.
- Cached and stale records are explicitly labeled with age.
- Malformed provider features do not crash ingestion or erase valid records.
- No wording claims prediction, guaranteed safety, or official Myanmar warning
  status.
- Automated tests cover backend, mobile, migration, and contract behavior.
- Formatting, static analysis, tests, builds, and startup smoke checks pass.
- Documentation matches the implemented commands and behavior.

## Later Increments

After this slice passes review:

1. reviewed offline first-aid content;
2. foreground location permission and last-known location;
3. shelters and Mapbox map/directions integration;
4. idempotent offline SOS queue and authenticated backend receipt;
5. foreground Rescue Beacon Mode;
6. explainable context recommendations;
7. constrained offline assistant and cloud-AI adapter;
8. trusted notifications and additional providers such as Myanmar DMH and
   GDACS.
