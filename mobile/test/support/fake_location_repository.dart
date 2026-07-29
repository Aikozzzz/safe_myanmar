import 'dart:async';

import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/location/domain/location_repository.dart';

final class FakeLocationRepository implements LocationRepository {
  bool serviceEnabled = true;
  ForegroundLocationPermission checkedPermission =
      ForegroundLocationPermission.granted;
  ForegroundLocationPermission requestedPermission =
      ForegroundLocationPermission.granted;
  ForegroundLocation? currentLocation;
  ForegroundLocation? lastKnownLocation;
  Object? currentLocationError;
  Object? lastKnownLocationError;
  Completer<ForegroundLocation>? currentLocationCompleter;
  bool appSettingsResult = true;
  bool locationSettingsResult = true;

  int serviceChecks = 0;
  int permissionChecks = 0;
  int permissionRequests = 0;
  int currentLocationRequests = 0;
  int lastKnownLocationRequests = 0;
  int appSettingsRequests = 0;
  int locationSettingsRequests = 0;

  @override
  Future<ForegroundLocationPermission> checkPermission() async {
    permissionChecks++;
    return checkedPermission;
  }

  @override
  Future<ForegroundLocation> getCurrentLocation() {
    currentLocationRequests++;
    final completer = currentLocationCompleter;
    if (completer != null) return completer.future;
    final error = currentLocationError;
    if (error != null) return Future.error(error);
    return Future.value(currentLocation!);
  }

  @override
  Future<ForegroundLocation?> getLastKnownLocation() {
    lastKnownLocationRequests++;
    final error = lastKnownLocationError;
    if (error != null) return Future.error(error);
    return Future.value(lastKnownLocation);
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    serviceChecks++;
    return serviceEnabled;
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsRequests++;
    return appSettingsResult;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsRequests++;
    return locationSettingsResult;
  }

  @override
  Future<ForegroundLocationPermission> requestPermission() async {
    permissionRequests++;
    return requestedPermission;
  }
}
