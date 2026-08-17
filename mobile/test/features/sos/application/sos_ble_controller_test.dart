import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sos/application/providers.dart';
import 'package:mobile/features/sos/domain/sos_ble.dart';
import 'package:mobile/features/sos/domain/sos_draft.dart';

void main() {
  test('broadcast requests permissions and starts a compact event', () async {
    final platform = FakeSosBlePlatform();
    final container = ProviderContainer(
      overrides: [sosBlePlatformProvider.overrideWithValue(platform)],
    );
    addTearDown(container.dispose);
    addTearDown(platform.events.close);
    final controller = container.read(sosBleControllerProvider.notifier);
    await settleSupport(container);

    await controller.broadcast(draft);

    expect(platform.permissionsRequested, 1);
    expect(platform.broadcastPayloads, hasLength(1));
    expect(platform.broadcastPayloads.single, hasLength(22));
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
        overrides: [sosBlePlatformProvider.overrideWithValue(platform)],
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

      platform.events.add(payload);
      platform.events.add(payload);
      platform.events.add(Uint8List.fromList([1, 2, 3]));
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(sosBleControllerProvider).nearbyEvents,
        hasLength(1),
      );
      expect(platform.scanStarted, 1);
    },
  );
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

final class FakeSosBlePlatform implements SosBlePlatformService {
  final events = StreamController<Uint8List>.broadcast();
  final broadcastPayloads = <Uint8List>[];
  var permissionsRequested = 0;
  var scanStarted = 0;

  @override
  Stream<Uint8List> get payloadStream => events.stream;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> requestPermissions() async {
    permissionsRequested++;
    return true;
  }

  @override
  Future<int?> batteryPercent() async => 80;

  @override
  Future<void> startBroadcast(Uint8List payload) async {
    broadcastPayloads.add(payload);
  }

  @override
  Future<void> stopBroadcast() async {}

  @override
  Future<void> startScan() async {
    scanStarted++;
  }

  @override
  Future<void> stopScan() async {}
}
