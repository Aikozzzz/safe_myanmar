import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_language.dart';
import 'language_preference_state.dart';
import 'providers.dart';

enum LanguagePreferenceOperationResult { success, busy, failed }

final class LanguagePreferenceController
    extends Notifier<LanguagePreferenceState> {
  late LanguagePreferenceRepository _repository;
  AppLanguage? _retryLanguage;

  @override
  LanguagePreferenceState build() {
    _repository = ref.watch(languagePreferenceRepositoryProvider);
    unawaited(Future<void>.microtask(_load));
    return const LanguagePreferenceState.loading();
  }

  Future<void> retry() async {
    final language = _retryLanguage;
    if (state.errorKind == LanguagePreferenceErrorKind.write &&
        language != null) {
      await _save(language);
      return;
    }
    await _load();
  }

  Future<LanguagePreferenceOperationResult> setLanguage(
    AppLanguage language,
  ) async {
    if (state.isBusy) return LanguagePreferenceOperationResult.busy;
    if (state.language == language &&
        state.phase == LanguagePreferencePhase.ready) {
      return LanguagePreferenceOperationResult.success;
    }
    return _save(language);
  }

  Future<void> _load() async {
    state = const LanguagePreferenceState.loading();
    try {
      final language = await _repository.read();
      _retryLanguage = null;
      state = LanguagePreferenceState.ready(language);
    } on Object {
      _retryLanguage = null;
      state = const LanguagePreferenceState.error(
        kind: LanguagePreferenceErrorKind.read,
        language: AppLanguage.english,
      );
    }
  }

  Future<LanguagePreferenceOperationResult> _save(
    AppLanguage language,
  ) async {
    if (state.isBusy) return LanguagePreferenceOperationResult.busy;
    final previous = state.language;
    _retryLanguage = language;
    state = LanguagePreferenceState.saving(
      language: previous,
      pendingLanguage: language,
    );
    try {
      await _repository.write(language);
      _retryLanguage = null;
      state = LanguagePreferenceState.ready(language);
      return LanguagePreferenceOperationResult.success;
    } on Object {
      state = LanguagePreferenceState.error(
        kind: LanguagePreferenceErrorKind.write,
        language: previous,
        pendingLanguage: language,
      );
      return LanguagePreferenceOperationResult.failed;
    }
  }
}
