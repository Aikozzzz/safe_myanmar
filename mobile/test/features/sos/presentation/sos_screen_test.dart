import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/router.dart';
import 'package:mobile/features/location/application/providers.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/profile/application/providers.dart';
import 'package:mobile/features/profile/domain/local_profile.dart';
import 'package:mobile/features/sos/application/providers.dart';
import 'package:mobile/features/sos/data/sos_ble_sender_identity.dart';
import 'package:mobile/features/sos/data/native_sms_composer.dart';
import 'package:mobile/features/sos/data/native_sms_sender.dart';
import 'package:mobile/features/sos/data/sos_sim_preference.dart';
import 'package:mobile/features/sos/domain/sos_ble.dart';
import 'package:mobile/features/sos/domain/sos_draft.dart';
import 'package:mobile/features/sos/presentation/hold_to_confirm.dart';

import '../../../support/fake_local_profile_repository.dart';
import '../../../support/fake_location_permission_prompt_store.dart';
import '../../../support/fake_location_repository.dart';
import '../../../support/fake_sos_draft_repository.dart';

void main() {
  late FakeLocalProfileRepository profileRepository;
  late FakeSosDraftRepository draftRepository;
  late FakeLocationRepository locationRepository;
  late FakeLocationPermissionPromptStore promptStore;
  late _FakeComposer composer;
  late _FakeSender sender;
  late _FakeSimPreferenceStore simPreference;
  late ProviderContainer container;

  setUp(() {
    profileRepository = FakeLocalProfileRepository()
      ..profile = LocalProfile(
        displayName: 'Test User',
        contacts: const [
          EmergencyContact(
            id: 'contact-1',
            name: 'Test Contact',
            phoneNumber: '+12025550123',
            label: 'Family',
            selectedForSos: true,
          ),
        ],
      );
    draftRepository = FakeSosDraftRepository();
    locationRepository = FakeLocationRepository()
      ..currentLocation = preciseLocation;
    promptStore = FakeLocationPermissionPromptStore();
    composer = _FakeComposer();
    sender = _FakeSender();
    simPreference = _FakeSimPreferenceStore();
  });

  Future<void> pumpSos(
    WidgetTester tester, {
    double textScale = 1,
    SosBlePlatformService? blePlatform,
    String draftId = 'draft-1',
  }) async {
    final router = createRouter(initialLocation: '/sos');
    addTearDown(router.dispose);
    container = ProviderContainer(
      overrides: [
        localProfileRepositoryProvider.overrideWithValue(profileRepository),
        sosDraftRepositoryProvider.overrideWithValue(draftRepository),
        locationRepositoryProvider.overrideWithValue(locationRepository),
        locationPermissionPromptStoreProvider.overrideWithValue(promptStore),
        nativeSmsComposerProvider.overrideWithValue(composer),
        nativeSmsSenderProvider.overrideWithValue(sender),
        sosSimPreferenceStoreProvider.overrideWithValue(simPreference),
        sosBleSenderIdentityStoreProvider.overrideWithValue(
          _FakeSosBleSenderIdentitySource(),
        ),
        sosClockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 23, 2)),
        sosDraftIdFactoryProvider.overrideWithValue(() => draftId),
        if (blePlatform != null)
          sosBlePlatformProvider.overrideWithValue(blePlatform),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: SafeMyanmarApp(router: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> revealInSos(WidgetTester tester, Finder target) async {
    if (target.evaluate().isEmpty) {
      final scrollable = find.byType(Scrollable).first;
      final state = tester.state<ScrollableState>(scrollable);
      state.position.jumpTo(0);
      await tester.pump();

      for (
        var attempt = 0;
        attempt < 30 && target.evaluate().isEmpty;
        attempt++
      ) {
        final position = state.position;
        if (position.pixels >= position.maxScrollExtent) {
          break;
        }
        position.jumpTo(
          (position.pixels + 240).clamp(0, position.maxScrollExtent).toDouble(),
        );
        await tester.pump();
      }
    }

    expect(target, findsWidgets);
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
  }

  testWidgets('opening SOS shows preview but prepares and opens nothing', (
    tester,
  ) async {
    await pumpSos(tester);

    expect(find.text('Selected recipients'), findsOneWidget);
    expect(find.text('Test Contact: +12025550123'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Exact SMS preview'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Exact SMS preview'), findsOneWidget);
    expect(
      find.textContaining('Location unavailable; no coordinates included.'),
      findsOneWidget,
    );
    expect(draftRepository.writes, 0);
    expect(composer.calls, 0);
  });

  testWidgets('shows readiness before review without starting an SOS', (
    tester,
  ) async {
    await pumpSos(tester);

    final readiness = find.byKey(const Key('sos-readiness-summary'));
    expect(readiness, findsOneWidget);
    expect(
      find.descendant(
        of: readiness,
        matching: find.byIcon(Icons.check_circle_outline),
      ),
      findsOneWidget,
    );
    expect(draftRepository.writes, 0);
    expect(sender.calls, 0);
    expect(composer.calls, 0);
  });

  testWidgets(
    'no selected contact links to More contacts and blocks preparation',
    (tester) async {
      profileRepository.profile = LocalProfile.empty();
      await pumpSos(tester);

      expect(find.text('No contacts selected'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('sos-readiness-summary')),
          matching: find.byIcon(Icons.person_search_outlined),
        ),
        findsOneWidget,
      );
      final contactsAction = find.widgetWithText(
        OutlinedButton,
        'Open More contacts',
      );
      await tester.tap(contactsAction);
      await tester.pumpAndSettle();
      expect(find.text('Emergency contacts'), findsOneWidget);
      expect(draftRepository.writes, 0);
      expect(composer.calls, 0);
    },
  );

  testWidgets('no selected contact disables hold and accessible activation', (
    tester,
  ) async {
    profileRepository.profile = LocalProfile.empty();
    await pumpSos(tester);
    await tester.scrollUntilVisible(
      _holdLabel,
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      tester.widget<HoldToConfirm>(find.byType(HoldToConfirm)).enabled,
      isFalse,
    );
    expect(draftRepository.writes, 0);
    expect(composer.calls, 0);
  });

  testWidgets('nearby sharing can prepare an SOS without an SMS contact', (
    tester,
  ) async {
    profileRepository.profile = LocalProfile.empty();
    final blePlatform = _FakeSosBlePlatform();
    await pumpSos(
      tester,
      blePlatform: blePlatform,
      draftId: '00112233-4455-6677-8899-aabbccddeeff',
    );
    await tester.pump();
    await tester.pump();
    expect(container.read(sosBleControllerProvider).supported, isTrue);

    final sharing = find.widgetWithText(
      CheckboxListTile,
      'Share limited SOS data nearby',
    );
    await tester.scrollUntilVisible(
      sharing,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(sharing);
    await tester.pumpAndSettle();
    await tester.tap(sharing);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      _holdLabel,
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      tester.widget<HoldToConfirm>(find.byType(HoldToConfirm)).enabled,
      isTrue,
    );
    final gesture = await tester.startGesture(tester.getCenter(_holdLabel));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await gesture.up();

    expect(draftRepository.drafts, hasLength(1));
    expect(blePlatform.broadcastPayloads, hasLength(1));
    expect(sender.calls, 0);
    await revealInSos(tester, find.text('Broadcast frame details'));
    expect(find.textContaining('Event ID: a55a102030400000'), findsOneWidget);
    expect(find.textContaining('Battery: 80%'), findsOneWidget);
  });

  testWidgets('nearby SOS shows the decoded frame details', (tester) async {
    final blePlatform = _FakeSosBlePlatform();
    addTearDown(blePlatform.dispose);
    await pumpSos(tester, blePlatform: blePlatform);

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
    blePlatform.events.add(SosBleAdvertisement(payload, rssi: -57));
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Nearby unverified SOS'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.textContaining('Event ID: 1122334455667788'), findsOneWidget);
    expect(find.textContaining('Battery: 73%'), findsOneWidget);
    expect(find.textContaining('Signal: -57 dBm'), findsOneWidget);
    expect(
      find.textContaining('Protocol: v3; TTL: 10 minutes'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Coordinates: 21.951000, 96.081000'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Google Maps: https://maps.google.com/?q=21.951000,96.081000',
      ),
      findsOneWidget,
    );
    container
        .read(sosBleControllerProvider.notifier)
        .dismissNearbyEvent('1122334455667788');
    await tester.pump();
  });

  testWidgets('previews current, last-known, and unavailable location states', (
    tester,
  ) async {
    await pumpSos(tester);
    final locationSharing = find.widgetWithText(
      SwitchListTile,
      'Include location in this SOS',
    );
    await container
        .read(foregroundLocationControllerProvider.notifier)
        .requestLocation();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      locationSharing,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(locationSharing);
    await tester.pumpAndSettle();
    await tester.tap(locationSharing);
    await tester.pumpAndSettle();
    await revealInSos(
      tester,
      find.textContaining('Current precise location: 16.840900, 96.173500'),
    );
    expect(
      find.textContaining('Current precise location: 16.840900, 96.173500'),
      findsWidgets,
    );

    locationRepository.currentLocationError = StateError('unavailable');
    locationRepository.lastKnownLocation = approximateLocation;
    await container
        .read(foregroundLocationControllerProvider.notifier)
        .requestLocation();
    await tester.pumpAndSettle();
    await revealInSos(
      tester,
      find.textContaining(
        'Last-known approximate location: 21.958800, 96.089100',
      ),
    );
    expect(
      find.textContaining(
        'Last-known approximate location: 21.958800, 96.089100',
      ),
      findsWidgets,
    );

    locationRepository.lastKnownLocation = null;
    await container
        .read(foregroundLocationControllerProvider.notifier)
        .requestLocation();
    await tester.pumpAndSettle();
    await revealInSos(
      tester,
      find.text('Location unavailable. No coordinates will be included.'),
    );
    expect(
      find.text('Location unavailable. No coordinates will be included.'),
      findsWidgets,
    );
  });

  testWidgets(
    'explicitly continues without location when it becomes unavailable',
    (tester) async {
      profileRepository.profile = LocalProfile.empty();
      final blePlatform = _FakeSosBlePlatform();
      addTearDown(blePlatform.dispose);
      await pumpSos(
        tester,
        blePlatform: blePlatform,
        draftId: '00112233-4455-6677-8899-aabbccddeeff',
      );

      final locationSharing = find.widgetWithText(
        SwitchListTile,
        'Include location in this SOS',
      );
      await tester.scrollUntilVisible(
        locationSharing,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(locationSharing);
      await tester.pumpAndSettle();
      await tester.tap(locationSharing);
      await tester.pumpAndSettle();

      locationRepository.currentLocationError = StateError('unavailable');
      locationRepository.lastKnownLocation = null;
      await container
          .read(foregroundLocationControllerProvider.notifier)
          .requestLocation();
      await tester.pumpAndSettle();
      expect(
        container.read(foregroundLocationControllerProvider).location,
        isNull,
      );
      expect(tester.widget<SwitchListTile>(locationSharing).value, isTrue);

      final nearbySharing = find.widgetWithText(
        CheckboxListTile,
        'Share limited SOS data nearby',
      );
      await tester.scrollUntilVisible(
        nearbySharing,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(nearbySharing);
      await tester.pumpAndSettle();
      await tester.tap(nearbySharing);
      await tester.pumpAndSettle();
      final accessible = find.widgetWithText(
        TextButton,
        'Use confirmation dialogs instead',
      );
      await tester.scrollUntilVisible(
        accessible,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(accessible);
      tester.widget<TextButton>(accessible).onPressed!();
      await tester.pumpAndSettle();
      expect(find.text('Confirm SOS draft details'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Send SOS SMS directly?'), findsOneWidget);
      await tester.tap(find.text('Send SMS now'));
      await tester.pumpAndSettle();

      expect(find.text('Location unavailable'), findsOneWidget);
      await tester.tap(find.text('Continue without location'));
      await tester.pumpAndSettle();

      expect(draftRepository.drafts.single.location, isNull);
      expect(blePlatform.broadcastPayloads, hasLength(1));
    },
  );

  testWidgets('continuous hold prepares then sends SMS and retains status', (
    tester,
  ) async {
    await pumpSos(tester);
    await tester.scrollUntilVisible(
      _holdLabel,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(_holdLabel);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(tester.getCenter(_holdLabel));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await gesture.up();

    expect(sender.calls, 1);
    expect(sender.recipients, ['+12025550123']);
    expect(
      sender.body,
      contains('User-prepared SafeMyanmar emergency message.'),
    );
    expect(draftRepository.drafts.single.status, SosDraftStatus.smsSent);
    expect(
      draftRepository.drafts.single.body,
      contains('Profile name: Test User'),
    );
    expect(find.textContaining('device accepted the SMS'), findsWidgets);
    expect(
      find.text('Status: SMS accepted by device; delivery unconfirmed'),
      findsOneWidget,
    );
  });

  testWidgets('releasing hold early cancels with no draft or composer', (
    tester,
  ) async {
    await pumpSos(tester);
    await tester.scrollUntilVisible(
      _holdLabel,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final gesture = await tester.startGesture(tester.getCenter(_holdLabel));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pump();

    expect(find.text('Hold cancelled. Nothing was sent.'), findsOneWidget);
    expect(draftRepository.writes, 0);
    expect(composer.calls, 0);
  });

  testWidgets('chooses SIM 2 and can remember the preferred SIM', (
    tester,
  ) async {
    sender.sims = const [
      SmsSim(subscriptionId: 1, slotIndex: 0, label: 'MPT'),
      SmsSim(subscriptionId: 2, slotIndex: 1, label: 'ATOM'),
    ];
    await pumpSos(tester);
    await tester.scrollUntilVisible(
      _holdLabel,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final gesture = await tester.startGesture(tester.getCenter(_holdLabel));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await gesture.up();

    expect(find.text('Choose SIM'), findsOneWidget);
    await tester.tap(find.text('SIM 2 - ATOM'));
    await tester.tap(find.text('Remember my preferred SIM'));
    await tester.tap(find.text('Send using SIM'));
    await tester.pumpAndSettle();

    expect(sender.subscriptionId, 2);
    expect(simPreference.preferredSubscriptionId, '2');
    expect(draftRepository.drafts.single.status, SosDraftStatus.smsSent);
  });

  testWidgets('accessible path requires two explicit dialog confirmations', (
    tester,
  ) async {
    await pumpSos(tester);
    final accessible = find.widgetWithText(
      TextButton,
      'Use confirmation dialogs instead',
    );
    await tester.scrollUntilVisible(
      accessible,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(accessible);
    tester.widget<TextButton>(accessible).onPressed!();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(find.text('Confirm SOS draft details'), findsOneWidget);
    expect(composer.calls, 0);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Send SOS SMS directly?'), findsOneWidget);
    expect(composer.calls, 0);

    await tester.tap(find.text('Send SMS now'));
    await tester.pumpAndSettle();
    expect(sender.calls, 1);
    expect(draftRepository.drafts.single.status, SosDraftStatus.smsSent);
  });

  testWidgets(
    'SMS failure is retained as failed, never reported as delivered',
    (tester) async {
      sender.result = const NativeSmsSendResult(NativeSmsSendStatus.failed);
      await pumpSos(tester);
      final accessible = find.widgetWithText(
        TextButton,
        'Use confirmation dialogs instead',
      );
      await tester.scrollUntilVisible(
        accessible,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(accessible);
      tester.widget<TextButton>(accessible).onPressed!();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send SMS now'));
      await tester.pumpAndSettle();

      expect(draftRepository.drafts.single.status, SosDraftStatus.smsFailed);
      expect(find.text('Status: SMS failed; retry available'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^Sent$|^Delivered$')), findsNothing);
    },
  );

  testWidgets('retry shows and uses immutable body after profile changes', (
    tester,
  ) async {
    await pumpSos(tester);
    final accessible = find.widgetWithText(
      TextButton,
      'Use confirmation dialogs instead',
    );
    await tester.scrollUntilVisible(
      accessible,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(accessible);
    tester.widget<TextButton>(accessible).onPressed!();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send SMS now'));
    await tester.pumpAndSettle();
    final preparedBody = draftRepository.drafts.single.body;

    await container
        .read(localProfileControllerProvider.notifier)
        .saveDisplayName('Changed User');
    await tester.pumpAndSettle();
    final openAgain = find.widgetWithText(OutlinedButton, 'Send again');
    await tester.scrollUntilVisible(
      openAgain,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(openAgain);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    tester.widget<OutlinedButton>(openAgain).onPressed!();
    await tester.pumpAndSettle();

    expect(find.textContaining(preparedBody), findsWidgets);
    expect(preparedBody, contains('Profile name: Test User'));
    expect(preparedBody, isNot(contains('Changed User')));
    await tester.tap(find.text('Send SMS now'));
    await tester.pumpAndSettle();
    expect(sender.body, preparedBody);
  });

  testWidgets('SOS screen fits 390x844 at 200 percent text with 48dp actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpSos(tester, textScale: 2);

    expect(tester.takeException(), isNull);
    final contactsAction = find.widgetWithText(
      OutlinedButton,
      'Open More contacts',
    );
    await tester.scrollUntilVisible(
      contactsAction,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.getSize(contactsAction).height, greaterThanOrEqualTo(48));
    final accessibleAction = find.widgetWithText(
      TextButton,
      'Use confirmation dialogs instead',
    );
    await tester.scrollUntilVisible(
      accessibleAction,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(accessibleAction).height, greaterThanOrEqualTo(48));
  });
}

Finder get _holdLabel => find.descendant(
  of: find.byType(HoldToConfirm),
  matching: find.text('Hold for 3 seconds to send SMS'),
);

final preciseLocation = ForegroundLocation(
  latitude: 16.8409,
  longitude: 96.1735,
  timestamp: DateTime.utc(2026, 7, 23, 1, 2, 3),
  precision: LocationPrecision.precise,
);

final approximateLocation = ForegroundLocation(
  latitude: 21.9588,
  longitude: 96.0891,
  timestamp: DateTime.utc(2026, 7, 22, 4, 5, 6),
  precision: LocationPrecision.approximate,
);

final class _FakeComposer implements NativeSmsComposer {
  bool result = true;
  int calls = 0;
  List<String>? recipients;
  String? body;

  @override
  Future<bool> open({
    required List<String> recipients,
    required String body,
  }) async {
    calls++;
    this.recipients = recipients;
    this.body = body;
    return result;
  }
}

final class _FakeSosBlePlatform implements SosBlePlatformService {
  final events = StreamController<SosBleAdvertisement>.broadcast();
  final broadcastPayloads = <Uint8List>[];

  @override
  Stream<SosBleAdvertisement> get payloadStream => events.stream;

  @override
  Stream<String> get notificationEventStream => const Stream.empty();

  void dispose() => events.close();

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> requestPermissions({
    required bool receive,
    required bool broadcast,
    required bool background,
  }) async => true;

  @override
  Future<SosBlePermissionState> getPermissionState() async =>
      const SosBlePermissionState(
        supported: true,
        bluetoothEnabled: true,
        scanGranted: true,
        advertiseGranted: true,
        notificationGranted: true,
      );

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<int?> batteryPercent() async => 80;

  @override
  Future<void> startBroadcast(Uint8List payload) async {
    broadcastPayloads.add(payload);
  }

  @override
  Future<void> startRelayBroadcast(Uint8List payload) async {}

  @override
  Future<void> stopBroadcast() async {}

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<bool> isBackgroundScanEnabled() async => false;

  @override
  Future<void> startBackgroundScan() async {}

  @override
  Future<void> stopBackgroundScan() async {}

  @override
  Future<List<SosBleAdvertisement>> readBackgroundAdvertisements() async =>
      const [];

  @override
  Future<String?> getPendingNotificationEventId() async => null;
}

final class _FakeSosBleSenderIdentitySource
    implements SosBleSenderIdentitySource {
  @override
  Future<SosBleSenderMetadata> next({DateTime? now}) async =>
      const SosBleSenderMetadata(senderToken: '10203040', eventSequence: 0);
}

final class _FakeSender implements NativeSmsSender {
  List<SmsSim> sims = const [
    SmsSim(subscriptionId: 1, slotIndex: 0, label: 'Test SIM'),
  ];
  bool permission = true;
  NativeSmsSendResult result = const NativeSmsSendResult(
    NativeSmsSendStatus.sent,
  );
  int calls = 0;
  List<String>? recipients;
  String? body;
  int? subscriptionId;

  @override
  Future<List<SmsSim>> listSims() async => sims;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<NativeSmsSendResult> send({
    required List<String> recipients,
    required String body,
    required int subscriptionId,
  }) async {
    calls++;
    this.recipients = recipients;
    this.body = body;
    this.subscriptionId = subscriptionId;
    return result;
  }
}

final class _FakeSimPreferenceStore implements SosSimPreferenceStore {
  String? preferredSubscriptionId;

  @override
  Future<String?> readPreferredSubscriptionId() async =>
      preferredSubscriptionId;

  @override
  Future<void> writePreferredSubscriptionId(String? subscriptionId) async {
    preferredSubscriptionId = subscriptionId;
  }
}
