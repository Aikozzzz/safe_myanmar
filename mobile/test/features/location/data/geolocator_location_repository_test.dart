import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/features/location/data/geolocator_location_repository.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/location/domain/location_repository.dart';

void main() {
  late GeolocatorPlatform originalPlatform;
  late FakeGeolocatorPlatform platform;
  late GeolocatorLocationRepository repository;

  setUp(() {
    originalPlatform = GeolocatorPlatform.instance;
    platform = FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = platform;
    repository = GeolocatorLocationRepository();
  });

  tearDown(() {
    GeolocatorPlatform.instance = originalPlatform;
  });

  test(
    'maps precise platform access and bounds the foreground lookup',
    () async {
      platform.accuracy = LocationAccuracyStatus.precise;

      final result = await repository.getCurrentLocation();

      expect(result.precision, LocationPrecision.precise);
      expect(result.latitude, 16.8409);
      expect(result.longitude, 96.1735);
      expect(result.timestamp, _timestamp);
      expect(platform.currentSettings?.accuracy, LocationAccuracy.high);
      expect(platform.currentSettings?.timeLimit, const Duration(seconds: 15));
    },
  );

  test('maps reduced platform access to approximate location', () async {
    platform.accuracy = LocationAccuracyStatus.reduced;

    final result = await repository.getCurrentLocation();

    expect(result.precision, LocationPrecision.approximate);
  });

  test(
    'uses conservative approximate wording when accuracy is unknown',
    () async {
      platform.accuracy = LocationAccuracyStatus.unknown;

      final result = await repository.getLastKnownLocation();

      expect(result?.precision, LocationPrecision.approximate);
    },
  );

  test('maps every platform permission without requesting it', () async {
    for (final entry in {
      LocationPermission.denied: ForegroundLocationPermission.denied,
      LocationPermission.deniedForever:
          ForegroundLocationPermission.permanentlyDenied,
      LocationPermission.whileInUse: ForegroundLocationPermission.granted,
      LocationPermission.always: ForegroundLocationPermission.granted,
      LocationPermission.unableToDetermine:
          ForegroundLocationPermission.unableToDetermine,
    }.entries) {
      platform.permission = entry.key;
      expect(await repository.checkPermission(), entry.value);
    }
    expect(platform.permissionRequests, 0);
  });
}

final _timestamp = DateTime.utc(2026, 7, 23, 1, 2, 3);

final _position = Position(
  latitude: 16.8409,
  longitude: 96.1735,
  timestamp: _timestamp,
  accuracy: 12,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

final class FakeGeolocatorPlatform extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.whileInUse;
  LocationAccuracyStatus accuracy = LocationAccuracyStatus.precise;
  LocationSettings? currentSettings;
  int permissionRequests = 0;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    currentSettings = locationSettings;
    return _position;
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => _position;

  @override
  Future<LocationAccuracyStatus> getLocationAccuracy() async => accuracy;

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return permission;
  }
}
