import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/data/secure_local_profile_repository.dart';
import 'package:mobile/features/profile/domain/local_profile.dart';
import 'package:mobile/features/profile/domain/local_profile_repository.dart';

void main() {
  late FakeSecureStorageDriver storage;
  late SecureLocalProfileRepository repository;

  setUp(() {
    storage = FakeSecureStorageDriver();
    repository = SecureLocalProfileRepository(storage);
  });

  test('uses one stable secure-storage key and one document', () async {
    final profile = LocalProfile(displayName: 'Test User', contacts: const []);

    await repository.write(profile);
    expect(storage.values.keys, [SecureLocalProfileRepository.storageKey]);
    expect(await repository.read(), profile);
  });

  test('secure storage never silently resets profile data on errors', () {
    expect(
      FlutterSecureStorageDriver.androidOptions.toMap()['resetOnError'],
      'false',
    );
  });

  test('does not delete or reveal a corrupt encrypted value on read', () async {
    const secret = 'Sensitive Name +12025550123';
    storage.values[SecureLocalProfileRepository.storageKey] = secret;

    Object? thrown;
    try {
      await repository.read();
    } on Object catch (error) {
      thrown = error;
    }

    expect(thrown, isA<LocalProfileReadException>());
    expect(thrown.toString(), isNot(contains('Sensitive Name')));
    expect(thrown.toString(), isNot(contains('+12025550123')));
    expect(storage.deletes, 0);
    expect(storage.values[SecureLocalProfileRepository.storageKey], secret);
  });

  test('redacts secure-store read and write failures', () async {
    const secret = 'Sensitive Name +12025550123';
    storage.error = StateError(secret);

    await expectLater(
      repository.read(),
      throwsA(
        isA<LocalProfileReadException>().having(
          (error) => error.toString(),
          'safe read error',
          isNot(contains(secret)),
        ),
      ),
    );
    await expectLater(
      repository.write(LocalProfile.empty()),
      throwsA(
        isA<LocalProfileWriteException>().having(
          (error) => error.toString(),
          'safe write error',
          isNot(contains(secret)),
        ),
      ),
    );
  });
}

final class FakeSecureStorageDriver implements SecureStorageDriver {
  final values = <String, String>{};
  Object? error;
  int deletes = 0;

  @override
  Future<String?> read(String key) async {
    if (error case final value?) throw value;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (error case final value?) throw value;
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (error case final value?) throw value;
    deletes += 1;
    values.remove(key);
  }
}
