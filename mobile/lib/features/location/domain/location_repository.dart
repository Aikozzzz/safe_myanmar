import 'foreground_location.dart';

enum ForegroundLocationPermission {
  denied,
  permanentlyDenied,
  granted,
  unableToDetermine,
}

abstract interface class LocationRepository {
  Future<bool> isLocationServiceEnabled();

  Future<ForegroundLocationPermission> checkPermission();

  Future<ForegroundLocationPermission> requestPermission();

  Future<ForegroundLocation> getCurrentLocation();

  Future<ForegroundLocation?> getLastKnownLocation();

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}
