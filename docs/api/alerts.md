# Live Earthquake API

## Conventions

- Timestamps are timezone-aware UTC values serialized as RFC 3339 with `Z`.
- The only current provider is `usgs`; source links use trusted USGS HTTPS hosts.
- A successful snapshot is `current` for five minutes after
  `last_successful_refresh_at`, then `stale`.
- List refresh attempts are throttled to one per 60 seconds and serialized with
  a PostgreSQL advisory lock.
- Item objects deliberately have no `severity` or `freshness` field. Magnitude
  is an observation, not an inferred impact assessment.
- Coverage is the inclusive Yangon Region envelope: latitude
  `14.04582802200008` to `17.79695808500003`, longitude `93.35195104000019` to
  `96.82662590900009`. This coarse administrative envelope is not an affected
  area or political border.
- A refresh searches the latest ten years and the list returns at most ten items,
  ordered by descending event time. Fewer items are returned when fewer records
  are available in the coverage envelope.

## Health

### `GET /health/live`

Process liveness. A successful response is `200`:

```json
{"status":"ok"}
```

### `GET /health/ready`

Checks PostgreSQL connectivity. A successful response is `200` with the same
body. Database failure returns the safe `503` error shape below with code
`service_unavailable`.

## List Alerts

### `GET /api/v1/alerts`

Returns up to the ten latest successful normalized USGS observations in the
Yangon Region coverage envelope and may refresh the snapshot when the 60-second
throttle permits. Exact response fields:

| Field | Type | Meaning |
|---|---|---|
| `items` | array of alert items | Up to ten in-bounds USGS observations, event time descending |
| `data_status` | `current` or `stale` | Age of the last successful backend snapshot |
| `last_successful_refresh_at` | UTC timestamp | Successful provider retrieval time |
| `provider` | `usgs` | Snapshot provider |

Structural example only; placeholders are not runnable fixture data:

```jsonc
{
  "items": [
    {
      "id": "usgs:<provider-event-id>",
      "provider": "usgs",
      "provider_event_id": "<provider-event-id>",
      "kind": "earthquake_information",
      "title": "<USGS title>",
      "place": "<USGS place description>",
      "magnitude": "<number>",
      "depth_km": "<number>",
      "latitude": "<number>",
      "longitude": "<number>",
      "event_at": "<UTC RFC3339 timestamp>",
      "provider_updated_at": "<UTC RFC3339 timestamp>",
      "retrieved_at": "<UTC RFC3339 timestamp>",
      "review_status": "<string or null>",
      "source_url": "https://earthquake.usgs.gov/earthquakes/eventpage/<provider-event-id>",
      "version": "<positive integer>"
    }
  ],
  "data_status": "<current or stale>",
  "last_successful_refresh_at": "<UTC RFC3339 timestamp>",
  "provider": "usgs"
}
```

A valid successful empty provider snapshot returns `200` with `items: []`, not
an error. If no successful snapshot exists and provider retrieval fails, the
endpoint returns `503 live_data_unavailable`.

## Alert Detail

### `GET /api/v1/alerts/{id}`

Returns one exact alert item using the `usgs:<provider-event-id>` ID. This read
uses persisted data and does not refresh USGS. Missing and non-USGS IDs return
`404 not_found`.

## Error Shape

All handled errors use the exact safe envelope below and include the same
request ID in the `X-Request-ID` response header:

```jsonc
{
  "error": {
    "code": "<stable-code>",
    "message": "<safe message>",
    "request_id": "<request-id>"
  }
}
```

| Status | Code | Message |
|---|---|---|
| `404` | `not_found` | `Earthquake information was not found.` for a missing item; unknown routes use `The requested resource was not found.` |
| `503` | `live_data_unavailable` | `Live earthquake data is currently unavailable.` |
| `503` | `service_unavailable` | `The service is not ready.` |
| `500` | `internal_server_error` | `An unexpected error occurred.` |

Responses never expose stack traces, database details, credentials, internal
paths, or provider payloads.

## Provider Limitations

The API currently represents USGS earthquake observations from a ten-year FDSN
catalog query that fall within the coarse Yangon Region coverage envelope. It
does not provide official warnings, predictions, evacuation orders, complete
all-disaster coverage, impact/severity classification, or guaranteed safety
information.
