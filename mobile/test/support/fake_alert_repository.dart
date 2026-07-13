import 'dart:async';

import 'package:mobile/features/alerts/domain/alert_repository.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';

final class FakeAlertRepository implements CachedAlertRepository {
  FakeAlertRepository() {
    _cache = StreamController<AlertSnapshot?>.broadcast(
      sync: true,
      onCancel: () => cacheCancelled.complete(),
    );
  }

  late final StreamController<AlertSnapshot?> _cache;
  final Completer<void> cacheCancelled = Completer<void>();
  final List<Completer<AlertSnapshot>> _refreshes = [];
  int refreshCalls = 0;

  Completer<AlertSnapshot> queueRefresh() {
    final completer = Completer<AlertSnapshot>();
    _refreshes.add(completer);
    return completer;
  }

  void emit(AlertSnapshot? snapshot) => _cache.add(snapshot);

  @override
  Stream<AlertSnapshot?> watchCachedSnapshot() => _cache.stream;

  @override
  Stream<List<Earthquake>> watchCached() => watchCachedSnapshot().map(
    (snapshot) => snapshot?.items ?? const <Earthquake>[],
  );

  @override
  Future<AlertSnapshot> refresh() {
    refreshCalls++;
    return _refreshes[refreshCalls - 1].future;
  }

  @override
  Future<Earthquake?> getById(String id) async => null;

  Future<void> close() => _cache.close();
}
