import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/alert_dto.dart';
import '../data/alert_remote_source.dart';
import '../data/alert_repository_impl.dart';
import '../domain/alert_repository.dart';
import '../domain/earthquake.dart';
import 'alert_list_state.dart';
import 'providers.dart';

final class AlertListController extends Notifier<AlertListState> {
  late CachedAlertRepository _repository;
  late Completer<void> _cacheReadiness;
  StreamSubscription<AlertSnapshot?>? _cacheSubscription;
  Future<void>? _activeRefresh;
  AlertSnapshot? _authoritativeSnapshot;
  bool _hasCache = false;
  bool _disposed = false;

  @override
  AlertListState build() {
    _repository = ref.watch(alertRepositoryProvider);
    _cacheReadiness = Completer<void>();
    late Future<void> initialOperation;
    initialOperation = _runInitialRefresh().whenComplete(() {
      if (identical(_activeRefresh, initialOperation)) _activeRefresh = null;
    });
    _activeRefresh = initialOperation;
    ref.onDispose(() {
      _disposed = true;
      _completeCacheReadiness();
      unawaited(_cacheSubscription?.cancel());
    });
    _cacheSubscription = _repository.watchCachedSnapshot().listen(
      _onCache,
      onError: _onCacheError,
    );
    return AlertListState(
      phase: AlertListPhase.loading,
      items: const [],
      presentationStatus: null,
      lastSuccessfulRefreshAt: null,
      isRefreshing: true,
      errorKind: null,
    );
  }

  Future<void> refresh() {
    final active = _activeRefresh;
    if (active != null) return active;

    state = state.copyWith(isRefreshing: true, clearErrorKind: true);
    return _startRefresh();
  }

  Future<void> _startRefresh() {
    late Future<void> operation;
    operation = _completeRefresh(Future.sync(_repository.refresh)).whenComplete(
      () {
        if (identical(_activeRefresh, operation)) _activeRefresh = null;
      },
    );
    _activeRefresh = operation;
    return operation;
  }

  Future<void> _runInitialRefresh() async {
    await _cacheReadiness.future;
    if (_disposed) return;
    await _completeRefresh(Future.sync(_repository.refresh));
  }

  Future<void> _completeRefresh(Future<AlertSnapshot> request) async {
    try {
      final snapshot = await request;
      if (_disposed) return;
      _hasCache = true;
      _authoritativeSnapshot = snapshot;
      state = AlertListState(
        phase: _phaseFor(snapshot.items),
        items: snapshot.items,
        presentationStatus: snapshot.dataStatus == AlertDataStatus.stale
            ? AlertPresentationStatus.stale
            : AlertPresentationStatus.live,
        lastSuccessfulRefreshAt: snapshot.lastSuccessfulRefreshAt,
        isRefreshing: false,
        errorKind: null,
      );
    } on AlertRemoteUnavailable {
      _recordFailure(AlertListErrorKind.remoteUnavailable);
    } on AlertRemoteException {
      _recordFailure(AlertListErrorKind.remoteUnavailable);
    } on AlertProtocolException {
      _recordFailure(AlertListErrorKind.invalidData);
    } on AlertStorageException {
      _recordFailure(AlertListErrorKind.storage);
    } catch (_) {
      _recordFailure(AlertListErrorKind.storage);
    }
  }

  void _onCache(AlertSnapshot? snapshot) {
    if (_disposed) return;
    if (snapshot != null) {
      _hasCache = true;
      final preserveAuthoritative =
          !state.isRefreshing &&
          _snapshotsEqual(snapshot, _authoritativeSnapshot);
      state = AlertListState(
        phase: _phaseFor(snapshot.items),
        items: snapshot.items,
        presentationStatus: state.errorKind != null
            ? AlertPresentationStatus.stale
            : preserveAuthoritative
            ? state.presentationStatus
            : snapshot.dataStatus == AlertDataStatus.stale
            ? AlertPresentationStatus.stale
            : AlertPresentationStatus.cached,
        lastSuccessfulRefreshAt: snapshot.lastSuccessfulRefreshAt,
        isRefreshing: state.isRefreshing,
        errorKind: state.errorKind,
      );
    }
    _completeCacheReadiness();
  }

  void _onCacheError(Object _, StackTrace _) {
    if (_activeRefresh != null) {
      state = state.copyWith(
        presentationStatus: _hasCache
            ? AlertPresentationStatus.stale
            : state.presentationStatus,
        isRefreshing: true,
        errorKind: AlertListErrorKind.storage,
      );
      _completeCacheReadiness();
      return;
    }
    _recordFailure(AlertListErrorKind.storage);
  }

  void _recordFailure(AlertListErrorKind kind) {
    if (_disposed) return;
    _authoritativeSnapshot = null;
    if (_hasCache) {
      state = state.copyWith(
        phase: _phaseFor(state.items),
        presentationStatus: AlertPresentationStatus.stale,
        isRefreshing: false,
        errorKind: kind,
      );
      return;
    }
    state = AlertListState(
      phase: AlertListPhase.unavailable,
      items: const [],
      presentationStatus: null,
      lastSuccessfulRefreshAt: null,
      isRefreshing: false,
      errorKind: kind,
    );
  }

  AlertListPhase _phaseFor(List<Earthquake> items) =>
      items.isEmpty ? AlertListPhase.empty : AlertListPhase.data;

  void _completeCacheReadiness() {
    if (!_cacheReadiness.isCompleted) _cacheReadiness.complete();
  }

  bool _snapshotsEqual(AlertSnapshot left, AlertSnapshot? right) {
    if (right == null ||
        left.dataStatus != right.dataStatus ||
        left.lastSuccessfulRefreshAt != right.lastSuccessfulRefreshAt ||
        left.items.length != right.items.length) {
      return false;
    }
    for (var index = 0; index < left.items.length; index++) {
      if (left.items[index] != right.items[index]) return false;
    }
    return true;
  }
}
