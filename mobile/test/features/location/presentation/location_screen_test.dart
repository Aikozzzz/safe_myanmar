import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/safe_theme.dart';
import 'package:mobile/features/location/application/providers.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/location/domain/location_repository.dart';
import 'package:mobile/features/location/presentation/location_screen.dart';
import 'package:mobile/features/navigation/application/providers.dart';
import 'package:mobile/core/network/mapbox_public_access_token.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../../../support/fake_location_repository.dart';
import '../../../support/fake_location_permission_prompt_store.dart';

void main() {
  late FakeLocationRepository repository;
  late FakeLocationPermissionPromptStore promptStore;

  setUp(() {
    repository = FakeLocationRepository()..currentLocation = preciseLocation;
    promptStore = FakeLocationPermissionPromptStore();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationRepositoryProvider.overrideWithValue(repository),
          locationPermissionPromptStoreProvider.overrideWithValue(promptStore),
        ],
        child: MaterialApp(
          theme: SafeTheme.light(),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LocationScreen(),
        ),
      ),
    );
  }

  Future<void> requestLocation(WidgetTester tester) async {
    await tester.pumpAndSettle();
    final action = find.widgetWithText(FilledButton, 'Use my location');
    await tester.scrollUntilVisible(action, 200);
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
    await tester.pumpAndSettle();
  }

  testWidgets('explains foreground location before any request', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Location access is off'), findsOneWidget);
    expect(find.textContaining('before location permission'), findsOneWidget);
    expect(
      find.textContaining('SDK, device, and usage telemetry'),
      findsOneWidget,
    );
    expect(
      find.textContaining('your device location is not included then'),
      findsOneWidget,
    );
    expect(
      find.textContaining('disclosing the viewed map area'),
      findsOneWidget,
    );
    expect(
      find.textContaining('SafeMyanmar backend and Mapbox Directions'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not request device location or construct'),
      findsOneWidget,
    );
    expect(
      find.textContaining('telemetry may use the network'),
      findsOneWidget,
    );
    final action = find.widgetWithText(FilledButton, 'Use my location');
    await tester.scrollUntilVisible(action, 200);
    expect(action, findsOneWidget);
    expect(repository.permissionChecks, 0);
    expect(repository.permissionRequests, 0);
  });

  testWidgets('does not construct Mapbox before explicit location request', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationRepositoryProvider.overrideWithValue(repository),
          locationPermissionPromptStoreProvider.overrideWithValue(promptStore),
          mapboxPublicAccessTokenProvider.overrideWithValue(
            MapboxPublicAccessToken.fromRaw(
              'pk.${List.filled(20, 'a').join()}.${List.filled(20, 'b').join()}',
            ),
          ),
        ],
        child: MaterialApp(
          theme: SafeTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LocationScreen(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('mapbox-map-widget')), findsNothing);
    expect(repository.permissionChecks, 0);
  });

  testWidgets('shows an accessible loading state', (tester) async {
    final completer = Completer<ForegroundLocation>();
    repository.currentLocationCompleter = completer;
    await pumpScreen(tester);

    await tester.pumpAndSettle();
    final action = find.widgetWithText(FilledButton, 'Use my location');
    await tester.scrollUntilVisible(action, 200);
    await tester.ensureVisible(action);
    await tester.pump();
    await tester.tap(action);
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
    await tester.pump();

    expect(find.text('Requesting location'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(CircularProgressIndicator)).label,
      contains('Finding your location'),
    );
    completer.complete(preciseLocation);
    await tester.pumpAndSettle();
  });

  testWidgets('labels precise foreground location and timestamp', (
    tester,
  ) async {
    await pumpScreen(tester);
    await requestLocation(tester);

    expect(find.text('Precise location available'), findsOneWidget);
    expect(find.text('Location: 16.840900, 96.173500'), findsOneWidget);
    expect(
      find.text('Location time: Jul 23, 2026 01:02:03 UTC'),
      findsOneWidget,
    );
  });

  testWidgets('labels approximate foreground location', (tester) async {
    repository.currentLocation = approximateLocation;
    await pumpScreen(tester);
    await requestLocation(tester);

    expect(find.text('Approximate location available'), findsOneWidget);
    expect(
      find.text(
        'Your device provided approximate foreground location access. '
        'The position may cover a wider area.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows denied as recoverable by explicit action', (tester) async {
    repository.checkedPermission = ForegroundLocationPermission.denied;
    repository.requestedPermission = ForegroundLocationPermission.denied;
    await pumpScreen(tester);
    await requestLocation(tester);

    expect(find.text('Allow location access?'), findsOneWidget);
    expect(find.text('Allow Location'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
    expect(repository.permissionRequests, 0);
    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();
    expect(find.text('Location permission denied'), findsOneWidget);
    expect(find.text('Open app settings'), findsOneWidget);
  });

  testWidgets('permanent denial offers app settings without another prompt', (
    tester,
  ) async {
    repository.checkedPermission =
        ForegroundLocationPermission.permanentlyDenied;
    await pumpScreen(tester);
    await requestLocation(tester);

    expect(find.text('Location permission permanently denied'), findsOneWidget);
    expect(find.text('Use my location'), findsNothing);
    expect(find.text('Try location again'), findsNothing);
    await tester.tap(find.text('Open app settings'));
    await tester.pumpAndSettle();
    expect(repository.appSettingsRequests, 1);
    expect(repository.permissionRequests, 0);
  });

  testWidgets('service disabled offers device location settings', (
    tester,
  ) async {
    repository.serviceEnabled = false;
    await pumpScreen(tester);
    await requestLocation(tester);

    expect(find.text('Location services are off'), findsOneWidget);
    await tester.tap(find.text('Open location settings'));
    await tester.pumpAndSettle();
    expect(repository.locationSettingsRequests, 1);
    expect(repository.permissionRequests, 0);
  });

  testWidgets('live failure clearly labels last-known location and time', (
    tester,
  ) async {
    repository.currentLocationError = TimeoutException('live unavailable');
    repository.lastKnownLocation = approximateLocation;
    await pumpScreen(tester);
    await requestLocation(tester);

    expect(find.text('Last known location'), findsOneWidget);
    expect(
      find.text(
        'A live location was unavailable. This is the last known location '
        'reported by your device.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Last known at: Jul 22, 2026 04:05:06 UTC'),
      findsOneWidget,
    );
    expect(find.text('Try location again'), findsOneWidget);
  });

  testWidgets('missing live and last-known fixes shows recoverable error', (
    tester,
  ) async {
    repository.currentLocationError = TimeoutException('live unavailable');
    await pumpScreen(tester);
    await requestLocation(tester);

    expect(find.text('Location temporarily unavailable'), findsOneWidget);
    expect(find.text('Try location again'), findsOneWidget);
  });

  testWidgets('location details show accuracy, coordinates, and update time', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SafeTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LocationDetailsSheet(
            location: preciseLocation,
            isLastKnown: false,
          ),
        ),
      ),
    );

    expect(find.text('Your location details'), findsOneWidget);
    expect(find.text('Access precision'), findsOneWidget);
    expect(find.text('Precise location available'), findsOneWidget);
    expect(find.text('Coordinates'), findsOneWidget);
    expect(find.text('Location: 16.840900, 96.173500'), findsOneWidget);
    expect(find.text('Last update'), findsOneWidget);
    expect(
      find.text('Location time: Jul 23, 2026 01:02:03 UTC'),
      findsOneWidget,
    );
  });

  testWidgets('restores granted location after a previous opt-in', (
    tester,
  ) async {
    promptStore.optedIn = true;
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Precise location available'), findsOneWidget);
    expect(find.text('Use my location'), findsNothing);
    expect(repository.permissionRequests, 0);
    expect(repository.currentLocationRequests, 1);
  });

  testWidgets('Map location chrome uses reviewed Burmese labels', (
    tester,
  ) async {
    await pumpScreen(tester, locale: const Locale('my'));
    await tester.pumpAndSettle();

    expect(find.text('တည်နေရာအသုံးပြုခွင့် ပိတ်ထားသည်'), findsOneWidget);
    expect(find.text('ကျွန်ုပ်၏တည်နေရာကို အသုံးပြုရန်'), findsOneWidget);
    expect(find.textContaining('SDK'), findsOneWidget);
  });
}

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
