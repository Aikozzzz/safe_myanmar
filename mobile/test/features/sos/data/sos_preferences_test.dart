import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/data/secure_local_profile_repository.dart';
import 'package:mobile/features/sos/data/sos_preferences.dart';

void main() {
  test('stores all SOS preferences in one secure document', () async {
    final storage = _FakeSecureStorageDriver();
    final store = SecureSosPreferencesStore(storage);
    const preferences = SosPreferences(
      includeLocation: true,
      shareNearbySos: true,
      receiveNearbySos: true,
      relayNearbySos: true,
      soundEnabled: true,
      backgroundReceive: true,
    );

    await store.write(preferences);

    expect(storage.values.keys, [SecureSosPreferencesStore.storageKey]);
    expect(await store.read(), isA<SosPreferences>());
    final restored = await store.read();
    expect(restored.includeLocation, isTrue);
    expect(restored.shareNearbySos, isTrue);
    expect(restored.receiveNearbySos, isTrue);
    expect(restored.relayNearbySos, isTrue);
    expect(restored.soundEnabled, isTrue);
    expect(restored.backgroundReceive, isTrue);
  });

  test('invalid or missing secure data safely defaults to disabled', () async {
    final storage = _FakeSecureStorageDriver()
      ..values[SecureSosPreferencesStore.storageKey] = 'not-json';
    final store = SecureSosPreferencesStore(storage);

    expect((await store.read()).includeLocation, isFalse);
    expect((await store.read()).backgroundReceive, isFalse);
  });
}

final class _FakeSecureStorageDriver implements SecureStorageDriver {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
