import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/data/secure_local_profile_repository.dart';
import 'package:mobile/features/sos/data/secure_sos_draft_repository.dart';
import 'package:mobile/features/sos/domain/sos_draft_repository.dart';

void main() {
  late _FakeStorage storage;
  late SecureSosDraftRepository repository;

  setUp(() {
    storage = _FakeStorage();
    repository = SecureSosDraftRepository(storage);
  });

  test('uses a secure document separate from the profile', () async {
    await repository.write(const []);

    expect(SecureSosDraftRepository.storageKey, isNot('local_profile_v1'));
    expect(storage.values.keys, [SecureSosDraftRepository.storageKey]);
    expect(await repository.read(), isEmpty);
  });

  test('shared secure storage never silently resets SOS data on errors', () {
    expect(
      FlutterSecureStorageDriver.androidOptions.toMap()['resetOnError'],
      'false',
    );
  });

  test('corruption is recoverable and is not deleted or revealed', () async {
    const secret = 'Sensitive Name +12025550123';
    storage.values[SecureSosDraftRepository.storageKey] = secret;

    await expectLater(
      repository.read(),
      throwsA(
        isA<SosDraftReadException>().having(
          (error) => error.toString(),
          'redacted error',
          isNot(contains(secret)),
        ),
      ),
    );
    expect(storage.values[SecureSosDraftRepository.storageKey], secret);
    expect(storage.deletes, 0);
  });

  test('secure storage failures are redacted', () async {
    storage.error = StateError('Sensitive Name +12025550123');

    await expectLater(repository.read(), throwsA(isA<SosDraftReadException>()));
    await expectLater(
      repository.write(const []),
      throwsA(isA<SosDraftWriteException>()),
    );
  });
}

final class _FakeStorage implements SecureStorageDriver {
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
    deletes++;
    values.remove(key);
  }
}
