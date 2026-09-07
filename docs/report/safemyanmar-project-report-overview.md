# SafeMyanmar

## AI Context-Aware Disaster Response Mobile Application

### Project Report Overview and Chapter Structure

| Field | Value |
|---|---|
| Project category | HPC-8115 / Mobile and Ubiquitous Computing Project |
| Project name | SafeMyanmar |
| Project type | Academic Android disaster-information prototype |
| Submitted date | September 2, 2026 |
| Project group members | User |

SafeMyanmar is an academic prototype. It is not an official warning,
earthquake-prediction, emergency-dispatch, medical, or guaranteed-safety
service.

## Document History

| Date | Version | By | Remarks |
|---|---:|---|---|
| September 2, 2026 | 1.00 | Project Group | Initial project report overview |
| September 7, 2026 | 1.01 | Project Group | Corrected implementation, optional, simulation, and future-work claims |

## Document Boundary

This document provides corrected report front matter, an abstract, a factual
scope summary, and a chapter structure. It does not claim that the listed full
chapters have already been written.

The following status terms are used throughout the report:

| Status | Meaning |
|---|---|
| Implemented | Present in the current Android or backend code |
| Partial or optional | Present but dependent on current data, external configuration, supported hardware, or separately provisioned artifacts |
| Simulation | Fictional, explicitly labeled behavior behind an explicit runtime opt-in; the Render blueprint enables the public demonstration |
| Future | Proposed capability that is not implemented |

## Abstract

Natural disasters can create situations in which people need reliable
information, location-aware assistance, emergency guidance, and communication
support within a short period. Disaster information can be difficult to verify,
network connectivity can be unreliable, and available guidance may not reflect
the user's location, permissions, or current data conditions.

SafeMyanmar is an academic Android disaster-information prototype developed for
the Mobile and Ubiquitous Computing subject. The project demonstrates how mobile
computing, ubiquitous and context-aware computing, foreground GPS, on-device
edge processing, and a server-side data layer can support a constrained disaster
information scenario. It also investigates optional local artificial
intelligence. High Performance Computing is treated as a future research
direction rather than an implemented component.

The implemented application focuses on live USGS earthquake observations for
Myanmar and an approximately 100 km surrounding coverage buffer, explicit
foreground location, a validated and time-limited Yangon navigation snapshot,
cache-aware map functions, local SOS preparation, nearby Bluetooth SOS, and
reviewed offline emergency guidance. The Flutter Material 3 interface contains
Home, Map, SOS, Guide, and More sections. A FastAPI backend retrieves and
normalizes USGS observations, stores successful snapshots in PostgreSQL, and
exposes versioned REST endpoints. The Android client strictly validates the API
response and stores a local Drift snapshot so valid information can remain
visible during poor connectivity.

Location is requested only after explicit user action. The application does not
request background location permission or maintain a location history.
Context-area analysis and route suggestions are also user initiated. Results
retain their source, data timestamp, rationale, and uncertainty. The current
validated Yangon snapshot contains no verified shelter records, so the system
does not invent shelter destinations or present a route as guaranteed safe.
Optional route alternatives require an explicitly selected destination and a
configured Mapbox Directions provider.

The SOS workflow uses a secure local profile and explicitly selected emergency
contacts. The user reviews the exact prepared information and confirms one
activation before Android attempts direct SMS delivery and, when enabled, a
time-limited nearby Bluetooth broadcast. The application records device
acceptance separately from failure and does not claim carrier delivery, rescue
dispatch, or rescue arrival. Nearby Bluetooth events remain unverified peer
information. The current implementation does not include the proposed
flashlight, siren, vibration, full-screen HELP, or battery-managed Rescue Beacon
mode.

The offline Guide contains five versioned English and Myanmar articles covering
earthquake response, trapped-person guidance, floodwater avoidance, home-fire
escape, and initial first-aid assessment. The default assistant uses
deterministic intent matching and approved local content. Optional ONNX and
Gemma runtimes can be provisioned separately on supported development devices,
but model artifacts are not bundled. Critical first-aid, trapped-person, SOS,
and route requests are excluded from generative rewriting, and no cloud AI
service is implemented.

Multi-disaster live alert feeds, trusted or citizen report submission, damage
reporting, push notifications, authenticated rescue-team integration, complete
Rescue Beacon behavior, disaster prediction, and HPC processing remain future
work. SafeMyanmar therefore demonstrates a transparent, offline-capable, and
privacy-conscious application of mobile and ubiquitous computing without
presenting incomplete data or proposed features as operational emergency
services.

## Contents at a Glance

1. Introduction
2. System Analysis
3. System Architecture and Design
4. System Implementation
5. System Operation
6. Testing and Evaluation
7. Limitations and Future Improvements
8. Conclusion
9. References
10. Appendices

## Table of Contents

### Chapter 1 - Introduction

#### 1.1 Background

Introduce disaster-information challenges in Myanmar and the relevance of
mobile and ubiquitous computing without claiming that the prototype is an
official emergency service.

#### 1.2 Problem Statement

Discuss misinformation, uncertain data, unreliable connectivity, location
limitations, and emergency communication challenges.

#### 1.3 Project Overview

Summarize the implemented Android, backend, offline, SOS, navigation, and
assistant components.

#### 1.4 Objectives

Separate achieved technical objectives from future operational goals. Do not
claim measured reductions in emergency response time.

#### 1.5 Implemented Scope and Exclusions

Identify implemented, optional, simulation-only, and future capabilities. State
that SafeMyanmar is not a warning, prediction, dispatch, medical, or
guaranteed-safety service.

#### 1.6 Target Users and Future Stakeholders

Identify citizens, trusted emergency contacts, students, and evaluators as
current users. Treat rescue teams, volunteers, humanitarian organizations, and
government organizations as future integration stakeholders.

### Chapter 2 - System Analysis

#### 2.1 Existing Problems

Analyze source trust, connectivity, stale information, user consent, and the
limits of generic emergency guidance.

#### 2.2 Proposed and Implemented Solution

Distinguish the broad SafeMyanmar vision from the completed academic prototype.

#### 2.3 Functional Requirements

Document the implemented requirements for earthquake retrieval, caching,
foreground location, context analysis, routing, local profiles and contacts,
confirmed SOS, nearby BLE, offline Guide access, and deterministic assistance.

#### 2.4 Non-functional Requirements

Cover offline operation, privacy, accessibility, bilingual presentation,
validation, security, source provenance, data freshness, battery awareness, and
transparent failure states.

#### 2.5 Feature Status Matrix

Use the factual capability matrix in this overview rather than presenting future
features as completed work.

### Chapter 3 - System Architecture and Design

#### 3.1 Overall Architecture

Describe the Flutter Android client, FastAPI REST API, PostgreSQL server cache,
Drift local cache, Android secure storage, and external data providers.

#### 3.2 Mobile Computing

Explain the five-tab Material 3 interface, Android permissions, SMS, BLE,
location, and local persistence.

#### 3.3 Ubiquitous and Context-Aware Computing

Explain how permission state, foreground location, selected disaster type,
cache state, network outcomes, and user preferences produce visible and
reversible behavior.

#### 3.4 Foreground GPS and Location Services

Cover precise, approximate, denied, permanently denied, service-disabled,
current, and last-known states. State that no background location permission is
requested.

#### 3.5 Edge Computing

Describe local Guide retrieval, Drift caching, deterministic classification,
secure local SOS state, BLE frame processing, and optional local-model runtimes.

#### 3.6 Server and Cloud-Deployable Backend

Describe FastAPI, PostgreSQL, provider normalization, REST APIs, Docker, and
external service integration. A deployable backend must not be described as an
already operational notification, dispatch, or cloud-AI platform.

#### 3.7 Constrained Artificial Intelligence

Describe deterministic Tier 1 behavior and optional, separately provisioned
ONNX and Gemma tiers. Include model validation, fallback, and critical-intent
restrictions.

#### 3.8 High Performance Computing as Future Work

Discuss simulation, prediction, and large-scale evacuation optimization only as
future research. Do not classify mobile OpenCL declarations or local model
execution as an implemented HPC subsystem.

### Chapter 4 - System Implementation

#### 4.1 Technology Stack

Document Flutter, Dart, Riverpod, `go_router`, Drift, Android secure storage,
Geolocator, Mapbox, Kotlin platform services, FastAPI, SQLAlchemy, Alembic,
PostgreSQL, and `httpx`.

#### 4.2 Mobile Application

Describe Home, Map, SOS, Guide, and More, including localization, accessibility,
theme, and cache-aware state handling.

#### 4.3 Backend API

Describe health, alert, shelter, hazard, context-area, route, and SOS-route
endpoints with their availability and configuration boundaries.

#### 4.4 Database and Local Persistence

Separate PostgreSQL earthquake snapshots from Drift data and Android secure
local profile, contact, preference, draft, and received-event storage.

#### 4.5 Earthquake Data Processing

Explain the USGS FDSN query, geographic envelope, approximate 100 km boundary
filter, strict normalization, reconciliation, provider locking, freshness, and
mobile cache flow.

#### 4.6 Navigation and Nearby Analysis

Explain the validated snapshot, current absence of verified shelters, OSM
environment observations, elevation data, selected candidates, Mapbox route
alternatives, and explicit uncertainty.

#### 4.7 SOS SMS and Nearby Bluetooth

Explain selected contacts, exact previews, confirmation, duplicate suppression,
direct Android SMS status, time-limited BLE broadcast, receiving, optional
one-hop relay, and peer-data limitations.

#### 4.8 Offline Emergency Guide

Document the five reviewed bilingual article records, sources, versions, review
date, filtering, search, and offline behavior.

#### 4.9 Deterministic and Optional Local Assistance

Explain intent classification, approved-content retrieval, optional model
provisioning, capability banners, safety rejection, and deterministic fallback.

#### 4.10 Development Simulation Boundaries

Document that fictional navigation data is explicitly labeled, disabled by
default, intentionally enabled by the public Render demonstration, and never
merged into the USGS alert feed.

### Chapter 5 - System Operation

#### 5.1 Earthquake Data Flow

Trace USGS retrieval through validation, PostgreSQL, the API, Drift, Riverpod,
and the list/detail interface.

#### 5.2 Location Processing

Trace explicit permission requests and the current or last-known foreground
location state.

#### 5.3 Context-Area and Route Suggestion Process

Trace explicit analysis, candidate review, destination selection, route request,
ranking, and uncertainty display. Do not describe continuous automatic
rerouting.

#### 5.4 SOS Process

Trace preparation, exact data review, confirmation, secure draft persistence,
SMS attempt, optional BLE broadcast, and visible status updates.

#### 5.5 Offline Guide and Assistant Process

Trace deterministic intent matching, local Guide retrieval, optional model use,
and safe fallback when a model or network is unavailable.

### Chapter 6 - Testing and Evaluation

#### 6.1 Testing Strategy

Describe unit, widget, API, repository, integration, accessibility, localization,
permission, cache, provider-failure, and offline tests.

#### 6.2 Backend Evaluation

Cover schema validation, provider normalization, geographic filtering,
PostgreSQL reconciliation, migrations, health endpoints, safe errors, and
provider-failure behavior.

#### 6.3 Mobile Evaluation

Cover routing, screen behavior, text scaling, English and Myanmar UI, location
states, alert caching, SOS confirmation, BLE behavior, and Guide retrieval.

#### 6.4 Offline and Failure Evaluation

Test stale cached alerts, server unavailability, GPS failure, permission denial,
route-provider failure, optional-model absence, and local SOS persistence.

#### 6.5 Safety, Security, and Privacy Review

Review explicit consent, trusted URLs, secret handling, exact-coordinate
exposure, secure local storage, simulation labels, medical restrictions, and
uncertainty wording.

#### 6.6 Evaluation Limits

State that automated tests and demonstrations do not establish field safety,
carrier delivery, BLE coverage, rescue response, medical effectiveness, or
real-world disaster-response-time improvement.

### Chapter 7 - Limitations and Future Improvements

#### 7.1 Current Limitations

Cover USGS-only live observations, the absence of official warnings and verified
shelters, snapshot age limits, provider dependence, GPS uncertainty, SMS and BLE
limitations, unbundled optional models, and unimplemented operational services.

#### 7.2 Future Improvements

Cover additional verified warning sources, refreshed shelter and hazard data,
authenticated notifications, rescue-organization integration, controlled
damage reporting, complete Rescue Beacon behavior, evaluated AI, and broader
offline communication.

#### 7.3 Future HPC Research

Treat flood modelling, earthquake simulation, damage analysis, and evacuation
optimization as independently validated future research, not current app
features.

### Chapter 8 - Conclusion

Evaluate what the prototype actually demonstrates: live earthquake data,
offline-first mobile state, explicit context use, local SOS communication,
reviewed guidance, and constrained assistance. Reiterate the operational and
safety boundaries.

### References

Use primary provider documentation, reviewed Guide sources, project architecture
documents, and applicable platform documentation. Do not list an organization
as an integrated source unless the implemented system actually consumes its
data.

### Appendices

Suggested appendices include API schemas, test results, permission declarations,
screenshots, database schema, environment configuration, and the capability
status matrix.

## Corrected Capability Matrix

| Capability | Status | Accurate report claim |
|---|---|---|
| Live disaster information | Implemented for USGS earthquake observations only | Informational observations with source and freshness state; not official warnings or predictions |
| Flood, fire, cyclone, landslide, and weather alerts | Future | No live alert-provider integration exists for these disaster types |
| Foreground GPS | Implemented | Explicit permission flow with precise, approximate, current, and last-known states |
| Background location tracking | Future or excluded | No background location permission or location-history service is implemented |
| Validated Yangon navigation data | Partial | Source-backed, time-limited snapshot; current snapshot has no verified shelters |
| Context-aware nearby analysis | Partial | Explicit earthquake/flood analysis depends on current hazard and upstream environment data |
| Route alternatives | Partial | Requires a selected destination and configured Mapbox Directions provider |
| SMS SOS | Implemented on Android | Explicitly confirmed direct SMS; device acceptance does not prove delivery |
| Nearby Bluetooth SOS | Implemented on supported Android devices | Time-limited broadcast, opt-in receiving, local retention, and optional one-hop relay |
| Complete Rescue Beacon Mode | Future | No flashlight pattern, siren, vibration pattern, HELP screen, wake lock, or battery mode |
| Offline Guide | Implemented | Five reviewed, bilingual, versioned local articles |
| Deterministic assistant | Implemented | Uses local intent matching and approved Guide content |
| ONNX and Gemma assistance | Partial or optional | Runtime is present; authorized model artifacts must be provisioned separately |
| Cloud AI | Future | No remote AI client or service exists |
| Trusted or citizen report submission | Future | No submission, verification, moderation, or report-storage workflow exists |
| Damage reporting and camera upload | Future | No report screen, camera permission, upload endpoint, or object storage exists |
| Push notifications | Future | No Firebase Cloud Messaging or backend push sender exists |
| Rescue-team dashboard and dispatch | Future | No authenticated rescue workflow or acknowledgement service exists |
| Edge computing | Implemented | Local cache, Guide, deterministic processing, secure state, BLE, and optional models |
| Server or cloud layer | Implemented backend, deployment-dependent | FastAPI and PostgreSQL exist; managed hosting does not imply operational emergency reliability |
| HPC | Future | No distributed or high-performance processing workload is implemented |

## Planned Figures

1. SafeMyanmar implemented system architecture
2. Live USGS earthquake data flow
3. Cache-first mobile alert states
4. Explicit foreground location and context-analysis flow
5. SOS SMS and nearby BLE confirmation sequence
6. Deterministic and optional local assistant tiers

These are proposed report figures. Their inclusion here does not claim that final
figure artwork has already been produced.

## Planned Tables

1. Functional requirements and implementation status
2. Non-functional requirements and verification evidence
3. Technology stack and component responsibilities
4. Data sources, timestamps, and known limitations
5. Mobile and backend test coverage
6. Current limitations and future improvements

These are proposed report tables. Their inclusion here does not claim that final
evaluation values have already been recorded.

## Keywords

SafeMyanmar, Mobile Computing, Ubiquitous Computing, Context Awareness, Disaster
Information, Earthquake Observation, Foreground GPS, Edge Computing, Offline
Computing, Artificial Intelligence, SOS, Bluetooth Low Energy, Flutter, FastAPI,
PostgreSQL, High Performance Computing Future Work

## Terminology and Safety Rules

- Use **earthquake information** or **USGS observation**, not **official warning**.
- Use **suggested route**, **suggested area**, or **lower-exposure candidate**, not
  **safe route** or **safe place**.
- Use **SMS accepted by device**, not **delivered**, unless carrier delivery is
  independently verified.
- Use **peer-reported nearby SOS**, not **verified victim** or **confirmed rescue**.
- Describe first-aid content as reviewed emergency guidance, not diagnosis or a
  replacement for medical services.
- Mark every fictional record as simulation data and keep it separate from live
  USGS observations.
- Identify Rescue Beacon, cloud AI, multi-disaster alerts, reports, push
  notifications, rescue integration, and HPC as future work.

## Repository References

- [Project scope and safety boundaries](../../README.md)
- [Implemented mobile design](../../DESIGN.md)
- [Corrected presentation](../presentation/safemyanmar-slides.md)
- [Live earthquake architecture](../architecture/live-earthquake-slice.md)
- [Context-aware mobile flow](../architecture/context-aware-mobile-flow.md)
- [Optional AI model provisioning](../architecture/optional-ai-model-provisioning.md)
- [Alert API](../api/alerts.md)
- [Navigation API and simulation boundaries](../../backend/docs/api/simulation-navigation.md)
- [Validated Yangon data report](../../SafeMyanmar_Yangon_2026-08-17/report.md)

## External Source References

- [USGS Earthquake Catalog API](https://earthquake.usgs.gov/fdsnws/event/1/)
- [Ready.gov Earthquakes](https://www.ready.gov/earthquakes)
- [Ready.gov Floods](https://www.ready.gov/floods)
- [Ready.gov Home Fires](https://www.ready.gov/home-fires)
- [American Red Cross First Aid Steps](https://www.redcross.org/take-a-class/first-aid/performing-first-aid/first-aid-steps)
- [OpenStreetMap copyright and attribution](https://www.openstreetmap.org/copyright)
