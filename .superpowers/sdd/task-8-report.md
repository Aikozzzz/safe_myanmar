# Task 8 Report: Cache-First Alert State

## Files

- Added `mobile/lib/features/alerts/data/alert_repository_impl.dart`.
- Added `mobile/lib/features/alerts/application/alert_list_state.dart`.
- Added `mobile/lib/features/alerts/application/alert_list_controller.dart`.
- Added `mobile/lib/features/alerts/application/providers.dart`.
- Extended `mobile/lib/features/alerts/domain/alert_repository.dart` with the backward-compatible `CachedAlertRepository` interface.
- Added repository and controller tests plus deterministic test fakes under `mobile/test/support/`.
- Updated `README.md` to describe the cache-first Riverpod alert state increment.

## RED Evidence

- Repository RED: `flutter test test/features/alerts/data/alert_repository_impl_test.dart` failed to compile because `alert_repository_impl.dart`, `AlertRepositoryImpl`, and `AlertStorageException` did not exist.
- Controller RED: `flutter test test/features/alerts/application/alert_list_controller_test.dart` failed to compile because the alert list state, controller, and providers did not exist.
- The first repository GREEN run exposed two incorrect timestamp expectations in the test fixture; expectations were corrected to the API's exact microseconds before GREEN was accepted.
- The first provider lifecycle run exposed that Drift's in-memory executor permits reads after close; database disposal was made injectable so the lifecycle callback could be asserted deterministically.

## State Transition Coverage

- Loading with no observed cache and an active initial refresh.
- Current cached data displayed before a blocked refresh as `cached` and refreshing.
- Stale cached data displayed before refresh as `stale` and refreshing.
- Current non-empty success to data/live.
- Stale non-empty success to data/stale.
- Current empty success to empty/live.
- Remote, protocol, and storage failure with cache to retained data/stale with a safe recoverable error kind.
- Remote, protocol, and storage failure without cache to unavailable.
- Manual recovery after failure.
- Duplicate concurrent refresh suppression.
- Cache stream updates during refresh without clearing `isRefreshing`.
- Stream cancellation and app-scoped HTTP/database lifecycle disposal.
- Immutable state items, value equality, nullable-field copy behavior, and safe state strings.

## Verification

- `dart format --output=none --set-exit-if-changed .`: passed, 28 files checked and 0 changed.
- `flutter analyze`: passed, no issues found.
- `flutter test test/features/alerts/data/alert_repository_impl_test.dart`: passed, 9 tests.
- `flutter test test/features/alerts/application/alert_list_controller_test.dart`: passed, 15 tests.
- `flutter test`: passed, 113 tests.
- `git diff --check`: passed; Git only reported the repository's Windows line-ending conversion warning.

## Commit

- Required commit: `feat: coordinate cache-first alert state` (this report is included in that commit).

## Self-Review

- Existing `AlertRepository` method signatures remain unchanged.
- Refresh performs one remote request and one atomic local replacement with no retries.
- Remote and protocol failures never replace local data; storage failures are normalized to a safe public exception.
- Providers own and dispose one app-scoped HTTP client and database.
- Controller errors are classified by public exception type and never expose raw exception messages.
- No widgets, connectivity package, runtime demo data, or out-of-scope emergency features were added.

## Concerns

- No known blockers. UI consumption remains intentionally outside Task 8.

## Review Fixes

### RED Evidence

- Initial ordering tests failed because `AlertListController.build()` called `repository.refresh()` immediately; refresh count was 1 before any cache event, and a synchronous remote failure put the provider itself into an error state before valid cache could be observed.
- Persistence race tests failed because matching cache emissions always rewrote current API results to `cached`; a synchronous persisted emission also exposed re-entrant stream delivery while the first cache callback was active.
- Cache-stream error tests failed because `_recordFailure` set `isRefreshing` false while the repository request was still active.
- Unknown refresh errors escaped the controller future with their raw exception.
- Repository read tests received raw local-source `StateError` values instead of `AlertStorageException`.
- The remote-source handshake test received a raw `HandshakeException` instead of `AlertRemoteUnavailable`.

### Implemented Corrections

- Initial refresh is represented as a coalesced pending operation but does not call the repository until the cache stream emits its first data event, including `null`.
- Initial request startup is explicitly ordered after the first cache callback returns, avoiding synchronous stream re-entry while preserving cache-before-network behavior.
- The controller records the last authoritative successful snapshot and uses full snapshot equivalence to prevent matching persistence emissions from downgrading `live` or `stale` outcomes.
- Differing external cache emissions update visible data; recoverable failure status remains stale/error, while a differing post-success snapshot is presented as cached or stale according to its metadata.
- Cache-stream errors during an active refresh retain `isRefreshing`, keep the operation coalesced, and allow the request result to become authoritative. Outside refresh they follow normal storage-failure behavior.
- All unexpected refresh exceptions are converted to safe storage state and consumed by the controller, including synchronous repository throws.
- All `IOException` subclasses, including TLS handshake failures, map to `AlertRemoteUnavailable` without leaking details.
- Repository cache-watch and detail-read failures now map unexpected local exceptions to safe `AlertStorageException`; replacement failures remain safely wrapped.
- The test repository can emit persisted snapshots synchronously before completion, explicitly after completion, and emit stream errors. Ordering uses completers rather than delays.
- Default `appDatabaseProvider` disposal is verified against a real `AppDatabase` using a close-tracking Drift interceptor; only the database factory is overridden.

### Review Verification

- `dart format --output=none --set-exit-if-changed .`: passed, 28 files checked and 0 changed.
- `flutter analyze`: passed, no issues found.
- `flutter test test/features/alerts/application/alert_list_controller_test.dart`: passed, 27 tests.
- `flutter test test/features/alerts/data/alert_repository_impl_test.dart`: passed, 11 tests.
- `flutter test test/features/alerts/data/alert_remote_source_test.dart`: passed, 6 tests.
- `flutter test`: passed, 127 tests.
- Review-fix commit: `fix: make cache-first state race safe` (this report update is included in that commit).

### Review Concerns

- No known blockers. Refresh still performs exactly one repository request and has no automatic retry.

## Initial Cache Gate Follow-Up

### RED Evidence

- A first cache-stream error left the previous synthetic initial-refresh completer unresolved, so no repository request started and all callers awaiting `refresh()` timed out.
- Disposing the provider before any cache event cancelled the subscription but did not settle the synthetic initial-refresh future, so an awaiting caller timed out.
- After an initial no-cache request failed to unavailable, a later valid cache snapshot retained the unavailable state's null presentation status instead of becoming stale data with the safe error.

### Implemented Corrections

- The controller now creates one explicit cache-readiness completer and one `_activeRefresh` future for the entire initial cache-gate-plus-request operation.
- The readiness gate completes on the first data event, including `null`, the first stream error, or provider disposal.
- Disposal before readiness settles all coalesced callers, cancels the cache subscription, and exits before calling the repository.
- A first cache error keeps loading/refreshing state with safe storage classification while the request runs. Success clears it; request failure replaces it with the request's own safe classification.
- Late non-null cache after unavailable changes the phase to data or empty, explicitly presents stale data, and preserves the existing safe error kind.
- Existing persistence-emission ordering, snapshot-equivalence, duplicate suppression, and no-retry behavior remain covered.

### Follow-Up Verification

- `dart format --output=none --set-exit-if-changed .`: passed, 28 files checked and 0 changed.
- `flutter analyze`: passed, no issues found.
- `flutter test test/features/alerts/application/alert_list_controller_test.dart`: passed, 31 tests.
- `flutter test`: passed, 131 tests.
- Follow-up commit: `fix: settle initial cache gate` (this report update is included in that commit).

### Follow-Up Concerns

- No known blockers. The initial operation always settles and still performs at most one repository request.
