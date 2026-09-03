import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../location/application/foreground_location_state.dart';
import '../../location/application/providers.dart';
import '../../sos/application/providers.dart';
import '../../sos/application/sos_ble_state.dart';
import '../../sos/application/sos_preferences_controller.dart';
import '../application/language_preference_state.dart';
import '../application/providers.dart';
import '../domain/app_language.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreSavedLocationPreference();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final preferencesState = ref.watch(sosPreferencesControllerProvider);
    final preferences = preferencesState.preferences;
    final bleState = ref.watch(sosBleControllerProvider);
    final locationState = ref.watch(foregroundLocationControllerProvider);

    ref.listen(sosPreferencesControllerProvider, (previous, next) {
      if (next.preferences.includeLocation &&
          previous?.preferences.includeLocation != true) {
        unawaited(
          ref
              .read(foregroundLocationControllerProvider.notifier)
              .restoreGrantedLocation(),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              strings.settingsDescription,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _LanguagePreferenceCard(),
            const SizedBox(height: 16),
            _SettingsSection(
              title: strings.settingsSosTitle,
              description: strings.settingsSosDescription,
              children: [
                SwitchListTile(
                  key: const ValueKey('settings-include-location'),
                  contentPadding: EdgeInsets.zero,
                  value: preferences.includeLocation,
                  onChanged:
                      preferencesState.isBusy ||
                          locationState.phase ==
                              ForegroundLocationPhase.requesting
                      ? null
                      : (value) => unawaited(_setLocationSharing(value)),
                  title: Text(strings.sosLocationSharingTitle),
                  subtitle: Text(strings.sosLocationSharingDescription),
                  secondary: const Icon(Icons.location_on_outlined),
                ),
                _settingDivider(),
                SwitchListTile(
                  key: const ValueKey('settings-share-nearby'),
                  contentPadding: EdgeInsets.zero,
                  value: preferences.shareNearbySos,
                  onChanged:
                      preferencesState.isBusy || bleState.supported == false
                      ? null
                      : (value) => unawaited(_setNearbySharing(value)),
                  title: Text(strings.sosBluetoothShareTitle),
                  subtitle: Text(strings.sosBluetoothShareDescription),
                  secondary: const Icon(Icons.bluetooth),
                ),
                _settingDivider(),
                SwitchListTile(
                  key: const ValueKey('settings-receive-nearby'),
                  contentPadding: EdgeInsets.zero,
                  value: preferences.receiveNearbySos,
                  onChanged:
                      preferencesState.isBusy || bleState.supported == false
                      ? null
                      : (value) => unawaited(_setNearbyReceiving(value)),
                  title: Text(strings.sosBluetoothReceiveTitle),
                  subtitle: Text(strings.sosBluetoothReceiveDescription),
                  secondary: const Icon(Icons.notifications_active_outlined),
                ),
                _settingDivider(),
                SwitchListTile(
                  key: const ValueKey('settings-relay-nearby'),
                  contentPadding: EdgeInsets.zero,
                  value: preferences.relayNearbySos,
                  onChanged:
                      preferencesState.isBusy || bleState.supported == false
                      ? null
                      : (value) => unawaited(_setRelay(value)),
                  title: Text(strings.sosBluetoothRelayTitle),
                  subtitle: Text(strings.sosBluetoothRelayDescription),
                  secondary: const Icon(Icons.repeat),
                ),
                _settingDivider(),
                SwitchListTile(
                  key: const ValueKey('settings-sound-alert'),
                  contentPadding: EdgeInsets.zero,
                  value: preferences.soundEnabled,
                  onChanged: preferencesState.isBusy
                      ? null
                      : (value) => unawaited(_setSound(value)),
                  title: Text(strings.sosBluetoothSoundTitle),
                  subtitle: Text(strings.sosBluetoothSoundDescription),
                  secondary: const Icon(Icons.volume_up_outlined),
                ),
                _settingDivider(),
                SwitchListTile(
                  key: const ValueKey('settings-background-receive'),
                  contentPadding: EdgeInsets.zero,
                  value: preferences.backgroundReceive,
                  onChanged:
                      preferencesState.isBusy || bleState.supported == false
                      ? null
                      : (value) => unawaited(_setBackgroundReceiving(value)),
                  title: Text(strings.sosBluetoothBackgroundReceiveTitle),
                  subtitle: Text(
                    strings.sosBluetoothBackgroundReceiveDescription,
                  ),
                  secondary: const Icon(Icons.notifications_none_outlined),
                ),
              ],
            ),
            if (_showLocationStatus(
              locationState,
              preferences.includeLocation,
            )) ...[
              const SizedBox(height: 16),
              _LocationPermissionStatus(
                state: locationState,
                onOpenSettings: _openLocationSettings,
              ),
            ],
            if (bleState.error != null || bleState.supported == false) ...[
              const SizedBox(height: 16),
              _BleSettingsStatus(
                state: bleState,
                onOpenSettings: _openSettings,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _restoreSavedLocationPreference() async {
    if (!ref
        .read(sosPreferencesControllerProvider)
        .preferences
        .includeLocation) {
      return;
    }
    await ref
        .read(foregroundLocationControllerProvider.notifier)
        .restoreGrantedLocation();
  }

  Future<void> _setLocationSharing(bool enabled) async {
    final strings = AppLocalizations.of(context)!;
    final preferences = ref.read(sosPreferencesControllerProvider.notifier);
    if (!enabled) {
      await _showPreferenceResult(await preferences.setIncludeLocation(false));
      return;
    }
    await ref
        .read(foregroundLocationControllerProvider.notifier)
        .requestLocation(confirmed: true);
    if (!mounted) return;
    if (ref.read(foregroundLocationControllerProvider).location == null) {
      _showNotice(strings.sosLocationSharingUnavailable);
      return;
    }
    await _showPreferenceResult(await preferences.setIncludeLocation(true));
  }

  Future<void> _setNearbySharing(bool enabled) async {
    await ref
        .read(sosBleControllerProvider.notifier)
        .setSharingEnabled(enabled);
  }

  Future<void> _setNearbyReceiving(bool enabled) async {
    await ref.read(sosBleControllerProvider.notifier).setListening(enabled);
  }

  Future<void> _setRelay(bool enabled) async {
    await ref.read(sosBleControllerProvider.notifier).setRelayEnabled(enabled);
  }

  Future<void> _setSound(bool enabled) async {
    await ref.read(sosBleControllerProvider.notifier).setSoundEnabled(enabled);
  }

  Future<void> _setBackgroundReceiving(bool enabled) async {
    await ref
        .read(sosBleControllerProvider.notifier)
        .setBackgroundListening(enabled);
  }

  Future<void> _showPreferenceResult(
    SosPreferencesOperationResult result,
  ) async {
    if (!mounted || result == SosPreferencesOperationResult.success) return;
    _showNotice(AppLocalizations.of(context)!.sosSettingsSaveFailed);
  }

  Future<void> _openSettings() async {
    await ref.read(sosBlePlatformProvider).openAppSettings();
  }

  Future<void> _openLocationSettings() async {
    final opened = await ref
        .read(foregroundLocationControllerProvider.notifier)
        .openAppSettings();
    if (!opened && mounted) {
      _showNotice(AppLocalizations.of(context)!.couldNotOpenLocationSettings);
    }
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _showLocationStatus(
    ForegroundLocationState state,
    bool preferenceEnabled,
  ) => preferenceEnabled && state.phase != ForegroundLocationPhase.notRequested;
}

Widget _settingDivider() => const Divider(height: 1);

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(description),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

class _LanguagePreferenceCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final state = ref.watch(languagePreferenceControllerProvider);
    final controller = ref.read(languagePreferenceControllerProvider.notifier);
    final errorKind = state.errorKind;

    return Semantics(
      container: true,
      key: const ValueKey('language-preference-card'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.languageSettingsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(strings.languageSettingsDescription),
              const SizedBox(height: 12),
              Semantics(
                label: strings.languageSettingsTitle,
                child: DropdownButtonFormField<AppLanguage>(
                  key: ValueKey('language-${state.language.code}'),
                  initialValue: state.language,
                  decoration: const InputDecoration(),
                  items: [
                    DropdownMenuItem(
                      value: AppLanguage.english,
                      child: Text(strings.languageEnglish),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.burmese,
                      child: Text(strings.languageBurmese),
                    ),
                  ],
                  onChanged: state.isBusy
                      ? null
                      : (value) {
                          if (value != null) {
                            unawaited(controller.setLanguage(value));
                          }
                        },
                ),
              ),
              if (state.phase == LanguagePreferencePhase.saving) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  label: strings.languageSaving,
                  child: const LinearProgressIndicator(),
                ),
              ],
              if (errorKind != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        errorKind == LanguagePreferenceErrorKind.read
                            ? strings.languageReadErrorTitle
                            : strings.languageWriteErrorTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        errorKind == LanguagePreferenceErrorKind.read
                            ? strings.languageReadErrorDescription
                            : strings.languageWriteErrorDescription,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: state.isBusy ? null : controller.retry,
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.retry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationPermissionStatus extends StatelessWidget {
  const _LocationPermissionStatus({
    required this.state,
    required this.onOpenSettings,
  });

  final ForegroundLocationState state;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final content = switch (state.phase) {
      ForegroundLocationPhase.requesting =>
        strings.locationRequestingDescription,
      ForegroundLocationPhase.preciseAvailable =>
        strings.preciseLocationDescription,
      ForegroundLocationPhase.approximateAvailable =>
        strings.approximateLocationDescription,
      ForegroundLocationPhase.denied =>
        strings.locationPermissionDeniedDescription,
      ForegroundLocationPhase.permanentlyDenied =>
        strings.locationPermissionPermanentlyDeniedDescription,
      ForegroundLocationPhase.serviceDisabled =>
        strings.locationServicesDisabledDescription,
      ForegroundLocationPhase.liveUnavailableWithLastKnown =>
        strings.lastKnownLocationDescription,
      ForegroundLocationPhase.recoverableError =>
        strings.locationRecoverableErrorDescription,
      ForegroundLocationPhase.notRequested ||
      ForegroundLocationPhase.permissionExplanationRequired => null,
    };
    if (content == null) return const SizedBox.shrink();
    final title = switch (state.phase) {
      ForegroundLocationPhase.requesting => strings.locationRequestingTitle,
      ForegroundLocationPhase.preciseAvailable =>
        strings.preciseLocationAvailable,
      ForegroundLocationPhase.approximateAvailable =>
        strings.approximateLocationAvailable,
      ForegroundLocationPhase.denied => strings.locationPermissionDenied,
      ForegroundLocationPhase.permanentlyDenied =>
        strings.locationPermissionPermanentlyDenied,
      ForegroundLocationPhase.serviceDisabled =>
        strings.locationServicesDisabled,
      ForegroundLocationPhase.liveUnavailableWithLastKnown =>
        strings.lastKnownLocation,
      ForegroundLocationPhase.recoverableError =>
        strings.locationRecoverableError,
      ForegroundLocationPhase.notRequested ||
      ForegroundLocationPhase.permissionExplanationRequired => '',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(content),
            if (state.phase == ForegroundLocationPhase.permanentlyDenied) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
                label: Text(strings.openAppSettings),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BleSettingsStatus extends StatelessWidget {
  const _BleSettingsStatus({required this.state, required this.onOpenSettings});

  final SosBleState state;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final message = state.supported == false
        ? strings.sosBluetoothUnavailable
        : state.error == 'permission_denied' ||
              state.error == 'notification_denied'
        ? strings.sosBluetoothPermissionRequired
        : state.error == 'bluetooth_disabled'
        ? strings.sosBluetoothDisabled
        : strings.sosBluetoothOperationFailed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (state.error == 'permission_denied' ||
                state.error == 'notification_denied' ||
                state.error == 'bluetooth_disabled') ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
                label: Text(strings.openAppSettings),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
