import '../domain/alert_repository.dart';
import '../domain/earthquake.dart';
import 'alert_local_source.dart';
import 'alert_remote_source.dart';

final class AlertStorageException implements Exception {
  const AlertStorageException();

  @override
  String toString() => 'AlertStorageException: Alert cache unavailable';
}

final class AlertRepositoryImpl implements CachedAlertRepository {
  factory AlertRepositoryImpl({
    required AlertLocalSource localSource,
    required AlertRemoteSource remoteSource,
    DateTime Function()? now,
  }) => AlertRepositoryImpl._(localSource, remoteSource, now ?? DateTime.now);

  AlertRepositoryImpl._(this._localSource, this._remoteSource, this._now);

  final AlertLocalSource _localSource;
  final AlertRemoteSource _remoteSource;
  final DateTime Function() _now;

  @override
  Stream<List<Earthquake>> watchCached() => watchCachedSnapshot().map(
    (snapshot) =>
        List<Earthquake>.unmodifiable(snapshot?.items ?? const <Earthquake>[]),
  );

  @override
  Stream<AlertSnapshot?> watchCachedSnapshot() async* {
    try {
      await for (final snapshot in _localSource.watchSnapshot()) {
        yield _toDomainSnapshot(snapshot);
      }
    } on AlertStorageException {
      rethrow;
    } catch (_) {
      throw const AlertStorageException();
    }
  }

  @override
  Future<AlertSnapshot> refresh() async {
    final snapshot = (await _remoteSource.fetchAlerts()).toDomain();
    try {
      await _localSource.replaceSnapshot(snapshot, _now().toUtc());
    } catch (_) {
      // A fresh remote snapshot remains usable when optional local caching fails.
    }
    return snapshot;
  }

  @override
  Future<Earthquake?> getById(String id) async {
    try {
      return await _localSource.getById(id);
    } on AlertStorageException {
      rethrow;
    } catch (_) {
      throw const AlertStorageException();
    }
  }

  AlertSnapshot? _toDomainSnapshot(AlertLocalSnapshot? snapshot) {
    if (snapshot == null) return null;
    return AlertSnapshot(
      items: snapshot.items,
      dataStatus: snapshot.dataStatus,
      lastSuccessfulRefreshAt: snapshot.lastSuccessfulRefreshAt,
    );
  }
}
