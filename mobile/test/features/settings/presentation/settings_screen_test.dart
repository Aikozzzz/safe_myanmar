import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/router.dart';
import 'package:mobile/features/location/application/providers.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/sos/application/providers.dart';
import 'package:mobile/features/sos/data/sos_preferences.dart';
import 'package:mobile/features/settings/application/providers.dart';

import '../../../support/fake_language_preference_repository.dart';
import '../../../support/fake_location_permission_prompt_store.dart';
import '../../../support/fake_location_repository.dart';
import '../../../support/fake_sos_ble_platform.dart';
import '../../../support/fake_sos_preferences_store.dart';

void main() {
  late FakeLanguagePreferenceRepository languageRepository;
  late FakeSosPreferencesStore preferencesStore;
  late FakeLocationRepository locationRepository;
  late FakeLocationPermissionPromptStore promptStore;
  late FakeSosBlePlatform blePlatform;

  setUp(() {
    languageRepository = FakeLanguagePreferenceRepository();
    preferencesStore = FakeSosPreferencesStore();
    locationRepository = FakeLocationRepository()
      ..currentLocation = ForegroundLocation(
        latitude: 21.9588,
        longitude: 96.0891,
        timestamp: DateTime.utc(2026, 7, 23, 12),
        precision: LocationPrecision.precise,
      );
    promptStore = FakeLocationPermissionPromptStore();
    blePlatform = FakeSosBlePlatform();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    final router = createRouter(initialLocation: '/more/settings');
    addTearDown(router.dispose);
    addTearDown(blePlatform.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          languagePreferenceRepositoryProvider.overrideWithValue(
            languageRepository,
          ),
          sosPreferencesStoreProvider.overrideWithValue(preferencesStore),
          locationRepositoryProvider.overrideWithValue(locationRepository),
          locationPermissionPromptStoreProvider.overrideWithValue(promptStore),
          sosBlePlatformProvider.overrideWithValue(blePlatform),
        ],
        child: SafeMyanmarApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSetting(WidgetTester tester, String key) async {
    final setting = find.byKey(ValueKey(key));
    await tester.ensureVisible(setting);
    await tester.tap(setting);
    await tester.pumpAndSettle();
  }

  testWidgets('Settings contains language and all SOS preference controls', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('language-preference-card')),
      findsOneWidget,
    );
    for (final key in [
      'settings-include-location',
      'settings-share-nearby',
      'settings-receive-nearby',
      'settings-relay-nearby',
      'settings-sound-alert',
      'settings-background-receive',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
  });

  testWidgets('successful settings changes persist and request permissions', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tapSetting(tester, 'settings-include-location');
    await tapSetting(tester, 'settings-share-nearby');
    await tapSetting(tester, 'settings-receive-nearby');
    await tapSetting(tester, 'settings-relay-nearby');
    await tapSetting(tester, 'settings-sound-alert');
    await tapSetting(tester, 'settings-background-receive');

    expect(preferencesStore.preferences, isA<SosPreferences>());
    final saved = preferencesStore.preferences;
    expect(saved.includeLocation, isTrue);
    expect(saved.shareNearbySos, isTrue);
    expect(saved.receiveNearbySos, isTrue);
    expect(saved.relayNearbySos, isTrue);
    expect(saved.soundEnabled, isTrue);
    expect(saved.backgroundReceive, isTrue);
    expect(blePlatform.permissionsRequested, greaterThanOrEqualTo(4));
    expect(blePlatform.scanStarted, greaterThanOrEqualTo(1));
    expect(blePlatform.backgroundScanEnabled, isTrue);
  });
}
