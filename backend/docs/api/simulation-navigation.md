# Navigation API

The default development configuration loads the validated snapshot configured
by `NAVIGATION_DATA_PATH`. At startup, the snapshot must pass validation and be
no more than 30 days old; otherwise `/health/ready` returns a safe
`navigation_data_missing`, `navigation_data_invalid`, or `navigation_data_stale`
error. The current Yangon snapshot exposes current hazard records but no
verified shelters or lower-exposure destination dataset, so those lists and
context-area recommendations may be empty. Stale or geometry-less records are
excluded, including shelters. Real context analysis only runs for earthquake
and flood data with a current snapshot hazard geometry; unsupported real
disaster types return `503 context_analysis_unavailable` rather than a generic
lower-exposure result. It never turns the absence of a hazard record into a
safety claim. Responses include source, timestamp, `simulation: false`, and an
uncertainty notice. Set
`ENABLE_SIMULATION_ANALYSIS=true` in a non-production environment to include
fictional hazard geometry in real `/context-areas` calculations only. The source
and uncertainty notice identify this mixed analysis, while `/hazards` and
`/shelters` continue to return collected snapshot data only.

The fictional API described below remains available only when
`ENABLE_SIMULATION_DATA=true`. It is for development demonstrations only and
must not be used as official hazard or evacuation data.

These endpoints expose fictional demonstration records and deterministic
context-analysis candidates. They are
available only when `ENABLE_SIMULATION_DATA=true`; startup rejects that setting
when `ENVIRONMENT=production`. Every record is labeled `SIMULATION`, attributed
to `SafeMyanmar Demo`, timestamped, and marked `simulation: true`.

When simulation data is disabled and no navigation snapshot is configured,
these routes are not registered or included in OpenAPI. With the default
validated snapshot, shelter, hazard, and context-area routes remain registered
with `simulation: false`; route suggestions return `503 routing_unavailable`
when no verified destination or directions provider is available.

This API does not provide official hazard information or guarantee route safety.
Clients should keep timestamps, attribution, rationale, and uncertainty notices
visible. Shelter and hazard lists remain available if routing is unavailable.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `ENABLE_SIMULATION_DATA` | `false` | Enables all three simulation endpoints outside production |
| `ENABLE_SIMULATION_ANALYSIS` | `false` | Adds labeled simulation hazards to real context-area analysis only; forbidden in production |
| `NAVIGATION_DATA_PATH` | `SafeMyanmar_Yangon_2026-08-17` | Validated real navigation snapshot directory |
| `OVERPASS_API_URL` | `https://overpass-api.de/api/interpreter` | Mapped building/tree lookup for earthquake analysis |
| `ELEVATION_API_URL` | `https://api.opentopodata.org/v1/aster30m` | Terrain elevation lookup for flood analysis |
| `MAPBOX_DIRECTIONS_ACCESS_TOKEN` | unset | Secret Mapbox token required only for route suggestions |
| `PROVIDER_TIMEOUT_SECONDS` | `10.0` | Timeout used for Mapbox and USGS requests |

The Directions integration always uses the trusted HTTPS host
`api.mapbox.com`, requests `alternatives=true`, full GeoJSON geometry, and
returns no more than the routes Mapbox supplies (up to three). Request origins
and destinations are neither persisted nor logged.

An enabled simulation deployment must remain nonpublic unless an independent
authentication or network-access control protects it. Restrict the backend
Mapbox token to the Directions API and the smallest practical usage scope. The
process permits at most four concurrent Mapbox calls and 30 route POSTs per
client host in a rolling 60-second window. Rate-limit state uses only the client
host's fixed-size, per-process keyed hash, expires in memory, and retains at most
1,024 hashes; it does not retain raw hosts or use tokens or coordinates as keys.
These per-process limits do not replace an authenticated edge rate limiter for
any shared deployment.

Context analysis is separately limited to 10 POSTs per client host in a rolling
60-second window and at most two concurrent analyses per process. These limits
also apply to explicitly enabled simulation analysis and do not replace an
authenticated edge rate limiter for a shared deployment.

Mapbox responses are limited to 1 MiB, three routes, and 5,000 geometry points
per route before geometry scoring. Malformed, non-finite, overflowing, or
oversized provider values are rejected as provider failures.

## `GET /api/v1/shelters`

Returns the configured shelter collection and its data timestamp. The current
Yangon snapshot returns an empty collection because no verified shelter records
were supplied.

## `GET /api/v1/hazards`

Returns current snapshot polygon hazards and their data timestamp. Stale or
geometry-less records are omitted.

## `POST /api/v1/context-areas`

Calculates up to three comparative lower-exposure area candidates around an
explicitly supplied origin. In real mode, the requested disaster type must
have a current snapshot hazard geometry. Earthquake candidates additionally
use mapped building/tree features, and flood candidates additionally use
terrain elevation. Fire, cyclone, landslide, and severe-weather analysis uses
hazard geometry only and does not assess spread, wind, slope stability,
structures, roads, or shelter availability. The request body is:

```json
{
  "origin": {"latitude": 21.95, "longitude": 96.08},
  "disaster_type": "earthquake",
  "scenario": "outdoors_after_shaking",
  "search_radius_m": 1000
}
```

Earthquake candidates are available only for `outdoors_after_shaking`; active
shaking returns Drop, Cover, and Hold On guidance instead of destinations. Flood
candidates rank higher terrain elevation and reject current mapped flood
polygons. Earthquake candidates compare mapped building and tree clearance.
Other disaster types reject candidates that intersect their current mapped
hazard polygons. These are comparative metrics from snapshot and external
geodata, not surveyed conditions or official advice. Mapped data may be
incomplete, and the result is never a guaranteed safe place.

## `POST /api/v1/route-suggestions`

Request body:

```json
{
  "origin": {"latitude": 21.95, "longitude": 96.08},
  "shelter_id": "simulation-shelter-1",
  "context_area_id": "context-area-earthquake-2195500-9608000",
  "disaster_type": "earthquake",
  "scenario": "outdoors_after_shaking",
  "search_radius_m": 1000,
  "profile": "walking"
}
```

`context_area_id` is optional for the legacy fixed-shelter demonstration
contract, but new clients should send it after selecting a result from
`/context-areas`. The backend recomputes the candidate from the origin and
disaster and search radius before requesting directions.

`profile` is optional and accepts `walking` or `driving`. If omitted, walking is
selected for a straight-line distance of 5 km or less and driving otherwise.
The response states this rule; callers can override it by sending `profile`.
Supported disasters are `earthquake`, `flood`, `fire`, `cyclone`, `landslide`,
and `severe_weather`.

Simulation coverage is provided by two separate fictional city regions:

| Region | Latitude | Longitude |
|---|---|---|
| Mandalay | `21.9300` to `21.9900` | `96.0600` to `96.1200` |
| Yangon | `16.8000` to `16.9200` | `96.0800` to `96.2000` |

The Yangon region supports testing with real Yangon device GPS readings while
remaining fictional demonstration data. Origins outside both regions are
rejected before Mapbox is called. Provider route candidates must remain inside
the same region as the origin; candidates that leave it are discarded and are
never described as suggested safer routes.

Returned Mapbox route geometries are scored against relevant simulation hazard
polygons. Ranking is deterministic: fewest intersected polygons, then shortest
duration, then shortest distance. No alternative is generated if Mapbox returns
fewer than three. The recommended option says exactly: "Suggested safer route
based on currently available SIMULATION information."

Errors use the standard safe envelope. Missing or failed Mapbox access returns
`503 routing_unavailable`; malformed requests return `422 invalid_request`; an
unknown shelter returns `404 shelter_not_found`; an origin outside coverage
returns `400 outside_simulation_area`; rate limits return `429
route_rate_limit_exceeded`; and exhausted provider concurrency returns `503
routing_busy`. The `429` and busy `503` responses include bounded `Retry-After`
headers. Error responses do not include the origin, destination, provider URL,
or token.

Context-analysis rate limits return `429 context_rate_limit_exceeded`; exhausted
analysis capacity returns `503 context_analysis_busy`. Both include a bounded
`Retry-After` header.
