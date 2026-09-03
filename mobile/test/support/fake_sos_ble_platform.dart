import 'dart:async';
import 'dart:typed_data';

import 'package:mobile/features/sos/domain/sos_ble.dart';

final class FakeSosBlePlatform implements SosBlePlatformService {
  final events = StreamController<SosBleAdvertisement>.broadcast();
  var permissionsRequested = 0;
  var scanStarted = 0;
  var scanStopped = 0;
  var backgroundScanEnabled = false;
  var permissionState = const SosBlePermissionState(
    supported: true,
    bluetoothEnabled: true,
    scanGranted: true,
    advertiseGranted: true,
    notificationGranted: true,
  );

  @override
  Stream<SosBleAdvertisement> get payloadStream => events.stream;

  @override
  Stream<String> get notificationEventStream => const Stream.empty();

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> requestPermissions({
    required bool receive,
    required bool broadcast,
    required bool background,
  }) async {
    permissionsRequested++;
    return true;
  }

  @override
  Future<SosBlePermissionState> getPermissionState() async => permissionState;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<int?> batteryPercent() async => 80;

  @override
  Future<void> startBroadcast(
    List<Uint8List> payloads, {
    String languageCode = 'en',
  }) async {}

  @override
  Future<void> startRelayBroadcast(
    List<Uint8List> payloads, {
    String languageCode = 'en',
  }) async {}

  @override
  Future<void> stopBroadcast() async {}

  @override
  Future<void> startScan() async => scanStarted++;

  @override
  Future<void> stopScan() async => scanStopped++;

  @override
  Future<bool> isBackgroundScanEnabled() async => backgroundScanEnabled;

  @override
  Future<void> startBackgroundScan({String languageCode = 'en'}) async {
    backgroundScanEnabled = true;
  }

  @override
  Future<void> stopBackgroundScan() async {
    backgroundScanEnabled = false;
  }

  @override
  Future<List<SosBleAdvertisement>> readBackgroundAdvertisements() async =>
      const [];

  @override
  Future<String?> getPendingNotificationEventId() async => null;

  Future<void> dispose() => events.close();
}
