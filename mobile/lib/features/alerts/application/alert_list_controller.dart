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
  StreamSubscription<AlertSnapshot?>? _cacheSubscription;
  Future<void>? _activeRefresh;
  AlertSnapshot? _authoritativeSnapshot;
  bool _hasCache = false;
  bool _hasObservedInitialCache = false;
  bool _disposed = false;

  @override
  AlertListState build() {
    _repository = ref.watch(alertRepositoryProvider);
    ref.onDispose(() {
      _disposed = true;
      unawaited(_cacheSubscription?.cancel());
    });
    _cacheSubscription = _repository.watchCachedSnapshot().listen(
      _onCache,
      onError: _onCacheError,
    );
    final initialRefresh = Completer<void>();
    _activeRefresh = initialRefresh.future;
    _initialRefresh = initialRefresh;
    return AlertListState(
      phase: AlertListPhase.loading,
      items: const [],
      presentationStatus: null,
      lastSuccessfulRefreshAt: null,
      isRefreshing: true,
      errorKind: null,
    );
  }

  Completer<void>? _initialRefresh;

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

  void _startInitialRefresh() {
    final completion = _initialRefresh!;
    final pending = completion.future;
    _initialRefresh = null;
    _completeRefresh(Future.sync(_repository.refresh)).whenComplete(() {
      if (!completion.isCompleted) completion.complete();
      if (identical(_activeRefresh, pending)) _activeRefresh = null;
    });
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
    final isFirstCacheEvent = !_hasObservedInitialCache;
    _hasObservedInitialCache = true;
    if (snapshot != null) {
      _hasCache = true;
      final preserveOutcome =
          state.errorKind != null ||
          (!state.isRefreshing &&
              _snapshotsEqual(snapshot, _authoritativeSnapshot));
      state = AlertListState(
        phase: _phaseFor(snapshot.items),
        items: snapshot.items,
        presentationStatus: preserveOutcome
            ? state.presentationStatus
            : snapshot.dataStatus == AlertDataStatus.stale
            ? AlertPresentationStatus.stale
            : AlertPresentationStatus.cached,
        lastSuccessfulRefreshAt: snapshot.lastSuccessfulRefreshAt,
        isRefreshing: state.isRefreshing,
        errorKind: state.errorKind,
      );
    }
    if (isFirstCacheEvent) {
      scheduleMicrotask(() {
        if (!_disposed) _startInitialRefresh();
      });
    }
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
