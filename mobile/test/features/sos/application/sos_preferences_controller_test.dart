import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sos/application/providers.dart';
import 'package:mobile/features/sos/application/sos_preferences_controller.dart';
import 'package:mobile/features/sos/data/sos_preferences.dart';

import '../../../support/fake_sos_preferences_store.dart';

void main() {
  test('loads saved choices and persists updated choices', () async {
    final store = FakeSosPreferencesStore()
      ..preferences = const SosPreferences(
        includeLocation: true,
        receiveNearbySos: true,
      );
    final container = _container(store);
    addTearDown(container.dispose);

    await _settle(container);
    final controller = container.read(
      sosPreferencesControllerProvider.notifier,
    );
    expect(
      container
          .read(sosPreferencesControllerProvider)
          .preferences
          .includeLocation,
      isTrue,
    );

    final result = await controller.setShareNearbySos(true);

    expect(result, SosPreferencesOperationResult.success);
    expect(store.preferences.shareNearbySos, isTrue);
  });

  test('write failure keeps the previous choices and retries safely', () async {
    final store = FakeSosPreferencesStore()
      ..writeError = StateError('secure storage unavailable');
    final container = _container(store);
    addTearDown(container.dispose);
    await _settle(container);

    final controller = container.read(
      sosPreferencesControllerProvider.notifier,
    );
    expect(
      await controller.setIncludeLocation(true),
      SosPreferencesOperationResult.failed,
    );
    expect(
      container
          .read(sosPreferencesControllerProvider)
          .preferences
          .includeLocation,
      isFalse,
    );

    store.writeError = null;
    await controller.retry();
    expect(store.preferences.includeLocation, isTrue);
  });
}

ProviderContainer _container(FakeSosPreferencesStore store) =>
    ProviderContainer(
      overrides: [sosPreferencesStoreProvider.overrideWithValue(store)],
    );

Future<void> _settle(ProviderContainer container) async {
  container.read(sosPreferencesControllerProvider);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
