import 'package:flutter/services.dart';

import '../domain/sos_ble.dart';

final class MethodChannelSosBlePlatform implements SosBlePlatformService {
  MethodChannelSosBlePlatform({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methodChannel = methodChannel ?? const MethodChannel(channelName),
       _eventChannel = eventChannel ?? const EventChannel(eventChannelName);

  static const channelName = 'org.safemyanmar.mobile/sos_ble';
  static const eventChannelName = 'org.safemyanmar.mobile/sos_ble_events';

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  @override
  Stream<Uint8List> get payloadStream => _eventChannel
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) {
        final data = (event as Map)['data'];
        if (data is Uint8List) return data;
        if (data is List) return Uint8List.fromList(data.cast<int>());
        throw const FormatException('Invalid SOS BLE platform event.');
      });

  @override
  Future<bool> isSupported() async =>
      await _invoke<bool>('isSupported') ?? false;

  @override
  Future<bool> requestPermissions() async =>
      await _invoke<bool>('requestPermissions') ?? false;

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
  Stream<Uint8List> get payloadStream => const Stream.empty();

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<int?> batteryPercent() async => null;

  @override
  Future<void> startBroadcast(Uint8List payload) async {
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
}
