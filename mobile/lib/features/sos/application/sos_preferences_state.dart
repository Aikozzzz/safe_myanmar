import '../data/sos_preferences.dart';

enum SosPreferencesPhase { loading, ready, saving, error }

final class SosPreferencesState {
  const SosPreferencesState({
    required this.phase,
    required this.preferences,
    this.pendingPreferences,
    this.error,
  });

  const SosPreferencesState.loading()
    : this(
        phase: SosPreferencesPhase.loading,
        preferences: const SosPreferences(),
      );

  const SosPreferencesState.ready(SosPreferences preferences)
    : this(phase: SosPreferencesPhase.ready, preferences: preferences);

  final SosPreferencesPhase phase;
  final SosPreferences preferences;
  final SosPreferences? pendingPreferences;
  final String? error;

  bool get isBusy =>
      phase == SosPreferencesPhase.loading ||
      phase == SosPreferencesPhase.saving;
}
