import 'dart:async';

import 'package:mobile/features/alerts/data/alert_local_source.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';

final class FakeAlertLocalSource implements AlertLocalSource {
  FakeAlertLocalSource({AlertLocalSnapshot? initialSnapshot})
    : _snapshot = initialSnapshot;

  final StreamController<AlertLocalSnapshot?> _controller =
      StreamController<AlertLocalSnapshot?>.broadcast();
  AlertLocalSnapshot? _snapshot;
  Object? replaceError;
  int replaceCalls = 0;
  String? requestedId;
  AlertSnapshot? replacedSnapshot;
  DateTime? replacedAt;

  @override
  Stream<AlertLocalSnapshot?> watchSnapshot() async* {
    yield _snapshot;
    yield* _controller.stream;
  }

  @override
  Future<AlertLocalSnapshot?> readSnapshot() async => _snapshot;

  @override
  Future<Earthquake?> getById(String id) async {
    requestedId = id;
    for (final item in _snapshot?.items ?? const <Earthquake>[]) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> replaceSnapshot(
    AlertSnapshot snapshot,
    DateTime cachedAt,
  ) async {
    replaceCalls++;
    if (replaceError case final error?) throw error;
    replacedSnapshot = snapshot;
    replacedAt = cachedAt;
    _snapshot = AlertLocalSnapshot(
      items: snapshot.items,
      dataStatus: snapshot.dataStatus,
      lastSuccessfulRefreshAt: snapshot.lastSuccessfulRefreshAt,
      cachedAt: cachedAt,
    );
    _controller.add(_snapshot);
  }

  void emit(AlertLocalSnapshot? snapshot) {
    _snapshot = snapshot;
    _controller.add(snapshot);
  }

  Future<void> close() => _controller.close();
}
