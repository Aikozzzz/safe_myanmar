import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/location_permission_prompt_store.dart';
import '../domain/location_repository.dart';
import 'foreground_location_state.dart';
import 'providers.dart';

final class ForegroundLocationController
    extends Notifier<ForegroundLocationState> {
  late LocationRepository _repository;
  late LocationPermissionPromptStore _promptStore;
  Future<void>? _activeRequest;

  @override
  ForegroundLocationState build() {
    _repository = ref.watch(locationRepositoryProvider);
    _promptStore = ref.watch(locationPermissionPromptStoreProvider);
    return const ForegroundLocationState.notRequested();
  }

  Future<void> requestLocation({bool confirmed = false}) {
    final activeRequest = _activeRequest;
    if (activeRequest != null) return activeRequest;

    late Future<void> request;
    request = _requestLocation(allowSystemPrompt: confirmed).whenComplete(() {
      if (identical(_activeRequest, request)) _activeRequest = null;
    });
    _activeRequest = request;
    return request;
  }

  Future<void> restoreGrantedLocation() async {
    final inFlight = _activeRequest;
    if (inFlight != null) return inFlight;
    if (!_canRestore(state.phase)) return;
    if (!await _hasOptedIn()) return;
    return _activeRequest ?? requestLocation();
  }

  void dismissPermissionExplanation() {
    if (state.phase == ForegroundLocationPhase.permissionExplanationRequired) {
      state = const ForegroundLocationState.denied();
    }
  }

  Future<bool> openAppSettings() async {
    try {
      final opened = await _repository.openAppSettings();
      if (opened) state = const ForegroundLocationState.notRequested();
      return opened;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      final opened = await _repository.openLocationSettings();
      if (opened) state = const ForegroundLocationState.notRequested();
      return opened;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshPermission() async {
    try {
      final permission = await _repository.checkPermission();
      switch (permission) {
        case ForegroundLocationPermission.granted:
          if (state.location != null) return;
          if (await _hasOptedIn()) {
            await restoreGrantedLocation();
            return;
          }
          if (state.phase == ForegroundLocationPhase.denied ||
              state.phase == ForegroundLocationPhase.permanentlyDenied) {
            state = const ForegroundLocationState.notRequested();
          }
        case ForegroundLocationPermission.denied:
          if (state.location != null ||
              state.phase == ForegroundLocationPhase.preciseAvailable ||
              state.phase == ForegroundLocationPhase.approximateAvailable ||
              state.phase ==
                  ForegroundLocationPhase.liveUnavailableWithLastKnown) {
            state = const ForegroundLocationState.denied();
          }
        case ForegroundLocationPermission.permanentlyDenied:
          if (state.location != null ||
              state.phase != ForegroundLocationPhase.notRequested) {
            state = const ForegroundLocationState.permanentlyDenied();
          }
        case ForegroundLocationPermission.unableToDetermine:
          if (state.location != null) {
            state = const ForegroundLocationState.recoverableError();
          }
      }
    } on Object {
      // Permission refresh is best effort and never shows a system prompt.
    }
  }

  Future<void> _requestLocation({required bool allowSystemPrompt}) async {
    state = const ForegroundLocationState.requesting();
    try {
      if (!await _repository.isLocationServiceEnabled()) {
        await _useLastKnownLocation();
        return;
      }

      var permission = await _repository.checkPermission();
      if (permission == ForegroundLocationPermission.denied) {
        if (!allowSystemPrompt) {
          final shown = await _hasShownExplanation();
          if (!shown) {
            await _markExplanationShown();
            state =
                const ForegroundLocationState.permissionExplanationRequired();
          } else {
            state = const ForegroundLocationState.denied();
          }
          return;
        }
        permission = await _repository.requestPermission();
      }
      switch (permission) {
        case ForegroundLocationPermission.denied:
          state = const ForegroundLocationState.denied();
          return;
        case ForegroundLocationPermission.permanentlyDenied:
          state = const ForegroundLocationState.permanentlyDenied();
          return;
        case ForegroundLocationPermission.unableToDetermine:
          state = const ForegroundLocationState.recoverableError();
          return;
        case ForegroundLocationPermission.granted:
          await _markOptedIn();
      }

      try {
        final location = await _repository.getCurrentLocation();
        state = ForegroundLocationState.available(location);
      } catch (_) {
        await _useLastKnownLocation();
      }
    } catch (_) {
      state = const ForegroundLocationState.recoverableError();
    }
  }

  bool _canRestore(ForegroundLocationPhase phase) {
    return phase == ForegroundLocationPhase.notRequested ||
        phase == ForegroundLocationPhase.denied ||
        phase == ForegroundLocationPhase.permanentlyDenied;
  }

  Future<bool> _hasShownExplanation() async {
    try {
      return await _promptStore.hasShownExplanation();
    } on Object {
      return false;
    }
  }

  Future<void> _markExplanationShown() async {
    try {
      await _promptStore.markExplanationShown();
    } on Object {
      // The in-memory state still prevents a repeated prompt this session.
    }
  }

  Future<bool> _hasOptedIn() async {
    try {
      return await _promptStore.hasOptedIn();
    } on Object {
      return false;
    }
  }

  Future<void> _markOptedIn() async {
    try {
      await _promptStore.markOptedIn();
    } on Object {
      // Restore on a later launch is best effort.
    }
  }

  Future<void> _useLastKnownLocation() async {
    try {
      final lastKnown = await _repository.getLastKnownLocation();
      if (lastKnown != null) {
        state = ForegroundLocationState.lastKnown(lastKnown);
        return;
      }
      if (!await _repository.isLocationServiceEnabled()) {
        state = const ForegroundLocationState.serviceDisabled();
        return;
      }
    } catch (_) {
      // The user can explicitly retry after this recoverable failure.
    }
    state = const ForegroundLocationState.recoverableError();
  }
}
