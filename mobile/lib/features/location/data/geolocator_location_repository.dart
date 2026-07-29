import 'package:geolocator/geolocator.dart';

import '../domain/foreground_location.dart';
import '../domain/location_repository.dart';

final class GeolocatorLocationRepository implements LocationRepository {
  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 15),
  );

  @override
  Future<ForegroundLocationPermission> checkPermission() async {
    return _mapPermission(await Geolocator.checkPermission());
  }

  @override
  Future<ForegroundLocation> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: _settings,
    );
    return _mapPosition(position);
  }

  @override
  Future<ForegroundLocation?> getLastKnownLocation() async {
    final position = await Geolocator.getLastKnownPosition();
    return position == null ? null : _mapPosition(position);
  }

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<ForegroundLocationPermission> requestPermission() async {
    return _mapPermission(await Geolocator.requestPermission());
  }

  Future<ForegroundLocation> _mapPosition(Position position) async {
    LocationPrecision precision;
    try {
      final accuracy = await Geolocator.getLocationAccuracy();
      precision = accuracy == LocationAccuracyStatus.precise
          ? LocationPrecision.precise
          : LocationPrecision.approximate;
    } catch (_) {
      // Do not claim precise access when the platform cannot report it.
      precision = LocationPrecision.approximate;
    }
    return ForegroundLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      precision: precision,
    );
  }

  ForegroundLocationPermission _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.denied => ForegroundLocationPermission.denied,
      LocationPermission.deniedForever =>
        ForegroundLocationPermission.permanentlyDenied,
      LocationPermission.whileInUse ||
      LocationPermission.always => ForegroundLocationPermission.granted,
      LocationPermission.unableToDetermine =>
        ForegroundLocationPermission.unableToDetermine,
    };
  }
}
