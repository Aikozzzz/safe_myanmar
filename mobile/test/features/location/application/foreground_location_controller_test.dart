import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/location/application/foreground_location_controller.dart';
import 'package:mobile/features/location/application/foreground_location_state.dart';
import 'package:mobile/features/location/application/providers.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/location/domain/location_repository.dart';

import '../../../support/fake_location_permission_prompt_store.dart';
import '../../../support/fake_location_repository.dart';

void main() {
  late FakeLocationRepository repository;
  late FakeLocationPermissionPromptStore promptStore;
  late ProviderContainer container;

  setUp(() {
    repository = FakeLocationRepository()..currentLocation = preciseLocation;
    promptStore = FakeLocationPermissionPromptStore();
    container = ProviderContainer(
      overrides: [
        locationRepositoryProvider.overrideWithValue(repository),
        locationPermissionPromptStoreProvider.overrideWithValue(promptStore),
      ],
    );
    addTearDown(container.dispose);
  });

  ForegroundLocationState state() =>
      container.read(foregroundLocationControllerProvider);

  ForegroundLocationController controller() =>
      container.read(foregroundLocationControllerProvider.notifier);

  Future<void> request({bool confirmed = true}) =>
      controller().requestLocation(confirmed: confirmed);

  test('starts not requested without touching platform location', () async {
    expect(state(), const ForegroundLocationState.notRequested());
    await controller().restoreGrantedLocation();
    expect(state(), const ForegroundLocationState.notRequested());
    expect(repository.serviceChecks, 0);
    expect(repository.permissionChecks, 0);
    expect(repository.permissionRequests, 0);
    expect(repository.currentLocationRequests, 0);
  });

  test('restores location after a previous opt-in without prompting', () async {
    promptStore.optedIn = true;

    await controller().restoreGrantedLocation();

    expect(state(), ForegroundLocationState.available(preciseLocation));
    expect(repository.permissionRequests, 0);
    expect(repository.currentLocationRequests, 1);
  });

  test('stays requesting while the explicit live lookup is pending', () async {
    final completer = Completer<ForegroundLocation>();
    repository.currentLocationCompleter = completer;

    final pending = request();
    await Future<void>.delayed(Duration.zero);

    expect(state(), const ForegroundLocationState.requesting());
    completer.complete(preciseLocation);
    await pending;
    expect(state(), ForegroundLocationState.available(preciseLocation));
  });

  test('reports service disabled before asking for permission', () async {
    repository.serviceEnabled = false;

    await request();

    expect(state(), const ForegroundLocationState.serviceDisabled());
    expect(repository.permissionChecks, 0);
    expect(repository.permissionRequests, 0);
  });

  test(
    'uses last-known location when the location service is disabled',
    () async {
      repository.serviceEnabled = false;
      repository.lastKnownLocation = approximateLocation;

      await request();

      expect(state(), ForegroundLocationState.lastKnown(approximateLocation));
      expect(repository.permissionChecks, 0);
      expect(repository.lastKnownLocationRequests, 1);
    },
  );

  test('reports denied after one explicit permission request', () async {
    repository.checkedPermission = ForegroundLocationPermission.denied;
    repository.requestedPermission = ForegroundLocationPermission.denied;

    await request();

    expect(state(), const ForegroundLocationState.denied());
    expect(repository.permissionRequests, 1);
    expect(repository.currentLocationRequests, 0);
  });

  test('shows the explanation before the first permission request', () async {
    repository.checkedPermission = ForegroundLocationPermission.denied;

    await request(confirmed: false);

    expect(
      state(),
      const ForegroundLocationState.permissionExplanationRequired(),
    );
    expect(repository.permissionRequests, 0);
    expect(promptStore.markCalls, 1);

    await container
        .read(foregroundLocationControllerProvider.notifier)
        .requestLocation(confirmed: true);
    expect(repository.permissionRequests, 1);
  });

  test('does not prompt again after a denied explanation', () async {
    repository.checkedPermission = ForegroundLocationPermission.denied;
    promptStore.shown = true;

    await request(confirmed: false);
    await request(confirmed: false);

    expect(state(), const ForegroundLocationState.denied());
    expect(repository.permissionRequests, 0);
  });

  test('permanent denial never repeats the platform prompt', () async {
    repository.checkedPermission =
        ForegroundLocationPermission.permanentlyDenied;

    await request();
    await request();

    expect(state(), const ForegroundLocationState.permanentlyDenied());
    expect(repository.permissionChecks, 2);
    expect(repository.permissionRequests, 0);
    expect(repository.currentLocationRequests, 0);
  });

  for (final location in [preciseLocation, approximateLocation]) {
    test(
      '${location.precision.name} permission returns its available state',
      () async {
        repository.currentLocation = location;

        await request();

        expect(state(), ForegroundLocationState.available(location));
        expect(repository.currentLocationRequests, 1);
        expect(repository.lastKnownLocationRequests, 0);
      },
    );
  }

  test('live failure uses one platform last-known location', () async {
    repository.currentLocationError = TimeoutException('no live fix');
    repository.lastKnownLocation = approximateLocation;

    await request();

    expect(state(), ForegroundLocationState.lastKnown(approximateLocation));
    expect(repository.currentLocationRequests, 1);
    expect(repository.lastKnownLocationRequests, 1);
  });

  test('live and last-known failure is recoverable', () async {
    repository.currentLocationError = TimeoutException('no live fix');

    await request();

    expect(state(), const ForegroundLocationState.recoverableError());
    expect(repository.lastKnownLocationRequests, 1);
  });

  test(
    'unable-to-determine permission is recoverable without prompting',
    () async {
      repository.checkedPermission =
          ForegroundLocationPermission.unableToDetermine;

      await request();

      expect(state(), const ForegroundLocationState.recoverableError());
      expect(repository.permissionRequests, 0);
    },
  );

  test('settings actions delegate and allow a fresh explicit check', () async {
    expect(await controller().openAppSettings(), isTrue);
    expect(repository.appSettingsRequests, 1);
    expect(state(), const ForegroundLocationState.notRequested());

    expect(await controller().openLocationSettings(), isTrue);
    expect(repository.locationSettingsRequests, 1);
    expect(state(), const ForegroundLocationState.notRequested());
  });

  test('remembers a successful grant for later launches', () async {
    await request();

    expect(promptStore.optedIn, isTrue);
    expect(promptStore.markOptInCalls, 1);
  });

  test('resume restores a granted location after settings change', () async {
    promptStore
      ..optedIn = true
      ..shown = true;
    repository.checkedPermission = ForegroundLocationPermission.denied;
    await request(confirmed: false);
    expect(state(), const ForegroundLocationState.denied());

    repository.checkedPermission = ForegroundLocationPermission.granted;
    await controller().refreshPermission();

    expect(state(), ForegroundLocationState.available(preciseLocation));
    expect(repository.permissionRequests, 0);
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
