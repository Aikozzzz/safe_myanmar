import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/location_repository.dart';
import 'foreground_location_state.dart';
import 'providers.dart';

final class ForegroundLocationController
    extends Notifier<ForegroundLocationState> {
  late LocationRepository _repository;
  Future<void>? _activeRequest;

  @override
  ForegroundLocationState build() {
    _repository = ref.watch(locationRepositoryProvider);
    return const ForegroundLocationState.notRequested();
  }

  Future<void> requestLocation() {
    final activeRequest = _activeRequest;
    if (activeRequest != null) return activeRequest;

    late Future<void> request;
    request = _requestLocation().whenComplete(() {
      if (identical(_activeRequest, request)) _activeRequest = null;
    });
    _activeRequest = request;
    return request;
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

  Future<void> _requestLocation() async {
    state = const ForegroundLocationState.requesting();
    try {
      if (!await _repository.isLocationServiceEnabled()) {
        state = const ForegroundLocationState.serviceDisabled();
        return;
      }

      var permission = await _repository.checkPermission();
      if (permission == ForegroundLocationPermission.denied) {
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
          break;
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
