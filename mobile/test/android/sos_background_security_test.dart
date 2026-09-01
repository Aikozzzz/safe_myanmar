import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String manifest;
  late String bridge;
  late String store;
  late String service;
  late String broadcastService;

  setUpAll(() {
    manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    bridge = File(
      'android/app/src/main/kotlin/org/safemyanmar/mobile/sos/SosBleBridge.kt',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    store = File(
      'android/app/src/main/kotlin/org/safemyanmar/mobile/sos/SosBleBackgroundEventStore.kt',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    service = File(
      'android/app/src/main/kotlin/org/safemyanmar/mobile/sos/SosBleBackgroundScanService.kt',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    broadcastService = File(
      'android/app/src/main/kotlin/org/safemyanmar/mobile/sos/SosBleBroadcastService.kt',
    ).readAsStringSync().replaceAll('\r\n', '\n');
  });

  test('declares a non-exported connected-device background receiver', () {
    expect(
      manifest,
      contains('android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE'),
    );
    expect(
      manifest,
      contains(
        '<service\n'
        '            android:name=".sos.SosBleBackgroundScanService"\n'
        '            android:exported="false"\n'
        '            android:foregroundServiceType="connectedDevice" />',
      ),
    );
  });

  test('does not request background location for BLE SOS receiving', () {
    expect(
      manifest,
      isNot(contains('android.permission.ACCESS_BACKGROUND_LOCATION')),
    );
  });

  test('registers local event IDs before native advertising starts', () {
    final register = bridge.indexOf('rememberOriginatedEvent(');
    final start = bridge.indexOf('SosBleBroadcastService.start(');

    expect(register, greaterThanOrEqualTo(0));
    expect(start, greaterThan(register));
  });

  test('filters local events before foreground and background delivery', () {
    final foregroundFilter = bridge.indexOf(
      'backgroundEventStore.isOriginatedEvent(eventId)',
    );
    final foregroundDelivery = bridge.lastIndexOf('eventSink?.success(');
    final backgroundFilter = store.indexOf(
      'isOriginatedEvent(frame.eventId, nowMillis)',
    );
    final backgroundWrite = store.indexOf('write(events)');
    final backgroundAdd = service.indexOf('store.add(payload');
    final backgroundNotification = service.indexOf('notifyIncoming(event)');

    expect(foregroundFilter, greaterThanOrEqualTo(0));
    expect(foregroundDelivery, greaterThan(foregroundFilter));
    expect(backgroundFilter, greaterThanOrEqualTo(0));
    expect(backgroundWrite, greaterThan(backgroundFilter));
    expect(backgroundAdd, greaterThanOrEqualTo(0));
    expect(backgroundNotification, greaterThan(backgroundAdd));
  });

  test('passes the selected language to native SOS notifications', () {
    expect(bridge, contains('languageCode(call.argument<String>("language"))'));
    expect(bridge, contains('setNotificationLanguage(language)'));
    expect(store, contains('notificationLanguage()'));
    expect(service, contains('EXTRA_LANGUAGE'));
    expect(service, contains('localizedResources(notificationLanguageCode)'));
    expect(broadcastService, contains('EXTRA_LANGUAGE'));
    expect(broadcastService, contains('localizedResources(languageCode)'));
  });
}
