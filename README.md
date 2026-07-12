# SafeMyanmar

> **AI Context-Aware Disaster Response Mobile Application for Myanmar**

SafeMyanmar is a mobile disaster-response application designed for the **Mobile and Ubiquitous Computing** subject. It helps people receive trusted disaster alerts, locate safer evacuation routes, request emergency assistance, and access first-aid guidance before, during, and after natural disasters.

The project combines **mobile computing, ubiquitous computing, GPS, mobile sensors, edge computing, cloud computing, artificial intelligence, and optional high-performance computing** to provide fast and context-aware emergency support.

---

## Project Information

| Item | Description |
|---|---|
| Project Name | SafeMyanmar |
| Project Type | Mobile Application |
| Subject | Mobile and Ubiquitous Computing |
| Target Platform | Android, with possible future iOS support |
| Main Context | Disaster preparedness and emergency response in Myanmar |
| Current Status | Academic prototype / MVP |

---

## Problem Statement

Myanmar is vulnerable to earthquakes, floods, cyclones, fires, landslides, and severe weather. During emergencies, people may have difficulty:

- receiving verified and timely information;
- identifying safe evacuation routes;
- contacting family members or rescue teams;
- sharing their current or last known location;
- finding reliable first-aid instructions;
- accessing online services when mobile connectivity is unstable.

SafeMyanmar addresses these problems through a mobile-first and context-aware emergency platform.

---

## Project Objectives

SafeMyanmar aims to:

- provide trusted disaster alerts from verified sources;
- detect the user's location and suggest safer evacuation routes;
- allow users to send SOS messages quickly;
- help nearby people or rescue teams locate trapped victims;
- provide emergency and first-aid guidance;
- continue offering essential information during limited connectivity;
- reduce disaster response time;
- demonstrate practical mobile and ubiquitous computing concepts.

---

## Target Users

- Citizens
- Families
- Students
- Volunteers
- Rescue teams
- Humanitarian organizations
- Government disaster-management organizations

---

## Core Features

### 1. Trusted Disaster Alerts

Users receive verified alerts for events such as:

- earthquakes;
- floods;
- fires;
- landslides;
- cyclones;
- heavy rain;
- severe weather.

Each alert may include the disaster type, affected area, severity, time, safety instructions, and source.

### 2. GPS Safe-Route Navigation

The app detects the user's current location and recommends a safer route by considering:

- nearby evacuation shelters;
- blocked roads;
- flooded areas;
- fire danger zones;
- updated disaster conditions.

The route can be recalculated when the user's position or environmental conditions change.

### 3. SOS Emergency Button

The SOS feature prepares or sends an emergency message containing:

- the user's GPS location;
- date and time;
- emergency status;
- optional personal message;
- last known location when a live connection is unavailable.

The message can be shared with saved emergency contacts. Integration with official rescue services is treated as a future feature unless an authorized service is available.

### 4. Rescue Beacon Mode

When activated, Rescue Beacon Mode can:

- play a loud emergency alarm;
- flash the phone flashlight in an SOS pattern;
- display a large **HELP** message;
- periodically share location when connectivity is available;
- reduce non-essential activity to preserve battery.

### 5. AI Emergency Assistant

The assistant provides guidance for questions such as:

- What should I do during an earthquake?
- How can I control bleeding?
- What should I do for a burn?
- What should I do if I am trapped?

When the internet is available, the app may use a cloud AI service. During limited connectivity, it falls back to an offline emergency knowledge base.

> The AI assistant is an educational support feature and must not replace professional medical advice or instructions from authorized emergency personnel.

### 6. Offline First-Aid Guide

Essential instructions remain available locally for:

- CPR;
- bleeding control;
- burns;
- fractures;
- earthquake safety;
- flood safety;
- fire safety.

### 7. Trusted Disaster Reports

The application displays reports from verified organizations, such as:

- government disaster-management agencies;
- meteorology and weather agencies;
- fire services;
- earthquake monitoring services;
- recognized humanitarian organizations.

### 8. Damage Reporting

A future reporting feature may allow users to submit:

- photos;
- GPS coordinates;
- descriptions;
- date and time;
- damage category.

Examples include flooded roads, fallen trees, fires, damaged buildings, and blocked roads. Reports should be reviewed before public distribution.

---

## Mobile Computing Concepts

SafeMyanmar demonstrates the following mobile-computing concepts:

### GPS and Location Services

- detects the user's real-time location;
- finds nearby shelters;
- supports evacuation navigation;
- attaches location to SOS and damage reports.

### Mobile Sensors and Hardware

- GPS;
- camera;
- flashlight;
- accelerometer for future movement or impact detection;
- network-state monitoring;
- battery-state monitoring.

### Wireless Communication

- mobile networks such as 4G and 5G;
- Wi-Fi;
- push notifications;
- Bluetooth or nearby-device communication as a future enhancement.

### Mobility

The app continues adapting while the user moves by updating location, route, nearby threats, shelters, and emergency recommendations.

---

## Ubiquitous Computing Concepts

SafeMyanmar is designed as a **context-aware system**. It observes relevant context such as:

- the user's location;
- the current disaster type;
- nearby danger areas;
- the nearest shelter;
- internet availability;
- battery level;
- time;
- possible assistance required.

Based on this context, the application can automatically prioritize relevant alerts, cache emergency information, update routes, and recommend suitable actions with minimal user interaction.

---

## Edge and Offline Computing

Important emergency functions should not depend completely on the cloud.

Local or edge-side processing may handle:

- offline first-aid content;
- cached alerts and shelter information;
- local route segments;
- network-state detection;
- beacon operation;
- queued SOS or damage reports;
- synchronization when connectivity returns.

This improves response time, reduces network dependency, and supports users during unstable connectivity.

---

## System Architecture

```mermaid
flowchart TD
    A[Trusted Data Sources<br/>Government, Weather, Earthquake and Disaster Services]
    B[Cloud Backend]
    C[AI Emergency Assistant]
    D[Disaster Database]
    E[Notification Service]
    F[Edge and Offline Layer]
    G[SafeMyanmar Mobile App]
    H[GPS and Location]
    I[Camera and Sensors]
    J[Flashlight and Beacon]
    K[User Emergency Features]

    A --> B
    B --> C
    B --> D
    B --> E
    B <--> F
    F <--> G
    G --> H
    G --> I
    G --> J
    G --> K
```

### Simplified Data Flow

1. Trusted services publish disaster information.
2. The backend validates, stores, and distributes alerts.
3. The notification service sends relevant alerts to users.
4. The mobile app combines alerts with the user's current context.
5. Offline and edge components preserve essential functionality.
6. SOS, location, and user reports are synchronized when a connection is available.

---

## Recommended Technology Stack

The final stack can be adjusted according to course requirements.

### Mobile Application

- **Flutter**
- Dart
- Material Design
- Provider, Riverpod, or BLoC for state management
- SQLite, Hive, or Isar for offline storage
- Google Maps SDK or OpenStreetMap
- Geolocator for GPS
- Firebase Cloud Messaging for notifications

### Backend

- **FastAPI** with Python 3.13
- SQLAlchemy 2 with Psycopg 3
- PostgreSQL 16
- Docker Compose for the API and development database

The current backend increment provides the application foundation and health endpoints.
Authentication, mapping, AI, alerts, and other disaster-response APIs remain future work.

### Cloud Services

- Firebase Authentication or JWT-based authentication
- Firebase Cloud Messaging
- Object storage for report photos
- Cloud-hosted API and database

### AI and Data Processing

- Rule-based offline emergency assistant for the MVP
- Cloud AI service for enhanced question answering
- Optional image classification for future damage analysis
- Optional HPC-based simulation and large-scale route optimization

---

## Suggested Project Structure

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
│   │   ├── first_aid/
│   │   ├── maps/
│   │   └── icons/
│   └── pubspec.yaml
├── backend/
│   ├── app/
│   │   ├── api/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── services/
│   │   ├── database/
│   │   └── main.py
│   ├── tests/
│   └── requirements.txt
├── docs/
│   ├── architecture/
│   ├── api/
│   └── screenshots/
├── .env.example
├── LICENSE
└── README.md
```

---

## MVP Scope

A realistic academic MVP should focus on:

- user registration or guest access;
- disaster-alert list and detail screen;
- GPS location detection;
- map with shelters and danger zones;
- SOS message generation and emergency-contact sharing;
- Rescue Beacon Mode;
- offline first-aid guide;
- local caching of essential disaster information;
- demonstration of context-aware recommendations.

Features involving official rescue dispatch, nationwide live hazard routing, or medical diagnosis should remain outside the MVP unless supported by authorized and reliable data providers.

---

## Functional Requirements

- The app shall display verified disaster alerts.
- The app shall request and process location permission.
- The app shall identify nearby shelters from available data.
- The app shall display a suggested evacuation route.
- The app shall allow the user to activate SOS mode.
- The app shall store emergency contacts locally or securely.
- The app shall activate audio, flashlight, and visual rescue signals.
- The app shall provide offline first-aid guidance.
- The app shall cache recently received alerts.
- The app shall synchronize pending data after connectivity returns.
- The app shall notify users about relevant nearby disasters.

---

## Non-Functional Requirements

### Performance

- Emergency screens should open quickly.
- Cached content should remain usable without internet access.
- Location and route updates should avoid unnecessary battery usage.

### Reliability

- Essential information should be stored locally.
- Failed requests should be retried safely.
- Pending SOS and reports should be queued until connectivity returns.

### Security and Privacy

- Location must only be collected with permission.
- Sensitive data must be encrypted during transmission.
- Access tokens and API keys must not be hard-coded.
- Emergency contacts must be stored securely.
- Public reports should not reveal unnecessary personal information.

### Usability

- The interface should support one-handed use.
- Emergency actions should use large and clear controls.
- Critical instructions should use simple language.
- The app should support Myanmar and English in a future multilingual version.
- Important screens should remain readable in low-light and stressful conditions.

### Accessibility

- large text support;
- high-contrast emergency interfaces;
- icon and text labels;
- vibration and sound feedback;
- compatibility with screen readers where possible.

---

## Required Mobile Permissions

Depending on the implemented features, the application may request:

- precise or approximate location;
- background location only when clearly required;
- camera access;
- flashlight access;
- notification permission;
- internet and network-state access;
- vibration;
- local storage access where applicable.

Permissions should be requested only when needed, with a clear explanation.

---

## Installation

### Prerequisites

- Flutter SDK
- Android Studio or Visual Studio Code
- Android SDK
- Python 3.13
- PostgreSQL 16, or Docker Desktop with Docker Compose
- Git

### Clone the Repository

```bash
git clone https://github.com/your-username/safemyanmar.git
cd safemyanmar
```

### Run the Mobile Application

```bash
cd mobile
flutter pub get
flutter run
```

### Run the Backend

From the repository root, create the backend environment:

```powershell
cd backend
py -3.13 -m venv .venv
```

Activate the environment:

```bash
# Windows PowerShell
.venv\Scripts\Activate.ps1

# macOS or Linux
source .venv/bin/activate
```

Install dependencies and start the API:

```powershell
pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn app.main:app --reload
```

Set a usable `DATABASE_URL` in `backend/.env` before starting the API. The API
is available at `http://localhost:8000`; liveness and database readiness are
reported by `/health/live` and `/health/ready`.

Alternatively, start the API and PostgreSQL 16 from the repository root:

```powershell
docker compose up --build
```

---

## Environment Variables

Create `backend/.env` from `backend/.env.example`. Only `DATABASE_URL` is
required in the current increment; the remaining values have the defaults shown.

```env
DATABASE_URL=postgresql+psycopg://user:password@localhost:5432/safemyanmar
USGS_FEED_URL=https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson
PROVIDER_TIMEOUT_SECONDS=10.0
REFRESH_MINIMUM_SECONDS=60
CURRENT_MAX_AGE_SECONDS=300
```

JWT, Mapbox, Firebase, and AI configuration are not required or implemented in
this backend increment. Never commit real secrets to the repository.

---

## Testing

Recommended testing areas include:

- unit tests for alert filtering and context rules;
- widget tests for emergency screens;
- API tests for alerts, shelters, SOS, and reports;
- offline-mode tests;
- location-permission tests;
- low-battery and poor-network simulations;
- usability testing for quick SOS activation.

Example commands:

```bash
# Flutter tests
cd mobile
flutter test

# Backend tests (from the repository root)
backend/.venv/Scripts/python -m pytest backend/tests
backend/.venv/Scripts/python -m ruff format --check backend
backend/.venv/Scripts/python -m ruff check backend
```

---

## Future Enhancements

- verified user-generated damage reports;
- rescue-team dashboard;
- multilingual Myanmar and English support;
- Bluetooth-based nearby distress broadcasting;
- peer-to-peer communication during network outages;
- accelerometer-based impact detection;
- disaster-image recognition;
- damage-severity prediction;
- personalized emergency recommendations;
- official rescue-service integration;
- large-scale evacuation optimization;
- flood and earthquake simulation using HPC resources.

---

## Academic Relevance

SafeMyanmar demonstrates practical use of:

- mobile computing;
- ubiquitous and context-aware computing;
- GPS and mobile sensors;
- wireless communication;
- push notifications;
- offline-first design;
- edge computing;
- cloud computing;
- artificial intelligence;
- optional high-performance computing.

The project shows how a mobile device can sense context, communicate wirelessly, adapt to changing conditions, and provide useful services while the user is moving.

---

## Limitations

- Disaster information is only as reliable as its data sources.
- GPS accuracy may decrease indoors or in dense urban areas.
- Safe-route recommendations may be incomplete when road data is outdated.
- SMS, calls, and internet services may fail during major disasters.
- The prototype must not claim direct connection to rescue organizations unless such integration is officially implemented.
- First-aid and AI guidance should not be treated as a substitute for trained professionals.

---

## Emergency Disclaimer

SafeMyanmar is an academic disaster-support application. It does not guarantee rescue, route safety, medical accuracy, or continuous network availability. In a real emergency, users should follow instructions from local authorities and contact officially recognized emergency services whenever possible.

---

## Contributors

| Name | Role |
|---|---|
| Add team member | Mobile Developer |
| Add team member | Backend Developer |
| Add team member | UI/UX Designer |
| Add team member | Research and Documentation |

---

## License

This project is intended for academic and educational use. Add an open-source license such as MIT if the project will be published publicly.

---

## Acknowledgements

This project is inspired by the need for accessible, trusted, and context-aware disaster-response technology for communities in Myanmar.
