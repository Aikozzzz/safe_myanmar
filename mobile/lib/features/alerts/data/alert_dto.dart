import '../domain/earthquake.dart';

final class AlertProtocolException implements Exception {
  const AlertProtocolException();

  @override
  String toString() => 'AlertProtocolException: Invalid alert response';
}

final class AlertDto {
  AlertDto._({
    required this.id,
    required this.provider,
    required this.providerEventId,
    required this.kind,
    required this.title,
    required this.place,
    required this.magnitude,
    required this.depthKm,
    required this.latitude,
    required this.longitude,
    required this.eventAt,
    required this.providerUpdatedAt,
    required this.retrievedAt,
    required this.reviewStatus,
    required this.sourceUrl,
    required this.version,
  });

  factory AlertDto.fromJson(Map<String, Object?> json) {
    try {
      _requireExactKeys(json, _itemKeys);
      final providerEventId = _nonEmptyString(json['provider_event_id']);
      final id = _string(json['id']);
      final provider = _string(json['provider']);
      final kind = _string(json['kind']);
      final title = _nonEmptyString(json['title']);
      final place = _nonEmptyString(json['place']);
      final magnitude = _finiteDouble(json['magnitude']);
      final depthKm = _finiteDouble(json['depth_km']);
      final latitude = _finiteDouble(json['latitude']);
      final longitude = _finiteDouble(json['longitude']);
      final reviewStatus = _nullableNonEmptyString(json['review_status']);
      final sourceUrl = _trustedSourceUrl(json['source_url']);
      final version = json['version'];

      if (provider != 'usgs' ||
          kind != 'earthquake_information' ||
          id != 'usgs:$providerEventId' ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180 ||
          version is! int ||
          version <= 0) {
        throw const AlertProtocolException();
      }

      return AlertDto._(
        id: id,
        provider: provider,
        providerEventId: providerEventId,
        kind: kind,
        title: title,
        place: place,
        magnitude: magnitude,
        depthKm: depthKm,
        latitude: latitude,
        longitude: longitude,
        eventAt: _utcTimestamp(json['event_at']),
        providerUpdatedAt: _utcTimestamp(json['provider_updated_at']),
        retrievedAt: _utcTimestamp(json['retrieved_at']),
        reviewStatus: reviewStatus,
        sourceUrl: sourceUrl,
        version: version,
      );
    } on AlertProtocolException {
      rethrow;
    } catch (_) {
      throw const AlertProtocolException();
    }
  }

  final String id;
  final String provider;
  final String providerEventId;
  final String kind;
  final String title;
  final String place;
  final double magnitude;
  final double depthKm;
  final double latitude;
  final double longitude;
  final DateTime eventAt;
  final DateTime providerUpdatedAt;
  final DateTime retrievedAt;
  final String? reviewStatus;
  final String sourceUrl;
  final int version;

  Earthquake toDomain() => Earthquake(
    id: id,
    provider: provider,
    providerEventId: providerEventId,
    kind: kind,
    title: title,
    place: place,
    magnitude: magnitude,
    depthKm: depthKm,
    latitude: latitude,
    longitude: longitude,
    eventAt: eventAt,
    providerUpdatedAt: providerUpdatedAt,
    retrievedAt: retrievedAt,
    reviewStatus: reviewStatus,
    sourceUrl: sourceUrl,
    version: version,
  );
}

final class AlertEnvelopeDto {
  AlertEnvelopeDto._({
    required List<AlertDto> items,
    required this.dataStatus,
    required this.lastSuccessfulRefreshAt,
    required this.provider,
  }) : items = List.unmodifiable(items);

  factory AlertEnvelopeDto.fromJson(Map<String, Object?> json) {
    try {
      _requireExactKeys(json, _envelopeKeys);
      final rawItems = json['items'];
      final provider = _string(json['provider']);
      final status = _string(json['data_status']);
      if (rawItems is! List || provider != 'usgs') {
        throw const AlertProtocolException();
      }

      return AlertEnvelopeDto._(
        items: rawItems.map((item) {
          if (item is! Map) throw const AlertProtocolException();
          return AlertDto.fromJson(item.cast<String, Object?>());
        }).toList(),
        dataStatus: switch (status) {
          'current' => AlertDataStatus.current,
          'stale' => AlertDataStatus.stale,
          _ => throw const AlertProtocolException(),
        },
        lastSuccessfulRefreshAt: _utcTimestamp(
          json['last_successful_refresh_at'],
        ),
        provider: provider,
      );
    } on AlertProtocolException {
      rethrow;
    } catch (_) {
      throw const AlertProtocolException();
    }
  }

  final List<AlertDto> items;
  final AlertDataStatus dataStatus;
  final DateTime lastSuccessfulRefreshAt;
  final String provider;

  AlertSnapshot toDomain() => AlertSnapshot(
    items: items.map((item) => item.toDomain()).toList(),
    dataStatus: dataStatus,
    lastSuccessfulRefreshAt: lastSuccessfulRefreshAt,
  );
}

const _envelopeKeys = {
  'items',
  'data_status',
  'last_successful_refresh_at',
  'provider',
};

const _itemKeys = {
  'id',
  'provider',
  'provider_event_id',
  'kind',
  'title',
  'place',
  'magnitude',
  'depth_km',
  'latitude',
  'longitude',
  'event_at',
  'provider_updated_at',
  'retrieved_at',
  'review_status',
  'source_url',
  'version',
};

void _requireExactKeys(Map<String, Object?> json, Set<String> keys) {
  if (json.length != keys.length || !json.keys.toSet().containsAll(keys)) {
    throw const AlertProtocolException();
  }
}

String _string(Object? value) {
  if (value is! String) throw const AlertProtocolException();
  return value;
}

String _nonEmptyString(Object? value) {
  final result = _string(value);
  if (result.trim().isEmpty) throw const AlertProtocolException();
  return result;
}

String? _nullableNonEmptyString(Object? value) {
  if (value == null) return null;
  return _nonEmptyString(value);
}

double _finiteDouble(Object? value) {
  if (value is! num) throw const AlertProtocolException();
  final result = value.toDouble();
  if (!result.isFinite) throw const AlertProtocolException();
  return result;
}

DateTime _utcTimestamp(Object? value) {
  if (value is! String || !value.endsWith('Z')) {
    throw const AlertProtocolException();
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) throw const AlertProtocolException();
  return parsed;
}

String _trustedSourceUrl(Object? value) {
  final source = _nonEmptyString(value);
  final uri = Uri.tryParse(source);
  if (uri == null ||
      uri.scheme != 'https' ||
      (uri.host != 'earthquake.usgs.gov' &&
          !uri.host.endsWith('.earthquake.usgs.gov'))) {
    throw const AlertProtocolException();
  }
  return source;
}
