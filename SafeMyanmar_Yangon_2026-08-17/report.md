# SafeMyanmar disaster-response data — Yangon Region

**Snapshot retrieved:** 2026-08-17T13:42:17+00:00  
**Country:** Myanmar  
**Target:** Yangon Region (not only Yangon municipal area)  
**Safety notice:** No route, shelter, road or location in this report is guaranteed safe. Always confirm through current local authorities and multiple independent sources before operational use.

## 1. Executive summary

- **No verified current Yangon shelter list was found.** `shelters.csv` contains only its schema header and `shelters.json` is an empty array. OpenStreetMap facilities were not re-labelled as official shelters.
- **One current official weather record** was extracted from DMH: rain or thundershowers for Yangon and neighbouring area, with cumulonimbus clouds developing in Yangon Region. DMH supplied no categorical severity or forecast polygon, so severity is `unknown`; the attached Yangon Region boundary is only a coverage envelope.
- **The latest USGS catalog earthquake found inside Yangon Region** for 1 January 2025 through retrieval time was a reviewed M3.5 event on 4 July 2026. It is historical and marked stale; it is not a current warning.
- **One recent Yangon fire incident** was retained as a stale incident. Its verified source did not provide coordinates, so its GeoJSON Feature geometry is `null` rather than estimated.
- **No verified current Yangon flood zone, cyclone warning or landslide warning was found.** A 2015 UNOSAT flood-water layer exists but is archived, medium-confidence and not field validated; it is listed as a source but intentionally excluded from the current hazard records.
- **No verified current road closure was found.** One official 16 August tree obstruction was retained as resolved/stale because MFSD reported clearance work completed; the report did not explicitly say the road reopened, so status remains `unknown`.
- Validation passed: coordinate ranges, non-null GeoJSON validity, timezone-aware record timestamps, unique IDs, stale marking and HTTPS source URLs were checked. One hazard and one road Feature intentionally use RFC 7946-permitted null geometry because official coordinates were not published.

## 2. Source table

Full publication/update/expiry and coverage fields are in `sources.csv`.

| Owner | URL | Data type | Update frequency | License | Reliability | Yangon result |
|---|---|---|---|---|---|---|
| Myanmar Department of Disaster Management / Relief and Resettlement Department | [source 1](https://www.rrdmyanmar.gov.mm/) | Official disaster situation reports and management information | Event-driven; public schedule not stated | No open-data license found | official | Site timed out; no verified current shelter list extracted |
| Myanmar Department of Meteorology and Hydrology | [source 2](https://www.moezala.gov.mm/en/forecast/132523) | Daily weather forecast / severe-weather conditions | Several times daily | No open-data license; site footer says all rights reserved | official | Included as current severe-weather forecast, severity unknown |
| Myanmar Department of Meteorology and Hydrology | [source 3](https://www.moezala.gov.mm/en/cyclone-warning) | Cyclone / low-pressure warnings | Event-driven | No open-data license; site footer says all rights reserved | official | No verified current Yangon cyclone warning found |
| Myanmar Red Cross Society | [source 4](https://www.redcross.org.mm/) | Humanitarian response reports, evacuation support and relief | Event-driven | Website says all rights reserved; no dataset license found | humanitarian | No named, geocoded current Yangon shelter list found |
| IFRC GO / Myanmar Red Cross Society | [source 5](https://go.ifrc.org/field-reports/18516) | Flood field report and humanitarian needs | Event-driven | No record-level open-data license found | humanitarian | Not imported; no current named Yangon shelter records |
| Myanmar Information Management Unit (MIMU) | [source 6](https://themimu.info/emergencies/general) | Emergency pages, situation reports and maps | Frequent during emergencies | Product-specific; no license inferred | humanitarian | Direct emergency pages intermittently returned 403; no current Yangon record extracted |
| OCHA Field Information Services Section (FISS) | [source 7](https://data.humdata.org/dataset/cod-ab-mmr) | Administrative boundaries, levels 0–5 | Periodic/review-based | CC BY 3.0 IGO / CC BY-IGO | humanitarian reference | Used only as the region boundary / coverage envelope |
| United Nations Satellite Centre (UNOSAT) | [source 8](https://data.humdata.org/dataset/geodata-of-flood-waters-near-city-of-yangon-myanmar-august-10-2015) | Satellite-detected flood-water polygons | Archived one-off activation | HDX license field: Other; no license URL | humanitarian scientific, medium confidence | Not imported into current hazards; not field validated and historical |
| U.S. Geological Survey Earthquake Hazards Program | [source 9](https://earthquake.usgs.gov/earthquakes/eventpage/us6000ta1y) | Earthquake event catalog / GeoJSON API | Real-time feeds updated every minute | U.S. Public Domain; attribution requested | scientific | Latest catalog event inside region included as historical incident |
| GDACS / European Commission JRC / UN cooperation framework | [source 10](https://www.gdacs.org/report.aspx?episodeid=14&eventid=1104011&eventtype=FL) | Global disaster alert; Myanmar flood FL 1104011 | Feeds approximately every 6 minutes | GDACS disclaimer/terms; no open license inferred | scientific humanitarian alert | Excluded: stale event and centroid outside Yangon Region |
| Copernicus Emergency Management Service | [source 11](https://mapping.emergency.copernicus.eu/activations/EMSR798/) | Rapid mapping for 2025 Myanmar earthquake | Event-driven activations | CEMS free, full and open access subject to terms and citation requirements | scientific humanitarian mapping | Not imported; historical and no verified current Yangon product |
| Myanmar Fire Services Department | [source 12](https://www.fsd.gov.mm/news-detail/1760) | Official road obstruction and clearance report | Event-driven | No open-data license found; site copyright applies | official | Included as resolved/stale obstruction with null geometry |
| Global New Light of Myanmar, citing Myanmar Fire Services Department | [source 13](https://www.gnlm.com.mm/ybs-bus-catches-fire-near-sanpya-market/) | Officially sourced fire incident report | Event-driven | No open-data license found; site copyright applies | official report | Included as stale fire incident with null geometry |
| OpenStreetMap contributors / OpenStreetMap Foundation | [source 14](https://www.openstreetmap.org/copyright) | Crowdsourced roads, buildings and public facilities | Continuous | ODbL 1.0; attribution and share-alike requirements | crowdsourced | Not used to label any shelter or to infer safe routes |

## 3. Extracted shelter data as CSV

File: `shelters.csv`

```csv
id,name,latitude,longitude,address,capacity,status,facilities,disaster_types,contact,source,source_url,issued_at,updated_at,expires_at,license,verification_level,retrieved_at,is_stale
```

Result: **no verified current data found**.

## 4. Extracted shelter data as JSON

File: `shelters.json`

```json
[]
```

## 5. Extracted hazard data as GeoJSON and JSON

Files: `hazards.geojson` and `hazards.json`

| ID | Type | Current? | Geometry | Verification | Key limitation |
|---|---|---:|---|---|---|
| dmh-yangon-weather-20260817-1600-mst | severe_weather | Yes at retrieval | OCHA Yangon Region coverage envelope | official | Not a forecast footprint; no severity category |
| usgs-us6000ta1y | earthquake | No, historical | USGS point, 96.1159 E / 16.6943 N / 10 km depth | scientific | Event record, not an active warning |
| gnlm-ybs-sanpya-20260730 | fire | No, extinguished | null | official report citing MFSD | No source coordinates; no point estimated |

Current flood zones: **no verified current data found**.  
Current cyclone warning for Yangon: **no verified current data found**.  
Current landslide warning for Yangon: **no verified current data found**.

## 6. Road closure data as CSV and JSON

Files: `road_closures.csv` and `road_closures.json`

One stale obstruction record is included for Yangon–Pyay Road at milepost 46/3. MFSD reported the tree obstruction at 07:07 MST and completion of clearance at 07:48 MST on 16 August 2026. Because reopening was not stated explicitly, status is `unknown`, not `open`. Geometry is null because no official coordinates were published.

## 7. Missing or unavailable fields

- Shelters: every field is unavailable because no verified current named/geocoded shelter list was found. Capacity, status, facilities, disaster types and public operational contact details were not inferred.
- DMH weather: no machine-readable forecast geometry, categorical severity, precise expiry time or open-data license.
- USGS earthquake: no PAGER alert/severity and no expiry time; severity remains `unknown`.
- Fire and road obstruction: no verified coordinates. Geometry is null, not geocoded from an unverified source.
- Flood: no verified current Yangon flood-extent layer. The UNOSAT 2015 product is historical and explicitly not field validated.
- Cyclone and landslide: no verified current Yangon-specific warning record found.
- DDM site access timed out. Direct MIMU emergency pages intermittently returned 403; research continued with other public sources.
- Several official and humanitarian pages did not state reusable-data licenses. Those records must not be redistributed beyond what their terms permit without review.

## 8. Data-quality problems and duplicates

- No duplicate IDs were detected. No exact record duplicates were found.
- Yangon **Region** is much larger than Yangon city. SafeMyanmar should store both the administrative code `MMR013` and the more precise locality text where available.
- The DMH administrative polygon is a coverage envelope, not an observed or forecast weather footprint.
- GDACS Myanmar flood FL 1104011 was excluded because it ended on 13 August and its centroid (94.6075, 20.318) lies outside Yangon Region.
- Multiple national flood stories refer to the same wider 2026 monsoon event but do not publish usable Yangon geometries. They were not converted into duplicate Yangon hazards.
- The UNOSAT 2015 layer reports medium confidence, possible under-detection in vegetation and built-up areas, and no field validation. It is unsuitable as a current flood zone.
- Source timestamps are preserved with timezone only when the source published or clearly implied one. Source-table metadata that lacks a timezone is labelled as such rather than guessed.
- Private names, ages, phone numbers and email addresses present in source pages were not extracted.

## 9. Recommended refresh interval

| Source/data | Normal | During active event | Staleness rule |
|---|---:|---:|---|
| DMH forecasts/warnings | 30 minutes | 10–15 minutes | Supersede by newer bulletin; do not invent expiry |
| USGS GeoJSON feeds | 5 minutes | 1–5 minutes | Keep events as history; update on source `updated` |
| GDACS | 10 minutes | 6 minutes | Mark stale after source `todate` |
| MFSD fire/road reports | 30 minutes | 10–15 minutes | Preserve resolution time; do not assume reopening |
| DDM/MRCS/IFRC/OCHA/MIMU | 6 hours | 1–3 hours | Use publication-specific validity and manual review |
| OCHA COD boundaries | Monthly | Weekly metadata check | Version by dataset release |
| OSM basemap facilities/roads | Weekly | Daily when operationally needed | Always retain `crowdsourced`; never auto-promote shelters |

## 10. SafeMyanmar PostgreSQL/PostGIS import recommendations

1. Use separate tables: `sources`, `shelters`, `hazards`, `road_events`, and immutable `ingest_runs`. Keep `raw_record jsonb` on every ingested row.
2. Store geometry as `geometry(Geometry, 4326)` and index with GiST. Validate with `ST_IsValid`, coordinate-range checks and geometry-type constraints before promotion from staging.
3. Keep `issued_at`, `updated_at`, `expires_at`, `retrieved_at`, `is_stale`, `verification_level`, `source_url`, `license`, `geometry_source_url` and `geometry_note` as first-class columns.
4. Deduplicate on `(source, source_record_id)` and retain source revisions instead of overwriting. Expose a `latest_non_stale` view for the app.
5. Treat null geometry as valid missing data. Never manufacture a point from a township name or street address without saving a separate geocoder source and confidence.
6. Keep `incident_verification` and `geometry_verification` separate. An official incident can still have crowdsourced or missing geometry.
7. Default unknown source statuses and severities to `unknown`; never infer `open`, `closed`, `safe`, `low` or `high` without a documented rule and provenance.
8. Do not allow the routing service to label a route “safe.” At most, show time-bounded warnings and avoid confirmed fresh closures, with visible source age and verification level.
9. Suggested import expression for GeoJSON: `ST_SetSRID(ST_GeomFromGeoJSON(feature->'geometry'), 4326)` only when geometry is non-null. Load CSVs into staging tables with `\copy`, then validate and upsert.
10. Add a license-policy gate. The USGS and OCHA COD records are reusable under their stated terms; official Myanmar pages with no open-data license should be linked and minimally quoted unless permission is confirmed.

### Validation result

`validation.json` status: **passed**. Valid non-null geometries: 2; intentional null geometries: 1; duplicate IDs: 0.
