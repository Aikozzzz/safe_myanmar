import '../../profile/data/secure_local_profile_repository.dart';

abstract interface class SosSimPreferenceStore {
  Future<String?> readPreferredSubscriptionId();

  Future<void> writePreferredSubscriptionId(String? subscriptionId);
}

final class SecureSosSimPreferenceStore implements SosSimPreferenceStore {
  const SecureSosSimPreferenceStore(this._storage);

  static const storageKey = 'sos_preferred_sim_v1';

  final SecureStorageDriver _storage;

  @override
  Future<String?> readPreferredSubscriptionId() => _storage.read(storageKey);

  @override
  Future<void> writePreferredSubscriptionId(String? subscriptionId) async {
    if (subscriptionId == null) {
      await _storage.delete(storageKey);
    } else {
      await _storage.write(storageKey, subscriptionId);
    }
  }
}
