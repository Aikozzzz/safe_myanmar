import 'package:mobile/features/settings/domain/app_language.dart';

final class FakeLanguagePreferenceRepository
    implements LanguagePreferenceRepository {
  AppLanguage language = AppLanguage.english;
  Object? readError;
  Object? writeError;
  int reads = 0;
  int writes = 0;
  final writtenLanguages = <AppLanguage>[];

  @override
  Future<AppLanguage> read() async {
    reads++;
    final error = readError;
    if (error != null) throw error;
    return language;
  }

  @override
  Future<void> write(AppLanguage value) async {
    writes++;
    final error = writeError;
    if (error != null) throw error;
    language = value;
    writtenLanguages.add(value);
  }
}
