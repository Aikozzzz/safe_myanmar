import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sos_preferences.dart';
import 'sos_preferences_state.dart';
import 'providers.dart';

enum SosPreferencesOperationResult { success, busy, failed }

final class SosPreferencesController extends Notifier<SosPreferencesState> {
  late SosPreferencesStore _store;
  SosPreferences? _retryPreferences;

  @override
  SosPreferencesState build() {
    _store = ref.watch(sosPreferencesStoreProvider);
    unawaited(_load());
    return const SosPreferencesState.loading();
  }

  Future<void> reload() => _load();

  Future<SosPreferencesOperationResult> setIncludeLocation(bool value) =>
      setPreferences(state.preferences.copyWith(includeLocation: value));

  Future<SosPreferencesOperationResult> setShareNearbySos(bool value) =>
      setPreferences(state.preferences.copyWith(shareNearbySos: value));

  Future<SosPreferencesOperationResult> setPreferences(
    SosPreferences preferences,
  ) async {
    if (state.isBusy) return SosPreferencesOperationResult.busy;
    return _save(preferences);
  }

  Future<void> retry() async {
    final pending = _retryPreferences;
    if (pending != null) {
      await _save(pending);
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    state = SosPreferencesState.loading();
    try {
      final preferences = await _store.read();
      if (!ref.mounted) return;
      _retryPreferences = null;
      state = SosPreferencesState.ready(preferences);
    } on Object {
      if (!ref.mounted) return;
      state = SosPreferencesState(
        phase: SosPreferencesPhase.error,
        preferences: state.preferences,
        error: 'read_failed',
      );
    }
  }

  Future<SosPreferencesOperationResult> _save(
    SosPreferences preferences,
  ) async {
    if (state.isBusy) return SosPreferencesOperationResult.busy;
    final previous = state.preferences;
    _retryPreferences = preferences;
    state = SosPreferencesState(
      phase: SosPreferencesPhase.saving,
      preferences: previous,
      pendingPreferences: preferences,
    );
    try {
      await _store.write(preferences);
      if (!ref.mounted) return SosPreferencesOperationResult.failed;
      _retryPreferences = null;
      state = SosPreferencesState.ready(preferences);
      return SosPreferencesOperationResult.success;
    } on Object {
      if (!ref.mounted) return SosPreferencesOperationResult.failed;
      state = SosPreferencesState(
        phase: SosPreferencesPhase.error,
        preferences: previous,
        pendingPreferences: preferences,
        error: 'write_failed',
      );
      return SosPreferencesOperationResult.failed;
    }
  }
}
