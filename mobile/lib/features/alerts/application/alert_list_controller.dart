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
  bool _hasCache = false;
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

    final request = _repository.refresh();
    _activeRefresh = _completeRefresh(request);
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
    final request = _repository.refresh();
    final operation = _completeRefresh(request);
    _activeRefresh = operation;
    return operation;
  }

  Future<void> _completeRefresh(Future<AlertSnapshot> request) async {
    try {
      final snapshot = await request;
      if (_disposed) return;
      _hasCache = true;
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
    } finally {
      _activeRefresh = null;
    }
  }

  void _onCache(AlertSnapshot? snapshot) {
    if (_disposed || snapshot == null) return;
    _hasCache = true;
    state = AlertListState(
      phase: _phaseFor(snapshot.items),
      items: snapshot.items,
      presentationStatus: snapshot.dataStatus == AlertDataStatus.stale
          ? AlertPresentationStatus.stale
          : AlertPresentationStatus.cached,
      lastSuccessfulRefreshAt: snapshot.lastSuccessfulRefreshAt,
      isRefreshing: state.isRefreshing,
      errorKind: state.errorKind,
    );
  }

  void _onCacheError(Object _, StackTrace _) {
    _recordFailure(AlertListErrorKind.storage);
  }

  void _recordFailure(AlertListErrorKind kind) {
    if (_disposed) return;
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
}
