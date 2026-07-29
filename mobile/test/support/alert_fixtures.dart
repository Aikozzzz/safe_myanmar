import 'package:mobile/features/alerts/domain/earthquake.dart';

Map<String, Object?> validAlertJson({
  String id = 'usgs:example',
  String providerEventId = 'example',
}) => <String, Object?>{
  'id': id,
  'provider': 'usgs',
  'provider_event_id': providerEventId,
  'kind': 'earthquake_information',
  'title': 'M 5.2 - Myanmar',
  'place': 'Myanmar',
  'magnitude': 5.2,
  'depth_km': 12.5,
  'latitude': 20.5,
  'longitude': 96.25,
  'event_at': '2026-07-13T01:02:03.000004Z',
  'provider_updated_at': '2026-07-13T01:03:04.000005Z',
  'retrieved_at': '2026-07-13T01:04:05.000006Z',
  'review_status': 'reviewed',
  'source_url': 'https://earthquake.usgs.gov/example',
  'version': 1,
};

Map<String, Object?> validEnvelopeJson({
  List<Object?>? items,
  String dataStatus = 'current',
}) => <String, Object?>{
  'items': items ?? <Object?>[validAlertJson()],
  'data_status': dataStatus,
  'last_successful_refresh_at': '2026-07-13T01:05:06.000007Z',
  'provider': 'usgs',
};

Earthquake earthquakeFixture({
  String id = 'usgs:example',
  String provider = 'usgs',
  String providerEventId = 'example',
  String title = 'M 5.2 - Myanmar',
  String place = 'Myanmar',
  double magnitude = 5.2,
  double depthKm = 12.5,
  DateTime? eventAt,
  DateTime? providerUpdatedAt,
  DateTime? retrievedAt,
  String? reviewStatus = 'reviewed',
  String sourceUrl = 'https://earthquake.usgs.gov/example',
  int version = 1,
}) => Earthquake(
  id: id,
  provider: provider,
  providerEventId: providerEventId,
  kind: 'earthquake_information',
  title: title,
  place: place,
  magnitude: magnitude,
  depthKm: depthKm,
  latitude: 20.5,
  longitude: 96.25,
  eventAt: eventAt ?? DateTime.utc(2026, 7, 13, 1, 2, 3, 4, 5),
  providerUpdatedAt:
      providerUpdatedAt ?? DateTime.utc(2026, 7, 13, 1, 3, 4, 5, 6),
  retrievedAt: retrievedAt ?? DateTime.utc(2026, 7, 13, 1, 4, 5, 6, 7),
  reviewStatus: reviewStatus,
  sourceUrl: sourceUrl,
  version: version,
);
