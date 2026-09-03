import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sos/application/providers.dart';
import 'package:mobile/features/sos/data/sos_ble_sender_identity.dart';
import 'package:mobile/features/sos/data/sos_preferences.dart';
import 'package:mobile/features/sos/domain/sos_ble.dart';
import 'package:mobile/features/sos/domain/sos_draft.dart';

import '../../../support/fake_sos_preferences_store.dart';

void main() {
  test(
    'restores saved receiver, relay, sound, and background choices',
    () async {
      final platform = FakeSosBlePlatform();
      final store = FakeSosPreferencesStore()
        ..preferences = const SosPreferences(
          receiveNearbySos: true,
          relayNearbySos: true,
          soundEnabled: true,
          backgroundReceive: true,
        );
      final container = ProviderContainer(
        overrides: [
          sosBlePlatformProvider.overrideWithValue(platform),
          sosPreferencesStoreProvider.overrideWithValue(store),
          sosBleSenderIdentityStoreProvider.overrideWithValue(
            _FakeSosBleSenderIdentitySource(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(platform.events.close);
      container.read(sosBleControllerProvider.notifier);

      await settleSupport(container);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(sosBleControllerProvider);
      expect(state.listening, isTrue);
      expect(state.relayEnabled, isTrue);
      expect(state.soundEnabled, isTrue);
      expect(state.backgroundListening, isTrue);
      expect(platform.scanStarted, greaterThanOrEqualTo(1));
      expect(platform.backgroundScanEnabled, isTrue);
    },
  );

  test('broadcast requests permissions and starts a compact event', () async {
    final platform = FakeSosBlePlatform();
    final container = ProviderContainer(
      overrides: [
        sosBlePlatformProvider.overrideWithValue(platform),
        sosBleSenderIdentityStoreProvider.overrideWithValue(
          _FakeSosBleSenderIdentitySource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(platform.events.close);
    final controller = container.read(sosBleControllerProvider.notifier);
    await settleSupport(container);

    await controller.broadcast(draft);

    expect(platform.permissionsRequested, 1);
    expect(platform.broadcastPayloads, hasLength(1));
    expect(platform.broadcastPayloads.single, hasLength(26));
    expect(
      container.read(sosBleControllerProvider).broadcastStatus,
      SosBleBroadcastStatus.active,
    );
    final activeEvent = container.read(sosBleControllerProvider).activeEvent;
    expect(activeEvent, isNotNull);
    expect(activeEvent!.eventId, 'a55a102030400000');
    expect(activeEvent.batteryPercent, 80);
  });

  test('broadcast includes optional BLE alias and message frames', () async {
    final platform = FakeSosBlePlatform();
    final container = ProviderContainer(
      overrides: [
        sosBlePlatformProvider.overrideWithValue(platform),
        sosBleSenderIdentityStoreProvider.overrideWithValue(
          _FakeSosBleSenderIdentitySource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(platform.events.close);
    final controller = container.read(sosBleControllerProvider.notifier);
    await settleSupport(container);

    await controller.broadcast(metadataDraft);

    expect(platform.broadcastFrameSets, hasLength(1));
    expect(platform.broadcastFrameSets.single.length, greaterThan(1));
    expect(container.read(sosBleControllerProvider).activeEvent?.alias, 'Aung');
    expect(
      container.read(sosBleControllerProvider).activeEvent?.message,
      'Trapped upstairs.',
    );
  });

  test('does not retain the sender as a nearby event after stopping', () async {
    final platform = FakeSosBlePlatform();
    final container = ProviderContainer(
      overrides: [
        sosBlePlatformProvider.overrideWithValue(platform),
        sosBleSenderIdentityStoreProvider.overrideWithValue(
          _FakeSosBleSenderIdentitySource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(platform.events.close);
    final controller = container.read(sosBleControllerProvider.notifier);
    await settleSupport(container);

    await controller.broadcast(draft);
    final selfPayload = platform.broadcastPayloads.single;
    platform.events.add(SosBleAdvertisement(selfPayload));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(sosBleControllerProvider).nearbyEvents, isEmpty);

    await controller.stopBroadcast();

    expect(container.read(sosBleControllerProvider).nearbyEvents, isEmpty);
    expect(
      container.read(sosBleControllerProvider).broadcastStatus,
      SosBleBroadcastStatus.stopped,
    );
  });

  test(
    'does not restore its own broadcast from the background queue',
    () async {
      final platform = FakeSosBlePlatform();
      final container = ProviderContainer(
        overrides: [
          sosBlePlatformProvider.overrideWithValue(platform),
          sosBleSenderIdentityStoreProvider.overrideWithValue(
            _FakeSosBleSenderIdentitySource(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(platform.events.close);
      final controller = container.read(sosBleControllerProvider.notifier);
      await settleSupport(container);

      await controller.broadcast(draft);
      platform.backgroundAdvertisements.add(
        SosBleAdvertisement(
          platform.broadcastPayloads.single,
          background: true,
        ),
      );

      await controller.restoreBackgroundEvents();

      expect(container.read(sosBleControllerProvider).nearbyEvents, isEmpty);
    },
  );

  test('can start a second broadcast after stopping the first', () async {
    final platform = FakeSosBlePlatform();
    final container = ProviderContainer(
      overrides: [
        sosBlePlatformProvider.overrideWithValue(platform),
        sosBleSenderIdentityStoreProvider.overrideWithValue(
          _FakeSosBleSenderIdentitySource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(platform.events.close);
    final controller = container.read(sosBleControllerProvider.notifier);
    await settleSupport(container);

    await controller.broadcast(draft);
    await controller.stopBroadcast();
    await controller.broadcast(draft);

    expect(platform.broadcastPayloads, hasLength(2));
    expect(
      container.read(sosBleControllerProvider).broadcastStatus,
      SosBleBroadcastStatus.active,
    );
  });

  test(
    'foreground receiver deduplicates valid events and ignores malformed data',
    () async {
      final platform = FakeSosBlePlatform();
      final container = ProviderContainer(
        overrides: [
          sosBlePlatformProvider.overrideWithValue(platform),
          sosBleSenderIdentityStoreProvider.overrideWithValue(
            _FakeSosBleSenderIdentitySource(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(platform.events.close);
      final controller = container.read(sosBleControllerProvider.notifier);
      await settleSupport(container);
      await controller.setListening(true);
      final payload = const SosBlePayloadCodec().encode(
        SosBleEvent(
          eventId: '0011223344556677',
          createdAt: DateTime.now().toUtc(),
          locationStatus: SosBleLocationStatus.unavailable,
          batteryPercent: 40,
        ),
      );

      platform.events.add(SosBleAdvertisement(payload));
      platform.events.add(SosBleAdvertisement(payload));
      platform.events.add(SosBleAdvertisement(Uint8List.fromList([1, 2, 3])));
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(sosBleControllerProvider).nearbyEvents,
        hasLength(1),
      );
      expect(platform.scanStarted, 1);
    },
  );

  test('explicit relay opt-in forwards a received event once', () async {
    final platform = FakeSosBlePlatform();
    final container = ProviderContainer(
      overrides: [
        sosBlePlatformProvider.overrideWithValue(platform),
        sosBleSenderIdentityStoreProvider.overrideWithValue(
          _FakeSosBleSenderIdentitySource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(platform.events.close);
    final controller = container.read(sosBleControllerProvider.notifier);
    await settleSupport(container);
    await controller.setRelayEnabled(true);
    final payload = const SosBlePayloadCodec().encode(
      SosBleEvent(
        eventId: '8899aabbccddeeff',
        createdAt: DateTime.now().toUtc(),
        locationStatus: SosBleLocationStatus.unavailable,
        batteryPercent: 40,
      ),
    );

    platform.events.add(SosBleAdvertisement(payload, rssi: -61));
    platform.events.add(SosBleAdvertisement(payload, rssi: -61));
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(platform.relayPayloads, hasLength(1));
    final relayed = const SosBlePayloadCodec().decode(
      platform.relayPayloads.single,
    );
    expect(relayed.eventId, '8899aabbccddeeff');
    expect(relayed.hopCount, 1);
    expect(container.read(sosBleControllerProvider).relayEnabled, isTrue);
    expect(container.read(sosBleControllerProvider).relayCount, 1);
  });

  test(
    'does not relay while this device is broadcasting its own SOS',
    () async {
      final platform = FakeSosBlePlatform();
      final container = ProviderContainer(
        overrides: [
          sosBlePlatformProvider.overrideWithValue(platform),
          sosBleSenderIdentityStoreProvider.overrideWithValue(
            _FakeSosBleSenderIdentitySource(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(platform.events.close);
      final controller = container.read(sosBleControllerProvider.notifier);
      await settleSupport(container);

      await controller.broadcast(draft);
      await controller.setRelayEnabled(true);
      final payload = const SosBlePayloadCodec().encode(
        SosBleEvent(
          eventId: '8899aabbccddeeff',
          createdAt: DateTime.now().toUtc(),
          locationStatus: SosBleLocationStatus.unavailable,
          batteryPercent: 40,
        ),
      );
      platform.events.add(SosBleAdvertisement(payload));
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(platform.relayPayloads, isEmpty);
      expect(container.read(sosBleControllerProvider).relayEnabled, isFalse);
    },
  );

  test('preserves received frame details and RSSI for the UI', () async {
    final platform = FakeSosBlePlatform();
    final container = ProviderContainer(
      overrides: [
        sosBlePlatformProvider.overrideWithValue(platform),
        sosBleSenderIdentityStoreProvider.overrideWithValue(
          _FakeSosBleSenderIdentitySource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(platform.events.close);
    await settleSupport(container);
    final payload = const SosBlePayloadCodec().encode(
      SosBleEvent(
        eventId: '1122334455667788',
        createdAt: DateTime.now().toUtc(),
        locationStatus: SosBleLocationStatus.current,
        batteryPercent: 73,
        latitude: 21.951,
        longitude: 96.081,
      ),
    );

    platform.events.add(SosBleAdvertisement(payload, rssi: -57));
    await Future<void>.delayed(Duration.zero);

    final event = container.read(sosBleControllerProvider).nearbyEvents.single;
    expect(event.eventId, '1122334455667788');
    expect(event.batteryPercent, 73);
    expect(event.rssi, -57);
    expect(event.latitude, 21.951);
    expect(event.longitude, 96.081);
    expect(event.protocolVersion, sosBleProtocolVersion);
    expect(event.ttlMinutes, sosBleTtlMinutes);
  });

  test('reassembles optional metadata received after the base frame', () async {
    final platform = FakeSosBlePlatform();
    final container = ProviderContainer(
      overrides: [
        sosBlePlatformProvider.overrideWithValue(platform),
        sosBleSenderIdentityStoreProvider.overrideWithValue(
          _FakeSosBleSenderIdentitySource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(platform.events.close);
    final controller = container.read(sosBleControllerProvider.notifier);
    await settleSupport(container);
    await controller.setListening(true);
    final frames = const SosBlePayloadCodec().encodeFrames(
      SosBleEvent(
        eventId: '1122334455667788',
        createdAt: DateTime.now().toUtc(),
        locationStatus: SosBleLocationStatus.unavailable,
        batteryPercent: 73,
        alias: 'Aung',
        message: 'Need water.',
      ),
    );

    platform.events.add(SosBleAdvertisement(frames.first, rssi: -57));
    for (final frame in frames.skip(1).toList().reversed) {
      platform.events.add(SosBleAdvertisement(frame, rssi: -57));
    }
    await Future<void>.delayed(Duration.zero);

    final event = container.read(sosBleControllerProvider).nearbyEvents.single;
    expect(event.alias, 'Aung');
    expect(event.message, 'Need water.');
  });

  test('does not attach metadata with a mismatched event timestamp', () async {
    final platform = FakeSosBlePlatform();
    final container = ProviderContainer(
      overrides: [
        sosBlePlatformProvider.overrideWithValue(platform),
        sosBleSenderIdentityStoreProvider.overrideWithValue(
          _FakeSosBleSenderIdentitySource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(platform.events.close);
    final controller = container.read(sosBleControllerProvider.notifier);
    await settleSupport(container);
    await controller.setListening(true);
    final eventId = '1122334455667788';
    final metadataFrames = const SosBlePayloadCodec().encodeMetadataFrames(
      SosBleEvent(
        eventId: eventId,
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
        locationStatus: SosBleLocationStatus.unavailable,
        batteryPercent: 73,
        alias: 'Aung',
      ),
    );
    final baseFrame = const SosBlePayloadCodec().encode(
      SosBleEvent(
        eventId: eventId,
        createdAt: DateTime.now().toUtc(),
        locationStatus: SosBleLocationStatus.unavailable,
        batteryPercent: 73,
      ),
    );

    for (final frame in metadataFrames) {
      platform.events.add(SosBleAdvertisement(frame));
    }
    platform.events.add(SosBleAdvertisement(baseFrame));
    await Future<void>.delayed(Duration.zero);

    final event = container.read(sosBleControllerProvider).nearbyEvents.single;
    expect(event.alias, isNull);
    expect(event.message, isNull);
  });

  test(
    'restores background events, focuses notification event, and never relays',
    () async {
      final platform = FakeSosBlePlatform();
      final container = ProviderContainer(
        overrides: [
          sosBlePlatformProvider.overrideWithValue(platform),
          sosBleSenderIdentityStoreProvider.overrideWithValue(
            _FakeSosBleSenderIdentitySource(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(platform.events.close);
      final eventId = '2233445566778899';
      final payload = const SosBlePayloadCodec().encode(
        SosBleEvent(
          eventId: eventId,
          createdAt: DateTime.now().toUtc(),
          locationStatus: SosBleLocationStatus.current,
          batteryPercent: 64,
          latitude: 21.951,
          longitude: 96.081,
        ),
      );
      platform.backgroundAdvertisements.add(
        SosBleAdvertisement(payload, rssi: -49, background: true),
      );
      platform.pendingNotificationEventId = eventId;
      final controller = container.read(sosBleControllerProvider.notifier);
      await settleSupport(container);

      await controller.setBackgroundListening(true);

      final state = container.read(sosBleControllerProvider);
      expect(state.backgroundListening, isTrue);
      expect(state.nearbyEvents.single.eventId, eventId);
      expect(state.nearbyEvents.single.rssi, -49);
      expect(state.focusedEventId, eventId);
      expect(platform.relayPayloads, isEmpty);
    },
  );

  test(
    'disabling background receiver does not stop foreground receiver',
    () async {
      final platform = FakeSosBlePlatform();
      final container = ProviderContainer(
        overrides: [
          sosBlePlatformProvider.overrideWithValue(platform),
          sosBleSenderIdentityStoreProvider.overrideWithValue(
            _FakeSosBleSenderIdentitySource(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(platform.events.close);
      final controller = container.read(sosBleControllerProvider.notifier);
      await settleSupport(container);

      await controller.setListening(true);
      await controller.setBackgroundListening(true);
      await controller.setBackgroundListening(false);

      final state = container.read(sosBleControllerProvider);
      expect(state.listening, isTrue);
      expect(state.backgroundListening, isFalse);
      expect(platform.backgroundScanEnabled, isFalse);
    },
  );

  test(
    'newer frames replace one sender while preserving other senders',
    () async {
      final platform = FakeSosBlePlatform();
      final container = ProviderContainer(
        overrides: [
          sosBlePlatformProvider.overrideWithValue(platform),
          sosBleSenderIdentityStoreProvider.overrideWithValue(
            _FakeSosBleSenderIdentitySource(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(platform.events.close);
      final controller = container.read(sosBleControllerProvider.notifier);
      await settleSupport(container);
      await controller.setListening(true);

      final firstSenderFrame = _senderFrame('01020304', 1, 16.8, 96.1);
      final replacementFrame = _senderFrame('01020304', 2, 16.9, 96.2);
      final otherSenderFrame = _senderFrame('aabbccdd', 1, 21.9, 96.0);
      platform.events.add(SosBleAdvertisement(firstSenderFrame));
      platform.events.add(SosBleAdvertisement(otherSenderFrame));
      await Future<void>.delayed(Duration.zero);
      controller.selectEvent(
        SosBleSenderMetadata(senderToken: '01020304', eventSequence: 1).eventId,
      );

      platform.events.add(SosBleAdvertisement(replacementFrame));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(sosBleControllerProvider);
      expect(state.nearbyEvents, hasLength(2));
      expect(state.nearbyEvents.map((event) => event.senderToken), [
        '01020304',
        'aabbccdd',
      ]);
      expect(state.nearbyEvents.first.eventSequence, 2);
      expect(state.nearbyEvents.first.latitude, 16.9);
      expect(state.selectedEventId, replacementFrameEventId);
    },
  );

  test('permission revocation stops an active foreground receiver', () async {
    final platform = FakeSosBlePlatform();
    final container = ProviderContainer(
      overrides: [
        sosBlePlatformProvider.overrideWithValue(platform),
        sosBleSenderIdentityStoreProvider.overrideWithValue(
          _FakeSosBleSenderIdentitySource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(platform.events.close);
    final controller = container.read(sosBleControllerProvider.notifier);
    await settleSupport(container);
    await controller.setListening(true);
    platform.permissionState = const SosBlePermissionState(
      supported: true,
      bluetoothEnabled: true,
      scanGranted: false,
      advertiseGranted: true,
      notificationGranted: true,
    );

    await controller.restoreBackgroundEvents();

    final state = container.read(sosBleControllerProvider);
    expect(state.listening, isFalse);
    expect(state.error, 'permission_denied');
    expect(platform.scanStopped, 1);
  });

  test('permission revocation stops an active broadcast', () async {
    final platform = FakeSosBlePlatform();
    final container = ProviderContainer(
      overrides: [
        sosBlePlatformProvider.overrideWithValue(platform),
        sosBleSenderIdentityStoreProvider.overrideWithValue(
          _FakeSosBleSenderIdentitySource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(platform.events.close);
    final controller = container.read(sosBleControllerProvider.notifier);
    await settleSupport(container);
    await controller.broadcast(draft);
    platform.permissionState = const SosBlePermissionState(
      supported: true,
      bluetoothEnabled: true,
      scanGranted: true,
      advertiseGranted: false,
      notificationGranted: true,
    );

    await controller.restoreBackgroundEvents();

    final state = container.read(sosBleControllerProvider);
    expect(state.isBroadcasting, isFalse);
    expect(state.activeEvent, isNull);
    expect(state.error, 'permission_denied');
    expect(platform.broadcastStopped, 1);
  });
}

Future<void> settleSupport(ProviderContainer container) async {
  container.read(sosBleControllerProvider);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final draft = SosDraft(
  id: '00112233-4455-6677-8899-aabbccddeeff',
  createdAt: DateTime.utc(2026, 7, 23),
  selectedContactIds: const [],
  recipients: const [],
  message: null,
  location: null,
  profileName: 'Test User',
  body: 'Test SOS body.',
  status: SosDraftStatus.prepared,
);

final metadataDraft = SosDraft(
  id: '00112233-4455-6677-8899-aabbccddeeff',
  createdAt: DateTime.now().toUtc(),
  selectedContactIds: const [],
  recipients: const [],
  message: null,
  location: null,
  profileName: 'Test User',
  body: 'Test SOS body.',
  status: SosDraftStatus.prepared,
  bleAlias: 'Aung',
  bleMessage: 'Trapped upstairs.',
);

final class FakeSosBlePlatform implements SosBlePlatformService {
  final events = StreamController<SosBleAdvertisement>.broadcast();
  final broadcastPayloads = <Uint8List>[];
  final relayPayloads = <Uint8List>[];
  final broadcastFrameSets = <List<Uint8List>>[];
  final relayFrameSets = <List<Uint8List>>[];
  var permissionsRequested = 0;
  var requestPermissionsResult = true;
  var scanStarted = 0;
  var scanStopped = 0;
  var broadcastStopped = 0;
  var backgroundScanEnabled = false;
  final backgroundAdvertisements = <SosBleAdvertisement>[];
  String? pendingNotificationEventId;
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
    return requestPermissionsResult;
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
  }) async {
    broadcastFrameSets.add(payloads);
    broadcastPayloads.addAll(payloads);
  }

  @override
  Future<void> startRelayBroadcast(
    List<Uint8List> payloads, {
    String languageCode = 'en',
  }) async {
    relayFrameSets.add(payloads);
    relayPayloads.addAll(payloads);
  }

  @override
  Future<void> stopBroadcast() async {
    broadcastStopped++;
  }

  @override
  Future<void> startScan() async {
    scanStarted++;
  }

  @override
  Future<void> stopScan() async {
    scanStopped++;
  }

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
      List.unmodifiable(backgroundAdvertisements);

  @override
  Future<String?> getPendingNotificationEventId() async {
    final value = pendingNotificationEventId;
    pendingNotificationEventId = null;
    return value;
  }
}

final class _FakeSosBleSenderIdentitySource
    implements SosBleSenderIdentitySource {
  var sequence = 0;

  @override
  Future<SosBleSenderMetadata> next({DateTime? now}) async {
    return SosBleSenderMetadata(
      senderToken: '10203040',
      eventSequence: sequence++,
    );
  }
}

final replacementFrameEventId = SosBleSenderMetadata(
  senderToken: '01020304',
  eventSequence: 2,
).eventId;

Uint8List _senderFrame(
  String senderToken,
  int eventSequence,
  double latitude,
  double longitude,
) {
  final event = SosBleEvent(
    eventId: SosBleSenderMetadata(
      senderToken: senderToken,
      eventSequence: eventSequence,
    ).eventId,
    createdAt: DateTime.now().toUtc(),
    locationStatus: SosBleLocationStatus.current,
    batteryPercent: 50,
    latitude: latitude,
    longitude: longitude,
    senderToken: senderToken,
    eventSequence: eventSequence,
  );
  return const SosBlePayloadCodec().encode(event);
}
