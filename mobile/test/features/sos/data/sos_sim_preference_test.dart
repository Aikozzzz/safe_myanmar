import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sos/data/sos_sim_preference.dart';
import 'package:mobile/features/profile/data/secure_local_profile_repository.dart';

void main() {
  test('stores and clears the preferred subscription id', () async {
    final storage = _FakeSecureStorageDriver();
    final preference = SecureSosSimPreferenceStore(storage);

    await preference.writePreferredSubscriptionId('2');
    expect(await preference.readPreferredSubscriptionId(), '2');

    await preference.writePreferredSubscriptionId(null);
    expect(await preference.readPreferredSubscriptionId(), isNull);
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
