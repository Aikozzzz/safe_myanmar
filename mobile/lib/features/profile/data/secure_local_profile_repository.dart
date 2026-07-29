import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/local_profile.dart';
import '../domain/local_profile_repository.dart';
import 'local_profile_codec.dart';

abstract interface class SecureStorageDriver {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

final class FlutterSecureStorageDriver implements SecureStorageDriver {
  FlutterSecureStorageDriver([FlutterSecureStorage? storage])
    : _storage =
          storage ?? const FlutterSecureStorage(aOptions: androidOptions);

  static const androidOptions = AndroidOptions(resetOnError: false);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

final class SecureLocalProfileRepository implements LocalProfileRepository {
  SecureLocalProfileRepository(this._storage);

  static const storageKey = 'local_profile_v1';

  final SecureStorageDriver _storage;

  @override
  Future<LocalProfile> read() async {
    late final String? payload;
    try {
      payload = await _storage.read(storageKey);
    } on Object {
      throw const LocalProfileReadException(
        LocalProfileReadFailureKind.unavailable,
      );
    }
    if (payload == null) return LocalProfile.empty();
    return LocalProfileCodec.decode(payload);
  }

  @override
  Future<void> write(LocalProfile profile) async {
    final payload = LocalProfileCodec.encode(profile);
    try {
      await _storage.write(storageKey, payload);
    } on Object {
      throw const LocalProfileWriteException();
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(storageKey);
    } on Object {
      throw const LocalProfileWriteException();
    }
  }
}
