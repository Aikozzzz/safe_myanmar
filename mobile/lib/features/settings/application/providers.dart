import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/application/providers.dart';
import '../data/secure_language_preference_repository.dart';
import '../domain/app_language.dart';
import 'language_preference_controller.dart';
import 'language_preference_state.dart';

final languagePreferenceRepositoryProvider =
    Provider<LanguagePreferenceRepository>(
      (ref) => SecureLanguagePreferenceRepository(
        ref.watch(secureStorageDriverProvider),
      ),
    );

final languagePreferenceControllerProvider =
    NotifierProvider<LanguagePreferenceController, LanguagePreferenceState>(
      LanguagePreferenceController.new,
    );
