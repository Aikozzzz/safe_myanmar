import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/settings/application/language_preference_controller.dart';
import 'package:mobile/features/settings/application/language_preference_state.dart';
import 'package:mobile/features/settings/application/providers.dart';
import 'package:mobile/features/settings/data/secure_language_preference_repository.dart';
import 'package:mobile/features/settings/domain/app_language.dart';
import 'package:mobile/features/profile/data/secure_local_profile_repository.dart';

import '../../../support/fake_language_preference_repository.dart';

void main() {
  test('defaults to English when no secure preference exists', () async {
    final storage = _FakeSecureStorageDriver();
    final repository = SecureLanguagePreferenceRepository(storage);

    expect(await repository.read(), AppLanguage.english);
    expect(storage.readKeys, [SecureLanguagePreferenceRepository.storageKey]);
  });

  test(
    'invalid secure values default to English and valid Burmese persists',
    () async {
      final storage = _FakeSecureStorageDriver()
        ..values[SecureLanguagePreferenceRepository.storageKey] = 'fr';
      final repository = SecureLanguagePreferenceRepository(storage);

      expect(await repository.read(), AppLanguage.english);

      await repository.write(AppLanguage.burmese);
      expect(
        storage.values[SecureLanguagePreferenceRepository.storageKey],
        'my',
      );
      expect(await repository.read(), AppLanguage.burmese);
    },
  );

  test(
    'controller loads English, saves Burmese, and persists across restart',
    () async {
      final repository = FakeLanguagePreferenceRepository();
      final first = _container(repository);
      addTearDown(first.dispose);

      expect(
        first.read(languagePreferenceControllerProvider).phase,
        LanguagePreferencePhase.loading,
      );
      await _settle();
      expect(
        first.read(languagePreferenceControllerProvider).language,
        AppLanguage.english,
      );
      expect(
        await first
            .read(languagePreferenceControllerProvider.notifier)
            .setLanguage(AppLanguage.burmese),
        LanguagePreferenceOperationResult.success,
      );

      final restart = _container(repository);
      addTearDown(restart.dispose);
      await _settleContainer(restart);
      expect(
        restart.read(languagePreferenceControllerProvider).language,
        AppLanguage.burmese,
      );
    },
  );

  test('read failure keeps English active and can retry', () async {
    final repository = FakeLanguagePreferenceRepository()
      ..readError = StateError('unavailable');
    final container = _container(repository);
    addTearDown(container.dispose);

    await _settleContainer(container);
    expect(
      container.read(languagePreferenceControllerProvider).errorKind,
      LanguagePreferenceErrorKind.read,
    );
    expect(
      container.read(languagePreferenceControllerProvider).language,
      AppLanguage.english,
    );

    repository.readError = null;
    await container.read(languagePreferenceControllerProvider.notifier).retry();
    expect(
      container.read(languagePreferenceControllerProvider).phase,
      LanguagePreferencePhase.ready,
    );
  });

  test(
    'write failure preserves the previous language and retries pending choice',
    () async {
      final repository = FakeLanguagePreferenceRepository()
        ..writeError = StateError('write failed');
      final container = _container(repository);
      addTearDown(container.dispose);
      await _settleContainer(container);

      expect(
        await container
            .read(languagePreferenceControllerProvider.notifier)
            .setLanguage(AppLanguage.burmese),
        LanguagePreferenceOperationResult.failed,
      );
      final failed = container.read(languagePreferenceControllerProvider);
      expect(failed.language, AppLanguage.english);
      expect(failed.errorKind, LanguagePreferenceErrorKind.write);

      repository.writeError = null;
      await container
          .read(languagePreferenceControllerProvider.notifier)
          .retry();
      expect(
        container.read(languagePreferenceControllerProvider).language,
        AppLanguage.burmese,
      );
    },
  );
}

ProviderContainer _container(FakeLanguagePreferenceRepository repository) =>
    ProviderContainer(
      overrides: [
        languagePreferenceRepositoryProvider.overrideWithValue(repository),
      ],
    );

Future<void> _settleContainer(ProviderContainer container) async {
  container.read(languagePreferenceControllerProvider);
  await _settle();
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _FakeSecureStorageDriver implements SecureStorageDriver {
  final values = <String, String>{};
  final readKeys = <String>[];

  @override
  Future<String?> read(String key) async {
    readKeys.add(key);
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
