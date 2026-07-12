# Live Earthquake Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter Android client and FastAPI/PostgreSQL backend that display live USGS earthquake information for Myanmar, preserve clearly labelled cached data when connectivity fails, and never ship simulated runtime records.

**Architecture:** A FastAPI provider adapter validates and normalizes the USGS GeoJSON feed, then a service transactionally upserts current events and refresh metadata into PostgreSQL. A Flutter Riverpod repository reads Drift first, refreshes through the normalized API, and exposes explicit live, cached, stale, empty, and unavailable states to accessible list/detail screens.

**Tech Stack:** Python 3.13, FastAPI, Pydantic 2, SQLAlchemy 2, Psycopg 3, Alembic, PostgreSQL 16, HTTPX, Pytest, Ruff, Flutter stable, Dart, Riverpod, go_router, Drift/SQLite, package:http, flutter_test, Docker Compose.

## Global Constraints

- Use only live USGS data in the running application; bundled, seeded, or visible simulated alerts are prohibited.
- Test fixtures are allowed only under test directories and must not be imported by runtime code.
- Describe records as `Earthquake information`, never official Myanmar warnings, evacuation orders, or predictions.
- Use inclusive coverage bounds: latitude `8.284..30.043`, longitude `90.689..102.676`.
- Poll USGS no more frequently than once every 60 seconds.
- API data is `current` when the latest successful refresh is no more than five minutes old; older persisted data is `stale`.
- Provider failure with no previous successful refresh returns `503 Service Unavailable`, not an empty list.
- A successful empty provider response records `last_successful_refresh_at` and returns an empty `items` list.
- Never infer a generic impact severity from earthquake magnitude.
- Build each normalized alert ID exactly as `usgs:<provider_event_id>`.
- API item objects do not contain `freshness`; mobile freshness is derived from the API envelope and local-cache state.
- Store and serialize all timestamps as timezone-aware UTC RFC 3339 values.
- A failed provider or mobile refresh must not erase valid persisted data.
- Use at least 48 dp touch targets, text-plus-icon status communication, large-text support, screen-reader semantics, and light/dark themes.
- Do not add Mapbox or request `MAPBOX_ACCESS_TOKEN` in this increment.
- Do not add authentication, location permission, SOS, Beacon, first aid, AI, push notification, shelter, or routing behavior.
- Never log full provider payloads, credentials, stack traces in API responses, or internal paths.
- Follow red-green-refactor: every production behavior must be preceded by a test that fails for the expected reason.
- Do not commit or initialize Git unless the user explicitly authorizes it.

---

## File Map

### Backend

- `backend/app/main.py`: FastAPI application factory and router registration.
- `backend/app/core/config.py`: validated environment configuration and constants.
- `backend/app/core/errors.py`: stable API error model and handlers.
- `backend/app/core/request_id.py`: request ID middleware.
- `backend/app/database/base.py`: SQLAlchemy declarative base.
- `backend/app/database/session.py`: engine and session factory.
- `backend/app/models/earthquake.py`: persisted normalized event.
- `backend/app/models/provider_sync.py`: USGS refresh-attempt and successful-refresh metadata.
- `backend/app/providers/usgs/client.py`: HTTP retrieval with explicit timeout.
- `backend/app/providers/usgs/normalizer.py`: per-feature validation and geographic filtering.
- `backend/app/repositories/earthquakes.py`: upsert and query operations.
- `backend/app/services/earthquakes.py`: refresh throttle, transaction, and staleness policy.
- `backend/app/schemas/earthquakes.py`: normalized public contracts.
- `backend/app/api/v1/alerts.py`: list and detail routes.
- `backend/app/api/health.py`: liveness and readiness routes.
- `backend/alembic/versions/0001_earthquake_cache.py`: initial reversible schema.
- `backend/tests/`: unit, API, repository, and migration tests.

### Mobile

- `mobile/lib/app/app.dart`: root `MaterialApp.router`.
- `mobile/lib/app/router.dart`: alert list/detail routes.
- `mobile/lib/app/theme/safe_theme.dart`: light and dark Material themes.
- `mobile/lib/core/database/app_database.dart`: Drift database and migration.
- `mobile/lib/core/network/api_config.dart`: compile-time API base URL validation.
- `mobile/lib/features/alerts/domain/earthquake.dart`: immutable domain model.
- `mobile/lib/features/alerts/domain/alert_repository.dart`: repository contract.
- `mobile/lib/features/alerts/data/alert_dto.dart`: normalized API parsing.
- `mobile/lib/features/alerts/data/alert_local_source.dart`: Drift reads/upserts.
- `mobile/lib/features/alerts/data/alert_remote_source.dart`: HTTP list/detail client.
- `mobile/lib/features/alerts/data/alert_repository_impl.dart`: cache-first coordination.
- `mobile/lib/features/alerts/application/alert_list_controller.dart`: Riverpod list state.
- `mobile/lib/features/alerts/presentation/alert_list_screen.dart`: explicit state UI.
- `mobile/lib/features/alerts/presentation/alert_detail_screen.dart`: source and limitation details.
- `mobile/lib/l10n/app_en.arb`: user-facing English strings.
- `mobile/test/`: domain, parsing, repository, controller, widget, theme, and semantics tests.

---

### Task 1: Backend Foundation And Health Contract

**Files:**
- Create: `backend/requirements.txt`
- Create: `backend/pyproject.toml`
- Create: `backend/.env.example`
- Create: `backend/app/__init__.py`
- Create: `backend/app/main.py`
- Create: `backend/app/core/config.py`
- Create: `backend/app/core/errors.py`
- Create: `backend/app/core/request_id.py`
- Create: `backend/app/api/health.py`
- Create: `backend/tests/conftest.py`
- Create: `backend/tests/api/test_health.py`
- Create: `backend/Dockerfile`
- Create: `docker-compose.yml`

**Interfaces:**
- Produces: `create_app() -> FastAPI`.
- Produces: `Settings` with `database_url`, `usgs_feed_url`, `provider_timeout_seconds`, `refresh_minimum_seconds`, and `current_max_age_seconds`.
- Produces: `GET /health/live` and `GET /health/ready`.

- [ ] **Step 1: Write failing health tests**

```python
def test_liveness_returns_ok(client):
    response = client.get("/health/live")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_unknown_route_uses_safe_error_shape(client):
    response = client.get("/missing")
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"
    assert response.json()["error"]["request_id"]
```

- [ ] **Step 2: Run the focused tests and verify RED**

Run: `py -3.13 -m venv backend/.venv`, install `backend/requirements.txt`, then run `backend/.venv/Scripts/python -m pytest backend/tests/api/test_health.py -v`.

Expected: collection fails because `app.main` does not exist.

- [ ] **Step 3: Add pinned dependency ranges and validated settings**

Use these ranges in `backend/requirements.txt`:

```text
fastapi>=0.115,<1
pydantic>=2.10,<3
pydantic-settings>=2.7,<3
sqlalchemy>=2.0,<3
psycopg[binary]>=3.2,<4
alembic>=1.14,<2
httpx>=0.28,<1
uvicorn[standard]>=0.34,<1
pytest>=8,<9
ruff>=0.9,<1
```

Set exact defaults:

```python
usgs_feed_url = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson"
provider_timeout_seconds = 10.0
refresh_minimum_seconds = 60
current_max_age_seconds = 300
```

- [ ] **Step 4: Implement request IDs, safe errors, application factory, and health routes**

The unknown-route response must be:

```json
{
  "error": {
    "code": "not_found",
    "message": "The requested resource was not found.",
    "request_id": "<non-empty value>"
  }
}
```

- [ ] **Step 5: Verify GREEN and lint**

Run:

```powershell
backend/.venv/Scripts/python -m pytest backend/tests/api/test_health.py -v
backend/.venv/Scripts/python -m ruff format --check backend
backend/.venv/Scripts/python -m ruff check backend
```

Expected: all commands pass without warnings.

- [ ] **Step 6: Add Docker development services**

Create PostgreSQL 16 and API services. The database health check must use `pg_isready`; the API must wait for healthy PostgreSQL. No demo seed service is allowed.

- [ ] **Step 7: Record task checkpoint**

Record changed files and verification output in the subagent report. Do not commit without explicit authorization.

---

### Task 2: USGS Normalization And Geographic Filtering

**Files:**
- Create: `backend/app/providers/__init__.py`
- Create: `backend/app/providers/usgs/__init__.py`
- Create: `backend/app/providers/usgs/models.py`
- Create: `backend/app/providers/usgs/normalizer.py`
- Create: `backend/app/schemas/earthquakes.py`
- Create: `backend/tests/fixtures/usgs_mixed_feed.json`
- Create: `backend/tests/providers/test_usgs_normalizer.py`

**Interfaces:**
- Produces: `normalize_feed(payload: dict[str, object], retrieved_at: datetime) -> NormalizationResult`.
- Produces: `NormalizedEarthquake` with provider ID, title, place, magnitude, depth, coordinates, event/update times, review status, source URL, and retrieved time.
- Produces: `NormalizationResult(events: tuple[NormalizedEarthquake, ...], rejected_count: int)`.

- [ ] **Step 1: Write failing normalization tests**

Cover one valid in-bounds feature, one outside feature, one malformed feature, and exact inclusive boundary values. Assert that malformed records increase `rejected_count` while valid records survive.

```python
result = normalize_feed(payload, retrieved_at)
assert [event.provider_event_id for event in result.events] == ["us7000test"]
assert result.rejected_count == 1
assert result.events[0].kind == "earthquake_information"
```

- [ ] **Step 2: Verify RED**

Run: `backend/.venv/Scripts/python -m pytest backend/tests/providers/test_usgs_normalizer.py -v`.

Expected: import failure for the missing normalizer.

- [ ] **Step 3: Implement strict provider models and constants**

Define exact constants:

```python
MIN_LATITUDE = 8.284
MAX_LATITUDE = 30.043
MIN_LONGITUDE = 90.689
MAX_LONGITUDE = 102.676
PROVIDER = "usgs"
KIND = "earthquake_information"
```

Validate finite coordinates and magnitude, a three-element point geometry, millisecond epoch timestamps, and HTTPS USGS detail URLs. Preserve `review_status` as nullable text; do not infer severity.

Set the normalized ID to `usgs:<provider_event_id>` and preserve the USGS
`properties.title` value after validation rather than synthesizing impact copy.

- [ ] **Step 4: Implement per-feature rejection**

Invalid top-level GeoJSON raises `InvalidProviderPayload`. Invalid individual features are counted and skipped. A valid empty `features` list returns an empty result without error.

- [ ] **Step 5: Verify GREEN and run backend tests**

Run:

```powershell
backend/.venv/Scripts/python -m pytest backend/tests/providers/test_usgs_normalizer.py -v
backend/.venv/Scripts/python -m pytest backend/tests -v
```

Expected: all tests pass.

- [ ] **Step 6: Record task checkpoint**

Record changed files and test evidence. Do not commit without authorization.

---

### Task 3: PostgreSQL Cache And Reversible Migration

**Files:**
- Create: `backend/alembic.ini`
- Create: `backend/alembic/env.py`
- Create: `backend/alembic/script.py.mako`
- Create: `backend/alembic/versions/0001_earthquake_cache.py`
- Create: `backend/app/database/base.py`
- Create: `backend/app/database/session.py`
- Create: `backend/app/models/__init__.py`
- Create: `backend/app/models/earthquake.py`
- Create: `backend/app/models/provider_sync.py`
- Create: `backend/app/repositories/earthquakes.py`
- Create: `backend/tests/repositories/test_earthquake_repository.py`
- Create: `backend/tests/migrations/test_migrations.py`

**Interfaces:**
- Produces: `EarthquakeRepository.upsert_many(session, events) -> None`.
- Produces: `EarthquakeRepository.list_recent(session) -> list[Earthquake]`.
- Produces: `EarthquakeRepository.get(session, event_id) -> Earthquake | None`.
- Produces: `ProviderSyncRepository` operations for attempt and success timestamps.

- [ ] **Step 1: Write failing PostgreSQL repository tests**

Tests must run against the Compose PostgreSQL service, not SQLite. Verify insertion, newer update replacement, older update rejection, stable ID lookup, and empty storage.

```python
repository.upsert_many(session, [newer_event])
repository.upsert_many(session, [older_event])
stored = repository.get(session, newer_event.id)
assert stored.provider_updated_at == newer_event.provider_updated_at
assert stored.magnitude == newer_event.magnitude
```

- [ ] **Step 2: Verify RED**

Run `docker compose up -d postgres`, then run the repository test with `TEST_DATABASE_URL` pointing at the test database.

Expected: import or missing-table failure.

- [ ] **Step 3: Implement models and initial migration**

The earthquake table must have a unique `(provider, provider_event_id)` constraint and indexes on `event_at` and `provider_updated_at`. The provider-sync table has one row per provider with `last_attempt_at`, nullable `last_successful_refresh_at`, and nullable `last_error_code`.

- [ ] **Step 4: Implement upsert rules transactionally**

An incoming record updates an existing row only when `incoming.provider_updated_at > stored.provider_updated_at`. Equal and older records leave the stored row unchanged.

- [ ] **Step 5: Add migration round-trip test**

Upgrade from base to head, assert both tables and constraints exist, downgrade to base, then upgrade to head again.

- [ ] **Step 6: Verify GREEN**

Run repository and migration tests, then all backend tests. Expected: pass with no warnings.

- [ ] **Step 7: Record task checkpoint**

Record migration revision and test evidence. Do not commit without authorization.

---

### Task 4: Refresh Service And Provider Failure Semantics

**Files:**
- Create: `backend/app/providers/usgs/client.py`
- Create: `backend/app/services/earthquakes.py`
- Create: `backend/tests/providers/test_usgs_client.py`
- Create: `backend/tests/services/test_earthquake_service.py`

**Interfaces:**
- Produces: `UsgsClient.fetch() -> tuple[dict[str, object], datetime]`.
- Produces: `EarthquakeService.list_alerts(now: datetime) -> AlertCollection`.
- Produces: `AlertCollection(items, data_status, last_successful_refresh_at)`.

- [ ] **Step 1: Write failing client tests**

Use HTTPX `MockTransport` to verify the exact USGS URL, 10-second timeout configuration, successful JSON parsing, timeout classification as `provider_timeout`, non-2xx classification as `provider_unavailable`, and invalid JSON classification as `invalid_provider_payload`.

- [ ] **Step 2: Verify RED and implement minimal client**

Run the client tests, confirm expected import failure, implement, and rerun until green.

- [ ] **Step 3: Write failing service tests**

Cover:

- refresh occurs when no attempt exists;
- refresh is skipped when the last attempt is under 60 seconds old;
- valid empty feed records a successful refresh;
- successful events are upserted;
- failure with no success raises `LiveDataUnavailable`;
- failure with previous records returns stale records;
- success age `<=300` seconds is current;
- success age `>300` seconds is stale.

- [ ] **Step 4: Verify RED and implement service transaction**

The same transaction must upsert events and update successful-refresh metadata. Failed provider calls update attempt/error metadata without deleting events or changing the previous success timestamp.

- [ ] **Step 5: Verify GREEN and all backend tests**

Run focused client/service tests and the full backend suite. Expected: pass.

- [ ] **Step 6: Record task checkpoint**

Record test output and any provider assumptions. Do not commit without authorization.

---

### Task 5: Versioned Alert API And Live Smoke Test

**Files:**
- Create: `backend/app/api/v1/__init__.py`
- Create: `backend/app/api/v1/router.py`
- Create: `backend/app/api/v1/alerts.py`
- Modify: `backend/app/main.py`
- Modify: `backend/app/api/health.py`
- Create: `backend/tests/api/test_alerts.py`
- Create: `backend/tests/integration/test_live_usgs_smoke.py`

**Interfaces:**
- Produces: `GET /api/v1/alerts` list envelope.
- Produces: `GET /api/v1/alerts/{alert_id}` detail response.
- Consumes: `EarthquakeService.list_alerts(now)` and repository detail lookup.

- [ ] **Step 1: Write failing API contract tests**

Assert exact list keys:

```json
{
  "items": [],
  "data_status": "current",
  "last_successful_refresh_at": "2026-07-13T10:00:00Z",
  "provider": "usgs"
}
```

Assert each item contains exactly `id`, `provider`, `provider_event_id`, `kind`,
`title`, `place`, `magnitude`, `depth_km`, `latitude`, `longitude`, `event_at`,
`provider_updated_at`, `retrieved_at`, `review_status`, `source_url`, and
`version`. Assert item objects exclude `severity` and `freshness`. Verify 404
safe errors and 503 `live_data_unavailable` errors.

- [ ] **Step 2: Verify RED and implement routes/schemas**

Register routes under `/api/v1`, inject service/session dependencies, and serialize UTC timestamps with `Z`.

- [ ] **Step 3: Verify API GREEN**

Run `pytest backend/tests/api/test_alerts.py -v` and the full backend suite.

- [ ] **Step 4: Add opt-in live-provider smoke test**

Mark the test `live` and skip unless `RUN_LIVE_USGS_TESTS=1`. It may assert only protocol/schema behavior, not that an earthquake currently exists.

- [ ] **Step 5: Start backend and verify live behavior**

Run migrations and Uvicorn, then request `/health/ready` and `/api/v1/alerts`. Verify the response contains no fixture IDs and provider equals `usgs`.

- [ ] **Step 6: Record task checkpoint**

Record commands and sanitized response shape. Do not commit without authorization.

---

### Task 6: Flutter Scaffold, Theme, Localization, And Domain Contract

**Prerequisite:** Flutter stable must be installed and available on `PATH`. Stop and report a blocker if `flutter --version` fails.

**Files:**
- Create with Flutter tooling: `mobile/`
- Modify: `mobile/pubspec.yaml`
- Create: `mobile/l10n.yaml`
- Create: `mobile/lib/l10n/app_en.arb`
- Create: `mobile/lib/app/theme/safe_theme.dart`
- Create: `mobile/lib/features/alerts/domain/earthquake.dart`
- Create: `mobile/lib/features/alerts/domain/alert_repository.dart`
- Create: `mobile/test/app/theme/safe_theme_test.dart`
- Create: `mobile/test/features/alerts/domain/earthquake_test.dart`

**Interfaces:**
- Produces: `Earthquake` domain entity matching the API contract.
- Produces: `AlertRepository.watchCached()`, `refresh()`, and `getById()`.
- Produces: `SafeTheme.light()` and `SafeTheme.dark()`.

- [ ] **Step 1: Install Flutter and verify toolchain**

Run `flutter --version`, `flutter doctor -v`, and record the exact installed version. Resolve Android SDK blockers before creating the app.

- [ ] **Step 2: Scaffold Android-only Flutter project**

Run `flutter create --platforms=android --org org.safemyanmar mobile`.

- [ ] **Step 3: Add dependencies**

Add `flutter_riverpod`, `go_router`, `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`, `http`, `intl`, `json_annotation`, and dev dependencies `drift_dev`, `build_runner`, `json_serializable`. Commit the generated lockfile only if Git is later authorized.

- [ ] **Step 4: Write failing domain and theme tests**

Test UTC enforcement, nullable review status, no severity field, Material 3 light/dark brightness, 48 dp minimum button size, and high-contrast primary text roles.

- [ ] **Step 5: Verify RED**

Run focused Flutter tests. Expected: missing domain/theme imports.

- [ ] **Step 6: Implement minimal domain, repository contract, localization, and themes**

Use localized strings for every visible label. Do not bundle Berkeley Mono; use a Myanmar-capable system fallback until a separately licensed bundled font is selected.

- [ ] **Step 7: Verify GREEN**

Run `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, and focused tests from `mobile/`.

- [ ] **Step 8: Record task checkpoint**

Record Flutter/Android versions and verification output. Do not commit without authorization.

---

### Task 7: Drift Cache And Normalized API Client

**Files:**
- Create: `mobile/lib/core/database/app_database.dart`
- Create: `mobile/lib/core/database/app_database.g.dart` through build runner
- Create: `mobile/lib/core/network/api_config.dart`
- Create: `mobile/lib/features/alerts/data/alert_dto.dart`
- Create: `mobile/lib/features/alerts/data/alert_local_source.dart`
- Create: `mobile/lib/features/alerts/data/alert_remote_source.dart`
- Create: `mobile/test/features/alerts/data/alert_dto_test.dart`
- Create: `mobile/test/features/alerts/data/alert_local_source_test.dart`
- Create: `mobile/test/features/alerts/data/alert_remote_source_test.dart`

**Interfaces:**
- Produces: `AlertDto.fromJson(Map<String, Object?>)` and `toDomain()`.
- Produces: `AlertLocalSource.readAll()`, `replaceIfNewer()`, and sync-metadata operations.
- Produces: `AlertRemoteSource.fetchAlerts()` returning items plus API freshness metadata.

- [ ] **Step 1: Write failing DTO tests**

Verify all required fields, RFC 3339 timestamps, nullable review status, missing-field rejection, and absence of severity inference.

- [ ] **Step 2: Verify RED and implement DTO**

Run focused test, confirm expected import failure, implement, and rerun green.

- [ ] **Step 3: Write failing Drift tests**

Use an in-memory native database. Verify empty read, transactional replace/upsert, older API records cannot overwrite newer records, refresh metadata persistence, and data surviving database recreation through a file-backed integration test.

- [ ] **Step 4: Verify RED and implement schema/source**

Database schema version is `1`. Store source/update/retrieval timestamps and the API's last successful refresh time. Do not include demo rows or seed callbacks.

- [ ] **Step 5: Write failing remote-source tests**

Use a fake `http.Client` to verify current, stale, empty, 503, malformed JSON, and timeout behavior. The base URL comes from `--dart-define=API_BASE_URL=...` and fails with an actionable message if absent outside tests.

- [ ] **Step 6: Implement remote source and verify GREEN**

Run build runner, format, analyze, and all Task 7 tests.

- [ ] **Step 7: Record task checkpoint**

Record generated files and tests. Do not commit without authorization.

---

### Task 8: Cache-First Repository And Riverpod State Machine

**Files:**
- Create: `mobile/lib/features/alerts/data/alert_repository_impl.dart`
- Create: `mobile/lib/features/alerts/application/alert_list_state.dart`
- Create: `mobile/lib/features/alerts/application/alert_list_controller.dart`
- Create: `mobile/lib/features/alerts/application/providers.dart`
- Create: `mobile/test/features/alerts/data/alert_repository_impl_test.dart`
- Create: `mobile/test/features/alerts/application/alert_list_controller_test.dart`

**Interfaces:**
- Consumes: Task 7 local/remote sources.
- Produces: `AlertListState` with phase, records, freshness, last successful update, and safe error kind.
- Produces: Riverpod `alertListControllerProvider`.

- [ ] **Step 1: Write failing repository tests**

Verify cache emits before remote completion, successful current refresh persists and emits live records, successful empty refresh emits empty, failure with cache emits stale cache, failure without cache emits unavailable, and refresh never deletes cache on error.

- [ ] **Step 2: Verify RED and implement repository**

Keep cache coordination in the repository rather than widgets. Do not use connectivity status as proof that the internet or provider is reachable.

- [ ] **Step 3: Write failing controller tests**

Cover `loading`, `data`, `empty`, `cached`, `stale`, `unavailable`, and recoverable manual refresh. Assert exact user-facing state distinctions, not colors.

- [ ] **Step 4: Verify RED and implement controller/providers**

Inject clock, repository, HTTP client, and database providers so tests do not touch the network or disk unless explicitly integration-scoped.

- [ ] **Step 5: Verify GREEN**

Run focused repository/controller tests, all Flutter tests, formatting, and analysis.

- [ ] **Step 6: Record task checkpoint**

Record state transition coverage and verification output. Do not commit without authorization.

---

### Task 9: Accessible Alert List And Detail Screens

**Files:**
- Create: `mobile/lib/app/app.dart`
- Create: `mobile/lib/app/router.dart`
- Modify: `mobile/lib/main.dart`
- Create: `mobile/lib/features/alerts/presentation/alert_list_screen.dart`
- Create: `mobile/lib/features/alerts/presentation/alert_detail_screen.dart`
- Create: `mobile/lib/features/alerts/presentation/widgets/earthquake_card.dart`
- Create: `mobile/lib/features/alerts/presentation/widgets/data_status_banner.dart`
- Create: `mobile/test/features/alerts/presentation/alert_list_screen_test.dart`
- Create: `mobile/test/features/alerts/presentation/alert_detail_screen_test.dart`
- Create: `mobile/test/features/alerts/presentation/accessibility_test.dart`

**Interfaces:**
- Consumes: `alertListControllerProvider` and `AlertRepository.getById()`.
- Produces: `/alerts` and `/alerts/:id` routes.

- [ ] **Step 1: Write failing list widget tests**

Verify loading text, live records, successful empty wording, unavailable wording, cached/stale banner with age, refresh action, USGS attribution, 48 dp controls, and no `SIMULATION`, `prediction`, or inferred severity labels.

- [ ] **Step 2: Verify RED and implement list screen**

Card order is: Earthquake information icon/label, magnitude and place, event time, data status, USGS attribution. Use localized strings and semantic labels.

- [ ] **Step 3: Write failing detail widget tests**

Verify magnitude, depth, place, event/update/retrieval times, review status when present, HTTPS source action, and the exact preliminary-data limitation notice.

- [ ] **Step 4: Verify RED and implement detail/router/app shell**

Support light/dark themes, text scaling, narrow screens, safe areas, and restoration-safe ID routing. Do not pass mutable model objects through routes.

- [ ] **Step 5: Add semantics and large-text tests**

At 200% text scale, essential text must wrap without ellipsis or overflow. Screen-reader traversal must announce information type, magnitude/place, event time, freshness, and source.

- [ ] **Step 6: Verify GREEN**

Run all widget tests, `flutter test`, `flutter analyze`, and formatting.

- [ ] **Step 7: Record task checkpoint**

Record screenshots only if generated manually; do not add unrequested golden baselines. Do not commit without authorization.

---

### Task 10: End-To-End Verification And Documentation

**Files:**
- Create: `mobile/integration_test/live_alerts_test.dart`
- Create: `docs/architecture/live-earthquake-slice.md`
- Create: `docs/api/alerts.md`
- Modify: `README.md`
- Create or modify: `.env.example`

**Interfaces:**
- Verifies: backend OpenAPI response is accepted by mobile DTO and displayed through the real repository path.
- Documents: local setup, runtime configuration, safety limitations, and future Mapbox variable.

- [ ] **Step 1: Write failing contract/integration test**

Start the backend against PostgreSQL, use a controlled provider HTTP server containing test-only USGS protocol fixtures, and run the mobile integration test against the backend. Runtime application code must not reference the fixture server.

- [ ] **Step 2: Verify RED**

Expected: failure until integration configuration and app wiring are complete.

- [ ] **Step 3: Complete environment and integration wiring**

Root `.env.example` documents `API_BASE_URL` and `DATABASE_URL`. Mention `MAPBOX_ACCESS_TOKEN` as required only for the future map increment; do not read or validate it in Sprint 1.

- [ ] **Step 4: Update documentation**

Document exact setup commands, USGS attribution, geographic bounds, 60-second throttle, five-minute freshness threshold, provider-outage behavior, no-warning/prediction limitation, no runtime demo data, and deferred features.

- [ ] **Step 5: Run complete backend verification**

```powershell
backend/.venv/Scripts/python -m ruff format --check backend
backend/.venv/Scripts/python -m ruff check backend
backend/.venv/Scripts/python -m pytest backend/tests -v
docker compose build api
docker compose up -d postgres
docker compose run --rm api alembic upgrade head
```

Expected: all commands pass.

- [ ] **Step 6: Run complete mobile verification**

From `mobile/`:

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Expected: all commands pass and APK is created.

- [ ] **Step 7: Run startup and live-data smoke checks**

Start PostgreSQL and API, apply migrations, call health/readiness and alerts, launch Android app, and verify live USGS data or the correct successful-empty/unavailable state. Confirm no fixture or simulated record is visible.

- [ ] **Step 8: Run security and scope review**

Search runtime source for fixture imports, `SIMULATION`, hard-coded credentials, `MAPBOX_ACCESS_TOKEN` access, location permissions, and severity inference. Any runtime match requires review and removal unless it is user-facing prohibited-word documentation.

- [ ] **Step 9: Record final checkpoint**

Record every command actually run, its result, environment limitations, and known residual risks. Do not claim unrun checks passed and do not commit without authorization.

---

## Execution Dependencies

```text
Task 1 Backend foundation
  -> Task 2 USGS normalization
  -> Task 3 PostgreSQL cache
  -> Task 4 refresh service
  -> Task 5 alert API

Task 6 Flutter scaffold
  -> Task 7 Drift/API client
  -> Task 8 repository/state
  -> Task 9 screens

Tasks 5 and 9
  -> Task 10 integration/documentation
```

Backend Tasks 1-5 can be completed with the existing Python launcher and Docker. Mobile Tasks 6-10 are blocked until Flutter stable and the Android toolchain are installed and available on `PATH`.
