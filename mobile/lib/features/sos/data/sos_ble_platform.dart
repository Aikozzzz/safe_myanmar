import 'package:flutter/services.dart';

import '../domain/sos_ble.dart';

final class MethodChannelSosBlePlatform implements SosBlePlatformService {
  MethodChannelSosBlePlatform({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
    EventChannel? notificationEventChannel,
  }) : _methodChannel = methodChannel ?? const MethodChannel(channelName),
       _eventChannel = eventChannel ?? const EventChannel(eventChannelName),
       _notificationEventChannel =
           notificationEventChannel ??
           const EventChannel(notificationEventChannelName);

  static const channelName = 'org.safemyanmar.mobile/sos_ble';
  static const eventChannelName = 'org.safemyanmar.mobile/sos_ble_events';
  static const notificationEventChannelName =
      'org.safemyanmar.mobile/sos_ble_notification_events';

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  final EventChannel _notificationEventChannel;

  @override
  Stream<SosBleAdvertisement> get payloadStream => _eventChannel
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) {
        final data = (event as Map)['data'];
        final payload = data is Uint8List
            ? data
            : data is List
            ? Uint8List.fromList(data.cast<int>())
            : null;
        if (payload == null) {
          throw const FormatException('Invalid SOS BLE platform event.');
        }
        final rssi = (event['rssi'] as num?)?.toInt();
        return SosBleAdvertisement(
          payload,
          rssi: rssi,
          background: event['background'] == true,
        );
      });

  @override
  Stream<String> get notificationEventStream => _notificationEventChannel
      .receiveBroadcastStream()
      .where((event) => event is String)
      .cast<String>();

  @override
  Future<bool> isSupported() async =>
      await _invoke<bool>('isSupported') ?? false;

  @override
  Future<bool> requestPermissions({
    required bool receive,
    required bool broadcast,
    required bool background,
  }) async =>
      await _invoke<bool>('requestPermissions', {
        'receive': receive,
        'broadcast': broadcast,
        'background': background,
      }) ??
      false;

  @override
  Future<SosBlePermissionState> getPermissionState() async {
    final value = await _invoke<Object?>('getPermissionState');
    if (value is! Map) {
      return const SosBlePermissionState(
        supported: false,
        bluetoothEnabled: false,
        scanGranted: false,
        advertiseGranted: false,
        notificationGranted: false,
      );
    }
    bool readBool(String key) => value[key] == true;
    return SosBlePermissionState(
      supported: readBool('supported'),
      bluetoothEnabled: readBool('bluetooth_enabled'),
      scanGranted: readBool('scan_granted'),
      advertiseGranted: readBool('advertise_granted'),
      notificationGranted: readBool('notification_granted'),
    );
  }

  @override
  Future<bool> openAppSettings() async =>
      await _invoke<bool>('openAppSettings') ?? false;

  @override
  Future<int?> batteryPercent() async {
    final value = await _invoke<Object?>('batteryPercent');
    return value is int && value >= 0 && value <= 100 ? value : null;
  }

  @override
  Future<void> startBroadcast(Uint8List payload) async {
    await _invoke<void>('startBroadcast', {'payload': payload});
  }

  @override
  Future<void> startRelayBroadcast(Uint8List payload) async {
    await _invoke<void>('startBroadcast', {
      'payload': payload,
      'duration_seconds': sosBleRelayDurationSeconds,
    });
  }

  @override
  Future<void> stopBroadcast() async {
    await _invoke<void>('stopBroadcast');
  }

  @override
  Future<void> startScan() async {
    await _invoke<void>('startScan');
  }

  @override
  Future<void> stopScan() async {
    await _invoke<void>('stopScan');
  }

  @override
  Future<bool> isBackgroundScanEnabled() async =>
      await _invoke<bool>('isBackgroundScanEnabled') ?? false;

  @override
  Future<void> startBackgroundScan() async {
    await _invoke<void>('startBackgroundScan');
  }

  @override
  Future<void> stopBackgroundScan() async {
    await _invoke<void>('stopBackgroundScan');
  }

  @override
  Future<List<SosBleAdvertisement>> readBackgroundAdvertisements() async {
    final events = await _invoke<Object?>('readBackgroundAdvertisements');
    if (events is! List) return const [];
    return [
      for (final event in events)
        if (event is Map) _advertisementFromMap(event),
    ];
  }

  @override
  Future<String?> getPendingNotificationEventId() async =>
      await _invoke<String?>('getPendingNotificationEventId');

  Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _methodChannel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    }
  }
}

final class UnsupportedSosBlePlatform implements SosBlePlatformService {
  const UnsupportedSosBlePlatform();

  @override
  Stream<SosBleAdvertisement> get payloadStream => const Stream.empty();

  @override
  Stream<String> get notificationEventStream => const Stream.empty();

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<bool> requestPermissions({
    required bool receive,
    required bool broadcast,
    required bool background,
  }) async => false;

  @override
  Future<SosBlePermissionState> getPermissionState() async =>
      const SosBlePermissionState(
        supported: false,
        bluetoothEnabled: false,
        scanGranted: false,
        advertiseGranted: false,
        notificationGranted: false,
      );

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<int?> batteryPercent() async => null;

  @override
  Future<void> startBroadcast(Uint8List payload) async {
    throw UnsupportedError('Bluetooth SOS is unavailable.');
  }

  @override
  Future<void> startRelayBroadcast(Uint8List payload) async {
    throw UnsupportedError('Bluetooth SOS is unavailable.');
  }

  @override
  Future<void> stopBroadcast() async {}

  @override
  Future<void> startScan() async {
    throw UnsupportedError('Bluetooth SOS is unavailable.');
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<bool> isBackgroundScanEnabled() async => false;

  @override
  Future<void> startBackgroundScan() async {
    throw UnsupportedError('Background Bluetooth SOS is unavailable.');
  }

  @override
  Future<void> stopBackgroundScan() async {}

  @override
  Future<List<SosBleAdvertisement>> readBackgroundAdvertisements() async =>
      const [];

  @override
  Future<String?> getPendingNotificationEventId() async => null;
}

SosBleAdvertisement _advertisementFromMap(Map<Object?, Object?> event) {
  final data = event['data'];
  final payload = data is Uint8List
      ? data
      : data is List
      ? Uint8List.fromList(data.cast<int>())
      : null;
  if (payload == null) {
    throw const FormatException('Invalid SOS BLE platform event.');
  }
  return SosBleAdvertisement(
    payload,
    rssi: (event['rssi'] as num?)?.toInt(),
    background: event['background'] == true,
  );
}
