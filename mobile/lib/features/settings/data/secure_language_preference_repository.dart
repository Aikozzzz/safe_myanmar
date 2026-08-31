import '../../profile/data/secure_local_profile_repository.dart';
import '../domain/app_language.dart';

final class SecureLanguagePreferenceRepository
    implements LanguagePreferenceRepository {
  SecureLanguagePreferenceRepository(this._storage);

  static const storageKey = 'app_language_v1';

  final SecureStorageDriver _storage;

  @override
  Future<AppLanguage> read() async {
    final value = await _storage.read(storageKey);
    return AppLanguage.fromStoredValue(value);
  }

  @override
  Future<void> write(AppLanguage language) =>
      _storage.write(storageKey, language.code);
}
