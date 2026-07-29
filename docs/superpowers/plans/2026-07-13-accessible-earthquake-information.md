# Accessible Earthquake Information Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Display accessible, localized earthquake information list and detail screens backed by the reviewed cache-first Riverpod state machine.

**Architecture:** A `MaterialApp.router` shell owns generated localization and SafeTheme configuration. The list consumes `alertListControllerProvider`; detail resolves a decoded route ID through `alertRepositoryProvider.getById` and launches only the validated model URL through an overridable launcher provider.

**Tech Stack:** Flutter, Material 3, Riverpod, go_router, intl, generated Flutter localization, flutter_test.

## Global Constraints

- Work only in `D:\SafeMyanmar\.worktrees\live-earthquake`.
- Every visible widget string comes from generated localization resources.
- Describe entries as `Earthquake information`; never warning, prediction, guaranteed safety, inferred severity, or demo content.
- Use icons plus text, 48x48 dp minimum targets, wrapping essential text, and UTC date/time formatting.
- Keep cached/stale data visible during refresh/failure.
- Widget tests override providers and launcher functions; they never use real network, disk, or browser resources.
- Use `url_launcher` only behind the injected source-launcher boundary so the explicit validated HTTPS USGS action works at runtime and widget tests never open a browser.

---

### Task 1: Localized List Presentation

**Files:**
- Modify: `mobile/lib/l10n/app_en.arb`
- Create: `mobile/lib/features/alerts/presentation/presentation_formatters.dart`
- Create: `mobile/lib/features/alerts/presentation/widgets/data_status_banner.dart`
- Create: `mobile/lib/features/alerts/presentation/widgets/earthquake_card.dart`
- Create: `mobile/lib/features/alerts/presentation/alert_list_screen.dart`
- Test: `mobile/test/features/alerts/presentation/alert_list_screen_test.dart`

**Interfaces:**
- Consumes: `alertListControllerProvider`, `AlertListState`, `Earthquake`.
- Produces: `AlertListScreen({Key? key, void Function(String id)? onOpenEarthquake})` and localized list widgets.

- [ ] **Step 1: Write failing list widget tests**

Cover loading semantics, live/cached/stale/empty/unavailable states, exact safe copy, item order, refresh coalescing, 48 dp refresh target, prohibited wording, and encoded-ID navigation using repository/controller overrides.

- [ ] **Step 2: Run tests to verify RED**

Run: `$env:Path='C:\Users\USER\develop\flutter\bin;' + $env:Path; flutter test test/features/alerts/presentation/alert_list_screen_test.dart`

Expected: FAIL because `AlertListScreen`, cards, banners, and localization messages do not exist.

- [ ] **Step 3: Implement minimal localized list UI**

Generate all dynamic strings through ARB placeholders, format one-decimal values with `intl`, format UTC timestamps with an explicit `UTC` suffix, and map state-machine phases without exposing exceptions.

- [ ] **Step 4: Generate localization and verify GREEN**

Run: `$env:Path='C:\Users\USER\develop\flutter\bin;' + $env:Path; flutter gen-l10n; flutter test test/features/alerts/presentation/alert_list_screen_test.dart`

Expected: PASS.

---

### Task 2: Repository-Backed Detail Presentation

**Files:**
- Modify: `mobile/lib/l10n/app_en.arb`
- Create: `mobile/lib/features/alerts/presentation/source_launcher.dart`
- Create: `mobile/lib/features/alerts/presentation/alert_detail_screen.dart`
- Modify: `mobile/test/support/fake_alert_repository.dart`
- Test: `mobile/test/features/alerts/presentation/alert_detail_screen_test.dart`

**Interfaces:**
- Consumes: decoded `String id`, `alertRepositoryProvider.getById(id)`.
- Produces: `sourceLauncherProvider` with `Future<bool> Function(Uri)` and `AlertDetailScreen({required String earthquakeId})`.

- [ ] **Step 1: Write failing detail widget tests**

Cover exact ID lookup, no refresh, localized loading/not-found states, all fields, optional review status, UTC formatting, exact source URI launch, and safe feedback for false/throwing launchers.

- [ ] **Step 2: Run tests to verify RED**

Run: `$env:Path='C:\Users\USER\develop\flutter\bin;' + $env:Path; flutter test test/features/alerts/presentation/alert_detail_screen_test.dart`

Expected: FAIL because detail and launcher providers do not exist.

- [ ] **Step 3: Implement minimal detail UI and injected launcher**

Resolve once with a family future provider, reject non-HTTPS/non-USGS model URLs before invoking the launcher, and show only localized non-sensitive failure feedback.

- [ ] **Step 4: Generate localization and verify GREEN**

Run: `$env:Path='C:\Users\USER\develop\flutter\bin;' + $env:Path; flutter gen-l10n; flutter test test/features/alerts/presentation/alert_detail_screen_test.dart`

Expected: PASS.

---

### Task 3: Router And Application Shell

**Files:**
- Create: `mobile/lib/app/app.dart`
- Create: `mobile/lib/app/router.dart`
- Modify: `mobile/lib/main.dart`
- Test: `mobile/test/features/alerts/presentation/alert_list_screen_test.dart`
- Test: `mobile/test/features/alerts/presentation/alert_detail_screen_test.dart`

**Interfaces:**
- Produces: `createRouter({String initialLocation = '/alerts'})` and `SafeMyanmarApp({GoRouter? router})`.

- [ ] **Step 1: Write failing route tests**

Verify `/alerts` initial location, encoded ID decode and repository lookup, unknown-route localized fallback, 48 dp back action, and provider-overridden construction without real resources.

- [ ] **Step 2: Run route tests to verify RED**

Run: `$env:Path='C:\Users\USER\develop\flutter\bin;' + $env:Path; flutter test test/features/alerts/presentation`

Expected: FAIL because router/app shell do not exist.

- [ ] **Step 3: Implement minimal router shell**

Use `MaterialApp.router`, system theme mode, generated delegates/locales, SafeTheme light/dark, localized not-found UI, and `ProviderScope(child: SafeMyanmarApp())` in `main()`.

- [ ] **Step 4: Verify GREEN**

Run: `$env:Path='C:\Users\USER\develop\flutter\bin;' + $env:Path; flutter test test/features/alerts/presentation`

Expected: PASS.

---

### Task 4: Accessibility And Responsive Coverage

**Files:**
- Create: `mobile/test/features/alerts/presentation/accessibility_test.dart`
- Modify presentation widgets only when a failing accessibility test requires it.

**Interfaces:**
- Verifies public widgets and app routes from Tasks 1-3.

- [ ] **Step 1: Write failing accessibility tests**

Exercise loading, unavailable, empty, populated list, and detail at 200% text scale on a narrow viewport; inspect semantics for type, values, time, status, source, hints/actions; measure every interactive render box; smoke-test light/dark themes.

- [ ] **Step 2: Run tests to verify RED**

Run: `$env:Path='C:\Users\USER\develop\flutter\bin;' + $env:Path; flutter test test/features/alerts/presentation/accessibility_test.dart`

Expected: FAIL on any missing semantics, wrapping, sizing, or theme behavior.

- [ ] **Step 3: Make minimal accessibility corrections**

Use wrapping layouts, scrolling where content can grow, explicit semantics, icon-and-text controls, and fixed minimum constraints without ellipsis.

- [ ] **Step 4: Verify GREEN**

Run the focused accessibility test and then the complete presentation directory; expect PASS with no overflow exceptions.

---

### Task 5: Verification, Report, And Commit

**Files:**
- Create: `.superpowers/sdd/task-9-report.md`

- [ ] **Step 1: Run required verification**

From `mobile/`, run `flutter gen-l10n`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test test/features/alerts/presentation`, and `flutter test` with Flutter prepended to PATH.

- [ ] **Step 2: Self-review safety and scope**

Inspect `git status`, `git diff`, prohibited visible wording, provider overrides, source URL validation, generated localization use, and absence of real resources in widget tests.

- [ ] **Step 3: Write report**

Record files, dependency rationale, observed RED failures, accessibility coverage, exact verification outcomes, self-review, concerns, and final commit hash.

- [ ] **Step 4: Commit**

Stage only Task 9 files and commit exactly: `feat: display accessible earthquake information`.
