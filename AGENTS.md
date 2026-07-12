# AGENTS.md

## Purpose

This file defines the rules, responsibilities, development workflow, and quality standards for AI coding agents working on **SafeMyanmar**, an AI context-aware disaster response mobile application for the **Mobile and Ubiquitous Computing** subject.

These instructions apply to agentic coding tools such as:

- OpenCode
- Cursor
- GitHub Copilot
- Claude Code
- ChatGPT coding agents
- Other repository-aware AI development assistants

The goal is to help agents make safe, minimal, testable, well-documented changes without breaking existing functionality.

---

# 1. Project Summary

SafeMyanmar is a mobile application designed to support people in Myanmar before, during, and after disasters such as:

- earthquakes;
- floods;
- fires;
- landslides;
- cyclones;
- heavy rain;
- severe weather.

The application combines:

- mobile computing;
- ubiquitous and context-aware computing;
- GPS and mobile sensors;
- offline-first design;
- edge computing;
- cloud computing;
- artificial intelligence;
- optional high-performance computing.

The academic MVP focuses on:

- trusted disaster alerts;
- GPS-based location awareness;
- nearby shelters;
- safe-route suggestions;
- SOS emergency messaging;
- Rescue Beacon Mode;
- offline first-aid guidance;
- cached emergency information;
- context-aware recommendations.

---

# 2. Primary Technology Stack

Unless the project files specify otherwise, use the following default stack.

## Mobile Application

- Flutter
- Dart
- Material Design
- Riverpod, Provider, or BLoC
- SQLite, Hive, or Isar for offline storage
- Geolocator for GPS
- Google Maps SDK or OpenStreetMap
- Firebase Cloud Messaging for push notifications

## Backend

- Python
- FastAPI
- PostgreSQL
- Redis where caching is necessary
- REST API
- WebSocket or Server-Sent Events only when real-time behavior is required

## Supporting Services

- Firebase Authentication or JWT authentication
- Firebase Cloud Messaging
- Cloud object storage for uploaded images
- Optional AI API for cloud-based emergency assistance

Agents must inspect the existing repository before introducing new technologies.

---

# 3. Repository Structure

The expected structure is:

```text
SafeMyanmar/
├── mobile/
│   ├── lib/
│   │   ├── core/
│   │   ├── models/
│   │   ├── services/
│   │   ├── features/
│   │   │   ├── alerts/
│   │   │   ├── navigation/
│   │   │   ├── sos/
│   │   │   ├── beacon/
│   │   │   ├── assistant/
│   │   │   └── first_aid/
│   │   └── main.dart
│   ├── assets/
│   ├── test/
│   └── pubspec.yaml
├── backend/
│   ├── app/
│   │   ├── api/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── services/
│   │   ├── repositories/
│   │   ├── database/
│   │   └── main.py
│   ├── tests/
│   └── requirements.txt
├── docs/
├── .env.example
├── AGENTS.md
├── README.md
└── LICENSE
```

Do not reorganize the repository unless the task explicitly requires it.

---

# 4. General Agent Rules

Every agent must follow these rules.

## 4.1 Inspect Before Editing

Before changing code:

1. Read `README.md`.
2. Read this `AGENTS.md`.
3. Inspect the relevant files.
4. Search for existing implementations.
5. Identify affected tests.
6. Confirm the current project architecture.
7. Reuse existing patterns where possible.

Do not assume that the repository still matches this document exactly.

## 4.2 Prefer Minimal Changes

- Make the smallest change that fully solves the task.
- Avoid unrelated refactoring.
- Do not rename files, classes, functions, routes, or database fields without a clear reason.
- Do not rewrite working modules only for style.
- Do not add dependencies when built-in or existing project tools are sufficient.

## 4.3 Do Not Invent Missing Requirements

When requirements are unclear:

- infer only from existing project behavior;
- preserve current behavior;
- document assumptions;
- ask for clarification only when the ambiguity could cause a major design or safety problem.

## 4.4 Keep the Project Runnable

After each meaningful change:

- format changed files;
- run relevant tests;
- run static analysis;
- verify the app or API still starts;
- report any test or build failure honestly.

## 4.5 Preserve Backward Compatibility

Unless the user explicitly approves a breaking change:

- keep existing API response formats;
- keep existing routes;
- keep database fields compatible;
- keep saved local data readable;
- keep current configuration variables supported.

---

# 5. Safety-Critical Development Rules

SafeMyanmar is a disaster-response application. Agents must treat emergency features as safety-sensitive.

## 5.1 Never Claim Guaranteed Safety

Do not implement wording such as:

- "This route is completely safe."
- "Rescue teams will definitely arrive."
- "This medical instruction guarantees recovery."
- "The app can always detect disasters."

Use wording such as:

- "Suggested safer route"
- "Last known location"
- "Emergency guidance"
- "Based on currently available information"

## 5.2 First-Aid Content

- First-aid content must be based on reviewed and trusted sources.
- Do not generate medical instructions dynamically without controls.
- Offline first-aid content should be versioned.
- AI-generated medical guidance must include a disclaimer.
- The app must recommend contacting authorized emergency or medical services when possible.

## 5.3 Route Guidance

Route recommendations must:

- show the data timestamp;
- show when map or hazard data may be stale;
- avoid presenting uncertain routes as guaranteed safe;
- handle missing location permission;
- handle unavailable GPS;
- handle offline state;
- allow users to view nearby shelters even when routing fails.

## 5.4 SOS Behavior

SOS functionality must:

- require clear user activation;
- prevent accidental repeated sending where possible;
- show what information will be sent;
- record the send status;
- distinguish queued, sent, delivered, and failed states;
- preserve the last known location;
- retry safely without creating uncontrolled duplicates.

## 5.5 Rescue Beacon Mode

Rescue Beacon Mode should:

- work without internet;
- clearly indicate that it is active;
- provide an obvious stop control;
- manage battery use;
- avoid permanently locking flashlight or sound resources;
- continue functioning when the app is backgrounded only if the platform permits it.

---

# 6. Offline-First Requirements

Offline support is a core requirement, not an optional enhancement.

Agents must design essential features to work during poor or unavailable connectivity.

## Essential Offline Features

- first-aid guide;
- cached disaster alerts;
- previously downloaded shelter information;
- Rescue Beacon Mode;
- emergency contact access;
- last known location;
- queued SOS messages;
- queued damage reports;
- network-state detection.

## Offline Data Rules

- Store only necessary data.
- Include timestamps for cached information.
- Mark stale data clearly.
- Avoid silently overwriting newer server data.
- Use conflict-resolution rules for synchronized records.
- Queue failed requests safely.
- Make queued operations idempotent when possible.

## Synchronization Rules

When connectivity returns:

1. authenticate if necessary;
2. upload queued emergency events first;
3. upload pending user reports;
4. fetch the latest alerts;
5. refresh shelter and hazard data;
6. update local synchronization timestamps;
7. retain failed operations for later retry.

---

# 7. Context-Aware Computing Rules

SafeMyanmar should adapt to context without surprising the user.

Possible context inputs include:

- GPS location;
- movement;
- nearby disaster events;
- internet availability;
- battery level;
- time;
- user-selected language;
- nearby shelters;
- current alert severity.

Context-aware behavior must be:

- explainable;
- reversible;
- permission-aware;
- battery-conscious;
- privacy-conscious.

Examples:

- show nearby alerts based on location;
- reduce background activity when battery is low;
- switch to offline guidance when the internet is unavailable;
- suggest nearby shelters when a severe alert is active;
- use the last known location when live GPS is unavailable.

Do not automatically share location or activate SOS without explicit user intent.

---

# 8. Mobile Development Standards

## 8.1 Flutter and Dart

- Follow Dart style conventions.
- Run `dart format`.
- Use null safety.
- Avoid deeply nested widgets.
- Keep business logic outside UI widgets.
- Use reusable widgets for repeated emergency UI patterns.
- Use named routes or the project's existing navigation approach.
- Keep platform-specific code isolated.

## 8.2 State Management

Use the state-management solution already present in the repository.

Do not mix multiple patterns without a strong reason.

State should distinguish:

- loading;
- success;
- empty;
- offline;
- stale;
- permission denied;
- recoverable error;
- non-recoverable error.

## 8.3 Mobile UI

Emergency interfaces must prioritize clarity.

Use:

- large touch targets;
- short labels;
- clear icons with text;
- visible status indicators;
- high-contrast layouts;
- confirmation for destructive or high-impact actions;
- Myanmar and English-ready text structures.

Avoid:

- hidden critical actions;
- long paragraphs during emergencies;
- animation that delays urgent actions;
- color-only status indicators;
- overly complex navigation.

## 8.4 Permissions

Request permissions only when needed.

For every permission:

- explain why it is needed;
- handle denial gracefully;
- handle permanent denial;
- provide settings guidance;
- avoid repeatedly prompting the user.

Location permissions should distinguish:

- approximate location;
- precise location;
- foreground location;
- background location.

Background location must not be requested unless the feature genuinely requires it.

---

# 9. Backend Development Standards

## 9.1 FastAPI

- Use routers for feature separation.
- Use Pydantic schemas for request and response validation.
- Keep business logic in services.
- Keep database access in repositories or equivalent modules.
- Avoid placing business logic directly in route handlers.
- Return consistent error responses.
- Use async code only where it provides value.

## 9.2 API Design

Use resource-oriented endpoints where practical.

Example routes:

```text
GET    /api/v1/alerts
GET    /api/v1/alerts/{alert_id}
GET    /api/v1/shelters
POST   /api/v1/sos
GET    /api/v1/sos/{sos_id}
POST   /api/v1/reports
GET    /api/v1/first-aid
POST   /api/v1/auth/login
```

Responses should include timestamps and source information for disaster data.

Example alert response:

```json
{
  "id": "alert_123",
  "type": "earthquake",
  "severity": "high",
  "title": "Earthquake detected near Mandalay",
  "description": "Move to an open area and avoid damaged buildings.",
  "source": "verified-source-name",
  "affected_area": {
    "latitude": 21.9588,
    "longitude": 96.0891,
    "radius_km": 30
  },
  "issued_at": "2026-07-13T00:00:00Z",
  "updated_at": "2026-07-13T00:05:00Z"
}
```

## 9.3 Validation

Validate:

- latitude and longitude ranges;
- timestamps;
- alert severity values;
- report file types and sizes;
- user-provided descriptions;
- phone numbers and emergency contact fields;
- supported disaster categories.

## 9.4 Error Handling

Do not expose:

- stack traces;
- database credentials;
- internal file paths;
- API keys;
- private user data.

Use consistent HTTP status codes and safe messages.

---

# 10. Database Rules

## General Rules

- Use migrations.
- Do not edit production tables manually.
- Use UUIDs or the project's existing ID format.
- Store timestamps in UTC.
- Add indexes for frequently queried location and time fields.
- Avoid storing duplicate alert records.
- Use soft deletion where audit history is important.

## Suggested Main Entities

- User
- EmergencyContact
- DisasterAlert
- Shelter
- HazardZone
- SOSRequest
- DamageReport
- FirstAidContent
- Notification
- SyncQueue
- AuditLog

## Location Data

Location data is sensitive.

- Store only when necessary.
- Define retention rules.
- Avoid indefinite storage of live location history.
- Limit access by role.
- Log sensitive access where possible.

---

# 11. Security and Privacy Rules

Agents must apply secure defaults.

## Secrets

- Never hard-code credentials.
- Use environment variables.
- Update `.env.example` when adding configuration.
- Never commit real `.env` files.
- Never place secrets in logs or test snapshots.

## Authentication

- Use short-lived access tokens where practical.
- Validate tokens on protected endpoints.
- Apply role checks for administrative features.
- Do not trust client-provided user IDs.

## Data Protection

- Use HTTPS in deployed environments.
- Encrypt sensitive data in transit.
- Avoid logging exact GPS coordinates unless necessary.
- Redact personal information from error reports.
- Validate and sanitize user input.
- Restrict uploaded files by type and size.

## Authorization

Suggested roles:

- citizen;
- volunteer;
- rescue_team;
- organization;
- administrator.

An agent must not add privileged functionality without authorization checks.

---

# 12. AI Feature Rules

The AI assistant must be constrained and transparent.

## Allowed AI Uses

- emergency FAQ answering;
- disaster-preparedness guidance;
- summarizing trusted alerts;
- explaining first-aid steps from approved content;
- future image classification for damage reports.

## Disallowed or Restricted Uses

- medical diagnosis;
- guaranteed route safety;
- automatic emergency dispatch without confirmation;
- inventing disaster information;
- presenting unverified user reports as official;
- replacing official emergency authorities.

## AI Response Requirements

AI responses should:

- identify uncertainty;
- prioritize concise emergency instructions;
- mention when information comes from offline content;
- recommend official help when available;
- avoid unsupported claims;
- avoid collecting unnecessary personal data.

## Offline AI Fallback

For the MVP, prefer:

- rule-based intent matching;
- keyword search;
- curated emergency content;
- structured decision trees.

Do not require a large local model unless the hardware and project scope justify it.

---

# 13. Notification Rules

Notifications should be relevant and rate-limited.

Each notification should include:

- disaster type;
- affected area;
- severity;
- issue time;
- trusted source;
- recommended action.

Avoid:

- duplicate notifications;
- notifications for expired alerts;
- excessive low-priority alerts;
- panic-inducing language;
- unsupported claims.

Critical alerts should be distinguishable from informational updates.

---

# 14. Testing Requirements

Every code change should include or update tests when practical.

## Mobile Tests

- unit tests;
- widget tests;
- integration tests;
- permission-state tests;
- offline-mode tests;
- poor-network tests;
- low-battery behavior tests;
- SOS interaction tests;
- route failure tests.

## Backend Tests

- API endpoint tests;
- schema validation tests;
- authentication tests;
- authorization tests;
- database tests;
- idempotency tests;
- file-upload validation tests;
- synchronization tests.

## Required Scenarios

At minimum, test:

1. no internet connection;
2. GPS unavailable;
3. location permission denied;
4. location permission permanently denied;
5. stale cached alert;
6. failed SOS transmission;
7. repeated SOS retry;
8. expired authentication token;
9. malformed disaster data;
10. server unavailable;
11. low battery;
12. empty shelter result.

---

# 15. Commands

Agents should use the commands supported by the repository.

## Flutter

```bash
cd mobile
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

## Backend

```bash
cd backend
python -m venv .venv
```

Activate the environment:

```bash
# Windows PowerShell
.venv\Scripts\Activate.ps1

# macOS or Linux
source .venv/bin/activate
```

Then run:

```bash
pip install -r requirements.txt
pytest
uvicorn app.main:app --reload
```

## Git

Before finishing:

```bash
git status
git diff
```

Do not commit unless the user explicitly requests it.

---

# 16. Documentation Rules

Agents must update documentation whenever behavior changes.

Update `README.md` when changing:

- setup steps;
- technology stack;
- major features;
- environment variables;
- architecture;
- project structure;
- commands.

Update API documentation when changing:

- endpoints;
- request fields;
- response fields;
- authentication;
- status codes;
- error formats.

Update this `AGENTS.md` when changing:

- coding workflow;
- architecture rules;
- testing requirements;
- safety requirements;
- supported tools or commands.

Do not allow code and documentation to become inconsistent.

---

# 17. Dependency Rules

Before adding a package:

1. Check whether the project already has a suitable dependency.
2. Check whether the standard library can solve the task.
3. Confirm the package is actively maintained.
4. Confirm its license is acceptable.
5. Confirm it supports the project's Flutter, Dart, or Python version.
6. Explain why it is necessary.

Avoid adding large packages for small tasks.

When adding a dependency:

- update the relevant dependency file;
- update lock files where appropriate;
- update setup documentation;
- add tests for the new behavior.

---

# 18. Database Migration Rules

When changing database models:

1. create a migration;
2. make the migration reversible where possible;
3. preserve existing data;
4. add indexes only when justified;
5. test upgrade and downgrade paths;
6. update schemas and API documentation;
7. update seed data if needed.

Do not drop data or columns unless explicitly approved.

---

# 19. Git and Change Management

## Branch Naming

Suggested branch names:

```text
feature/disaster-alerts
feature/sos-mode
feature/offline-first-aid
fix/location-permission
fix/sos-retry
docs/update-architecture
test/offline-sync
```

## Commit Message Style

Suggested format:

```text
feat: add cached disaster alert support
fix: prevent duplicate SOS retries
docs: update mobile setup instructions
test: add location permission scenarios
refactor: separate alert service from UI
```

## Change Scope

A single task should ideally produce a focused set of changes.

Do not combine:

- feature implementation;
- unrelated formatting;
- broad refactoring;
- dependency upgrades;
- documentation restructuring;

unless the user explicitly requests them together.

---

# 20. Agent Workflow

For each task, follow this process.

## Step 1: Understand the Task

Identify:

- requested behavior;
- affected modules;
- user-visible changes;
- safety implications;
- offline implications;
- privacy implications.

## Step 2: Inspect the Codebase

Read:

- relevant source files;
- related models and services;
- existing tests;
- configuration files;
- documentation.

## Step 3: Plan

Create a short internal plan that includes:

- files to change;
- implementation approach;
- tests to add or update;
- risks;
- assumptions.

## Step 4: Implement

- follow existing patterns;
- keep changes focused;
- include proper error handling;
- preserve offline behavior;
- avoid breaking public interfaces.

## Step 5: Validate

Run:

- formatters;
- static analysis;
- tests;
- build or startup checks.

## Step 6: Review

Check:

- security;
- privacy;
- emergency wording;
- accessibility;
- offline behavior;
- documentation consistency;
- accidental unrelated changes.

## Step 7: Report

The final response should state:

- what changed;
- files changed;
- tests run;
- results;
- known limitations;
- any required manual steps.

Do not claim that tests passed if they were not run.

---

# 21. Definition of Done

A task is complete only when:

- the requested behavior is implemented;
- existing functionality is preserved;
- relevant tests are added or updated;
- tests pass, or failures are clearly reported;
- formatting and static analysis pass;
- security and privacy concerns are addressed;
- offline behavior is considered;
- documentation is updated;
- no secrets are committed;
- no unrelated changes remain.

---

# 22. Prohibited Agent Actions

Agents must not:

- fabricate test results;
- claim a feature is complete when it is only mocked;
- silently remove existing features;
- expose credentials;
- commit `.env` files;
- bypass authorization;
- disable tests to make a build pass;
- remove validation without justification;
- send real SOS messages during tests;
- call real emergency services;
- collect background location without clear need;
- present unverified reports as official;
- use AI output as a medical diagnosis;
- rewrite the whole project for a small task;
- commit or push without explicit user approval.

---

# 23. Mock and Demo Data Rules

For development and demonstrations:

- clearly mark all demo alerts as simulated;
- use fictional phone numbers;
- use non-sensitive sample coordinates;
- avoid real personal information;
- do not send real notifications to emergency contacts;
- do not use real disaster reports without permission.

Example simulated alert:

```json
{
  "id": "demo_alert_001",
  "type": "earthquake",
  "severity": "medium",
  "title": "SIMULATION: Earthquake Drill",
  "description": "This is demonstration data for testing only.",
  "source": "SafeMyanmar Demo",
  "issued_at": "2026-07-13T00:00:00Z"
}
```

---

# 24. Environment Configuration

Expected variables may include:

```env
API_BASE_URL=http://localhost:8000
DATABASE_URL=postgresql://user:password@localhost:5432/safemyanmar
JWT_SECRET=replace_with_a_secure_secret
MAPS_API_KEY=replace_with_your_map_key
FIREBASE_PROJECT_ID=replace_with_project_id
FIREBASE_CREDENTIALS_PATH=replace_with_local_path
AI_API_KEY=replace_only_if_cloud_ai_is_enabled
ENVIRONMENT=development
```

Whenever a new variable is added:

- add it to `.env.example`;
- document whether it is required;
- provide a safe default where possible;
- validate it during startup.

---

# 25. Recommended Feature Priorities

Agents should prioritize work in this order unless the user gives another priority.

## Priority 1: Core Safety and Offline Features

- disaster alert display;
- location permission handling;
- nearby shelters;
- SOS preparation and queueing;
- offline first-aid guide;
- Rescue Beacon Mode;
- cached data.

## Priority 2: Context Awareness

- location-based alert filtering;
- network-aware behavior;
- battery-aware behavior;
- last-known-location handling;
- context-sensitive recommendations.

## Priority 3: Cloud Integration

- authentication;
- push notifications;
- real-time alert synchronization;
- SOS status tracking;
- report uploads.

## Priority 4: Advanced Features

- user-generated damage reports;
- rescue-team dashboard;
- Bluetooth communication;
- peer-to-peer emergency messaging;
- AI image recognition;
- predictive models;
- HPC-based simulation.

---

# 26. Agent Prompt Template

Use the following prompt structure when assigning tasks to an AI coding agent.

```text
You are working on the SafeMyanmar project.

Read README.md and AGENTS.md before editing.

Task:
[Describe the feature or bug clearly.]

Requirements:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

Constraints:
- Keep changes minimal.
- Reuse existing architecture and dependencies.
- Preserve offline behavior.
- Do not break current APIs.
- Add or update tests.
- Update documentation if behavior changes.
- Do not commit or push changes.

Before implementing:
1. Inspect relevant files.
2. Explain the implementation plan.
3. Identify risks and assumptions.

After implementing:
1. Run formatting.
2. Run static analysis.
3. Run relevant tests.
4. Summarize changed files.
5. Report any failures honestly.
```

---

# 27. Example Feature Prompt

```text
Implement offline SOS queueing for SafeMyanmar.

Requirements:
- When the user presses SOS without internet access, store the request locally.
- Save the last known GPS location and creation time.
- Show the request as "Queued".
- Automatically retry when connectivity returns.
- Prevent duplicate SOS submissions.
- Update the UI to show queued, sending, sent, and failed states.
- Add tests for offline, retry, duplicate prevention, and failed synchronization.

Constraints:
- Use the existing state-management and local-storage solution.
- Do not add a new dependency unless necessary.
- Do not send a real SMS or contact emergency services.
- Preserve the current SOS API format.
- Update README.md if setup or behavior changes.
```

---

# 28. Example Bug-Fix Prompt

```text
Fix the location permission flow in SafeMyanmar.

Current problem:
The app repeatedly asks for location permission after the user permanently denies it.

Expected behavior:
- Detect permanent denial.
- Stop repeated permission requests.
- Show an explanation.
- Provide a button that opens the application settings.
- Allow access to offline first-aid content without location permission.
- Add widget tests for denied and permanently denied states.

Do not change unrelated navigation or redesign the screen.
```

---

# 29. Final Response Format for Agents

After completing a task, respond in this format:

```text
Implemented:
- [Change 1]
- [Change 2]

Files changed:
- path/to/file
- path/to/test

Validation:
- dart format: passed
- flutter analyze: passed
- flutter test: passed
- pytest: passed

Notes:
- [Known limitation or manual step]

No commit or push was performed.
```

Only include validation commands that were actually run.

---

# 30. Project Principle

SafeMyanmar must remain:

- trustworthy;
- context-aware;
- offline-capable;
- privacy-conscious;
- accessible;
- testable;
- transparent about uncertainty;
- suitable for an academic mobile and ubiquitous computing project.

When choosing between a complex feature and a reliable emergency experience, prefer the reliable emergency experience.
