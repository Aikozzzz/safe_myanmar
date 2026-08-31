import '../../profile/data/secure_local_profile_repository.dart';

abstract interface class LocationPermissionPromptStore {
  Future<bool> hasShownExplanation();

  Future<void> markExplanationShown();

  Future<bool> hasOptedIn();

  Future<void> markOptedIn();
}

final class SecureLocationPermissionPromptStore
    implements LocationPermissionPromptStore {
  const SecureLocationPermissionPromptStore(this._storage);

  static const storageKey = 'location_permission_explanation_v1';
  static const optInStorageKey = 'location_permission_opt_in_v1';

  final SecureStorageDriver _storage;

  @override
  Future<bool> hasShownExplanation() async =>
      (await _storage.read(storageKey)) == '1';

  @override
  Future<void> markExplanationShown() => _storage.write(storageKey, '1');

  @override
  Future<bool> hasOptedIn() async =>
      (await _storage.read(optInStorageKey)) == '1';

  @override
  Future<void> markOptedIn() => _storage.write(optInStorageKey, '1');
}
