import 'package:mobile/features/sos/data/sos_preferences.dart';

final class FakeSosPreferencesStore implements SosPreferencesStore {
  SosPreferences preferences = const SosPreferences();
  Object? readError;
  Object? writeError;
  int reads = 0;
  int writes = 0;

  @override
  Future<SosPreferences> read() async {
    reads++;
    if (readError case final error?) throw error;
    return preferences;
  }

  @override
  Future<void> write(SosPreferences value) async {
    writes++;
    if (writeError case final error?) throw error;
    preferences = value;
  }
}
