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
  final Completer<void> refreshStarted = Completer<void>();
  final List<FakeAlertRefresh> _refreshes = [];
  int refreshCalls = 0;

  FakeAlertRefresh queueRefresh({AlertSnapshot? synchronousCacheSnapshot}) {
    final refresh = FakeAlertRefresh(
      synchronousCacheSnapshot: synchronousCacheSnapshot,
    );
    _refreshes.add(refresh);
    return refresh;
  }

  void queueSynchronousError(Object error) =>
      _refreshes.add(FakeAlertRefresh(synchronousError: error));

  void emit(AlertSnapshot? snapshot) => _cache.add(snapshot);

  void emitError(Object error) => _cache.addError(error, StackTrace.current);

  @override
  Stream<AlertSnapshot?> watchCachedSnapshot() => _cache.stream;

  @override
  Stream<List<Earthquake>> watchCached() => watchCachedSnapshot().map(
    (snapshot) => snapshot?.items ?? const <Earthquake>[],
  );

  @override
  Future<AlertSnapshot> refresh() {
    refreshCalls++;
    if (!refreshStarted.isCompleted) refreshStarted.complete();
    final refresh = _refreshes[refreshCalls - 1];
    if (refresh.synchronousCacheSnapshot case final snapshot?) emit(snapshot);
    if (refresh.synchronousError case final error?) throw error;
    return refresh.future;
  }

  @override
  Future<Earthquake?> getById(String id) async => null;

  Future<void> close() => _cache.close();
}

final class FakeAlertRefresh {
  FakeAlertRefresh({this.synchronousCacheSnapshot, this.synchronousError}) {
    _completer.future.then<void>((_) {}, onError: (_, _) {});
  }

  final AlertSnapshot? synchronousCacheSnapshot;
  final Object? synchronousError;
  final Completer<AlertSnapshot> _completer = Completer<AlertSnapshot>();

  Future<AlertSnapshot> get future => _completer.future;

  void complete(AlertSnapshot snapshot) => _completer.complete(snapshot);

  void completeError(Object error) =>
      _completer.completeError(error, StackTrace.current);
}
