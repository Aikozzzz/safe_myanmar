import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/earthquake.dart';

final class AlertLocalSnapshot {
  AlertLocalSnapshot({
    required List<Earthquake> items,
    required this.dataStatus,
    required this.lastSuccessfulRefreshAt,
    required this.cachedAt,
  }) : items = List.unmodifiable(items);

  final List<Earthquake> items;
  final AlertDataStatus dataStatus;
  final DateTime lastSuccessfulRefreshAt;
  final DateTime cachedAt;
}

abstract interface class AlertLocalSource {
  Stream<AlertLocalSnapshot?> watchSnapshot();
  Future<AlertLocalSnapshot?> readSnapshot();
  Future<Earthquake?> getById(String id);
  Future<void> replaceSnapshot(AlertSnapshot snapshot, DateTime cachedAt);
}

final class DriftAlertLocalSource implements AlertLocalSource {
  DriftAlertLocalSource(this._database);

  static const _provider = 'usgs';

  final AppDatabase _database;

  @override
  Stream<AlertLocalSnapshot?> watchSnapshot() async* {
    final metadataQuery = _database.select(_database.alertSyncMetadata)
      ..where((row) => row.provider.equals(_provider));
    await for (final _ in metadataQuery.watchSingleOrNull()) {
      yield await readSnapshot();
    }
  }

  @override
  Future<AlertLocalSnapshot?> readSnapshot() {
    return _database.transaction(() async {
      final metadataQuery = _database.select(_database.alertSyncMetadata)
        ..where((row) => row.provider.equals(_provider));
      final metadata = await metadataQuery.getSingleOrNull();
      if (metadata == null) return null;

      final itemsQuery = _database.select(_database.cachedEarthquakes)
        ..where((row) => row.provider.equals(_provider))
        ..orderBy([
          (row) => OrderingTerm.desc(row.eventAt),
          (row) => OrderingTerm.asc(row.id),
        ]);
      final rows = await itemsQuery.get();
      return AlertLocalSnapshot(
        items: rows.map(_toDomain).toList(),
        dataStatus: _dataStatus(metadata.dataStatus),
        lastSuccessfulRefreshAt: _utc(metadata.lastSuccessfulRefreshAt),
        cachedAt: _utc(metadata.cachedAt),
      );
    });
  }

  @override
  Future<Earthquake?> getById(String id) async {
    final query = _database.select(_database.cachedEarthquakes)
      ..where((row) => row.id.equals(id) & row.provider.equals(_provider));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> replaceSnapshot(
    AlertSnapshot snapshot,
    DateTime cachedAt,
  ) async {
    if (!cachedAt.isUtc) {
      throw ArgumentError.value(cachedAt, 'cachedAt', 'Must be UTC');
    }

    await _database.transaction(() async {
      for (final item in snapshot.items) {
        final existingQuery = _database.select(_database.cachedEarthquakes)
          ..where(
            (row) => row.id.equals(item.id) & row.provider.equals(_provider),
          );
        final existing = await existingQuery.getSingleOrNull();
        if (existing != null &&
            existing.providerUpdatedAt >=
                item.providerUpdatedAt.microsecondsSinceEpoch) {
          continue;
        }
        await _database
            .into(_database.cachedEarthquakes)
            .insertOnConflictUpdate(_toCompanion(item));
      }

      final ids = snapshot.items.map((item) => item.id).toList();
      final obsolete = _database.delete(_database.cachedEarthquakes)
        ..where((row) {
          final usgs = row.provider.equals(_provider);
          return ids.isEmpty ? usgs : usgs & row.id.isNotIn(ids);
        });
      await obsolete.go();

      await _database
          .into(_database.alertSyncMetadata)
          .insertOnConflictUpdate(
            AlertSyncMetadataCompanion.insert(
              provider: _provider,
              dataStatus: snapshot.dataStatus.name,
              lastSuccessfulRefreshAt:
                  snapshot.lastSuccessfulRefreshAt.microsecondsSinceEpoch,
              cachedAt: cachedAt.microsecondsSinceEpoch,
            ),
          );
    });
  }

  CachedEarthquakesCompanion _toCompanion(Earthquake item) {
    return CachedEarthquakesCompanion.insert(
      id: item.id,
      provider: item.provider,
      providerEventId: item.providerEventId,
      kind: item.kind,
      title: item.title,
      place: item.place,
      magnitude: item.magnitude,
      depthKm: item.depthKm,
      latitude: item.latitude,
      longitude: item.longitude,
      eventAt: item.eventAt.microsecondsSinceEpoch,
      providerUpdatedAt: item.providerUpdatedAt.microsecondsSinceEpoch,
      retrievedAt: item.retrievedAt.microsecondsSinceEpoch,
      reviewStatus: Value(item.reviewStatus),
      sourceUrl: item.sourceUrl,
      version: item.version,
    );
  }

  Earthquake _toDomain(CachedEarthquake row) {
    return Earthquake(
      id: row.id,
      provider: row.provider,
      providerEventId: row.providerEventId,
      kind: row.kind,
      title: row.title,
      place: row.place,
      magnitude: row.magnitude,
      depthKm: row.depthKm,
      latitude: row.latitude,
      longitude: row.longitude,
      eventAt: _utc(row.eventAt),
      providerUpdatedAt: _utc(row.providerUpdatedAt),
      retrievedAt: _utc(row.retrievedAt),
      reviewStatus: row.reviewStatus,
      sourceUrl: row.sourceUrl,
      version: row.version,
    );
  }

  DateTime _utc(int microseconds) =>
      DateTime.fromMicrosecondsSinceEpoch(microseconds, isUtc: true);

  AlertDataStatus _dataStatus(String value) => switch (value) {
    'current' => AlertDataStatus.current,
    'stale' => AlertDataStatus.stale,
    _ => throw StateError('Invalid cached alert status'),
  };
}
