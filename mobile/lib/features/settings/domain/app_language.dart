enum AppLanguage {
  english('en'),
  burmese('my');

  const AppLanguage(this.code);

  final String code;

  bool get isBurmese => this == AppLanguage.burmese;

  static AppLanguage fromStoredValue(String? value) => switch (value) {
    'my' => AppLanguage.burmese,
    _ => AppLanguage.english,
  };
}

abstract interface class LanguagePreferenceRepository {
  Future<AppLanguage> read();

  Future<void> write(AppLanguage language);
}
