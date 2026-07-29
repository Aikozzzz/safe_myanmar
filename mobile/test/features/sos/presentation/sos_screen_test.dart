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
import 'package:mobile/features/sos/data/native_sms_composer.dart';
import 'package:mobile/features/sos/domain/sos_draft.dart';
import 'package:mobile/features/sos/presentation/hold_to_confirm.dart';

import '../../../support/fake_local_profile_repository.dart';
import '../../../support/fake_location_repository.dart';
import '../../../support/fake_sos_draft_repository.dart';

void main() {
  late FakeLocalProfileRepository profileRepository;
  late FakeSosDraftRepository draftRepository;
  late FakeLocationRepository locationRepository;
  late _FakeComposer composer;
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
    composer = _FakeComposer();
  });

  Future<void> pumpSos(WidgetTester tester, {double textScale = 1}) async {
    final router = createRouter(initialLocation: '/sos');
    addTearDown(router.dispose);
    container = ProviderContainer(
      overrides: [
        localProfileRepositoryProvider.overrideWithValue(profileRepository),
        sosDraftRepositoryProvider.overrideWithValue(draftRepository),
        locationRepositoryProvider.overrideWithValue(locationRepository),
        nativeSmsComposerProvider.overrideWithValue(composer),
        sosClockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 23, 2)),
        sosDraftIdFactoryProvider.overrideWithValue(() => 'draft-1'),
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

  testWidgets('opening SOS shows preview but prepares and opens nothing', (
    tester,
  ) async {
    await pumpSos(tester);

    expect(find.text('Selected recipients'), findsOneWidget);
    expect(find.text('Test Contact: +12025550123'), findsOneWidget);
    expect(find.text('Exact SMS preview'), findsOneWidget);
    expect(
      find.textContaining('Location unavailable; no coordinates included.'),
      findsOneWidget,
    );
    expect(draftRepository.writes, 0);
    expect(composer.calls, 0);
  });

  testWidgets(
    'no selected contact links to More contacts and blocks preparation',
    (tester) async {
      profileRepository.profile = LocalProfile.empty();
      await pumpSos(tester);

      expect(find.text('No contacts selected'), findsOneWidget);
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

  testWidgets('previews current, last-known, and unavailable location states', (
    tester,
  ) async {
    await pumpSos(tester);
    await container
        .read(foregroundLocationControllerProvider.notifier)
        .requestLocation();
    await tester.pumpAndSettle();
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
    expect(
      find.text('Location unavailable. No coordinates will be included.'),
      findsWidgets,
    );
  });

  testWidgets(
    'continuous hold prepares then opens composer and retains status',
    (tester) async {
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

      expect(composer.calls, 1);
      expect(composer.recipients, ['+12025550123']);
      expect(
        composer.body,
        contains('User-prepared SafeMyanmar emergency message.'),
      );
      expect(
        draftRepository.drafts.single.status,
        SosDraftStatus.composerOpened,
      );
      expect(
        draftRepository.drafts.single.body,
        contains('Profile name: Test User'),
      );
      expect(
        find.textContaining('SafeMyanmar cannot verify SMS transmission'),
        findsWidgets,
      );
      expect(
        find.text('Status: Messaging app opened; outcome unknown'),
        findsOneWidget,
      );
    },
  );

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

    expect(find.text('Hold cancelled. Nothing was opened.'), findsOneWidget);
    expect(draftRepository.writes, 0);
    expect(composer.calls, 0);
  });

  testWidgets('accessible path requires two explicit dialog confirmations', (
    tester,
  ) async {
    await pumpSos(tester);
    await tester.scrollUntilVisible(
      find.text('Use confirmation dialogs instead'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Use confirmation dialogs instead'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm SOS draft details'), findsOneWidget);
    expect(composer.calls, 0);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Open the messaging app?'), findsOneWidget);
    expect(composer.calls, 0);

    await tester.tap(find.text('Prepare and open messaging'));
    await tester.pumpAndSettle();
    expect(composer.calls, 1);
    expect(draftRepository.drafts.single.status, SosDraftStatus.composerOpened);
  });

  testWidgets(
    'launcher failure is retained as failed-to-open, never delivery',
    (tester) async {
      composer.result = false;
      await pumpSos(tester);
      await tester.scrollUntilVisible(
        find.text('Use confirmation dialogs instead'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Use confirmation dialogs instead'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prepare and open messaging'));
      await tester.pumpAndSettle();

      expect(draftRepository.drafts.single.status, SosDraftStatus.failedToOpen);
      expect(find.text('Status: Messaging app failed to open'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^Sent$|^Delivered$')), findsNothing);
    },
  );

  testWidgets('retry shows and uses immutable body after profile changes', (
    tester,
  ) async {
    await pumpSos(tester);
    await tester.scrollUntilVisible(
      find.text('Use confirmation dialogs instead'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Use confirmation dialogs instead'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prepare and open messaging'));
    await tester.pumpAndSettle();
    final preparedBody = draftRepository.drafts.single.body;

    await container
        .read(localProfileControllerProvider.notifier)
        .saveDisplayName('Changed User');
    await tester.pumpAndSettle();
    final openAgain = find.widgetWithText(OutlinedButton, 'Open again');
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
    await tester.tap(find.text('Prepare and open messaging'));
    await tester.pumpAndSettle();
    expect(composer.body, preparedBody);
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
  matching: find.text('Hold for 3 seconds to prepare and open messaging'),
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
