import '../domain/app_language.dart';

enum LanguagePreferencePhase { loading, ready, saving, error }

enum LanguagePreferenceErrorKind { read, write }

final class LanguagePreferenceState {
  const LanguagePreferenceState({
    required this.phase,
    required this.language,
    required this.errorKind,
    this.pendingLanguage,
  });

  const LanguagePreferenceState.loading()
    : this(
        phase: LanguagePreferencePhase.loading,
        language: AppLanguage.english,
        errorKind: null,
      );

  const LanguagePreferenceState.ready(AppLanguage language)
    : this(
        phase: LanguagePreferencePhase.ready,
        language: language,
        errorKind: null,
      );

  const LanguagePreferenceState.saving({
    required AppLanguage language,
    required AppLanguage pendingLanguage,
  }) : this(
         phase: LanguagePreferencePhase.saving,
         language: language,
         errorKind: null,
         pendingLanguage: pendingLanguage,
       );

  const LanguagePreferenceState.error({
    required LanguagePreferenceErrorKind kind,
    required this.language,
    this.pendingLanguage,
  }) : phase = LanguagePreferencePhase.error,
       errorKind = kind;

  final LanguagePreferencePhase phase;
  final AppLanguage language;
  final LanguagePreferenceErrorKind? errorKind;
  final AppLanguage? pendingLanguage;

  bool get isBusy =>
      phase == LanguagePreferencePhase.loading ||
      phase == LanguagePreferencePhase.saving;
}
