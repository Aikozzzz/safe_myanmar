enum AlertDataStatus { current, stale }

final class Earthquake {
  Earthquake({
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
  }) : assert(id.startsWith('usgs:')),
       assert(provider == 'usgs'),
       assert(kind == 'earthquake_information'),
       assert(sourceUrl.startsWith('https://')),
       assert(magnitude.isFinite),
       assert(depthKm.isFinite),
       assert(latitude.isFinite && latitude >= -90 && latitude <= 90),
       assert(longitude.isFinite && longitude >= -180 && longitude <= 180),
       assert(eventAt.isUtc),
       assert(providerUpdatedAt.isUtc),
       assert(retrievedAt.isUtc),
       assert(version > 0);

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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Earthquake &&
            id == other.id &&
            provider == other.provider &&
            providerEventId == other.providerEventId &&
            kind == other.kind &&
            title == other.title &&
            place == other.place &&
            magnitude == other.magnitude &&
            depthKm == other.depthKm &&
            latitude == other.latitude &&
            longitude == other.longitude &&
            eventAt == other.eventAt &&
            providerUpdatedAt == other.providerUpdatedAt &&
            retrievedAt == other.retrievedAt &&
            reviewStatus == other.reviewStatus &&
            sourceUrl == other.sourceUrl &&
            version == other.version;
  }

  @override
  int get hashCode => Object.hash(
    id,
    provider,
    providerEventId,
    kind,
    title,
    place,
    magnitude,
    depthKm,
    latitude,
    longitude,
    eventAt,
    providerUpdatedAt,
    retrievedAt,
    reviewStatus,
    sourceUrl,
    version,
  );
}

final class AlertSnapshot {
  AlertSnapshot({
    required List<Earthquake> items,
    required this.dataStatus,
    required this.lastSuccessfulRefreshAt,
  }) : assert(lastSuccessfulRefreshAt.isUtc),
       items = List.unmodifiable(items);

  final List<Earthquake> items;
  final AlertDataStatus dataStatus;
  final DateTime lastSuccessfulRefreshAt;
}
