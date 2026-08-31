import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../location/application/foreground_location_state.dart';
import '../../location/application/providers.dart';
import '../../profile/application/providers.dart';
import '../../profile/domain/local_profile.dart';
import '../application/providers.dart';
import '../application/sos_draft_queue_controller.dart';
import '../application/sos_draft_queue_state.dart';
import '../data/native_sms_sender.dart';
import '../application/sos_ble_state.dart';
import '../domain/sos_ble.dart';
import '../domain/sos_draft.dart';
import 'hold_to_confirm.dart';
import 'sos_message_builder.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  final _messageController = TextEditingController();
  var _shareNearbySos = false;
  var _includeLocation = false;
  var _sendingSms = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final profileState = ref.watch(localProfileControllerProvider);
    final queueState = ref.watch(sosDraftQueueControllerProvider);
    final bleState = ref.watch(sosBleControllerProvider);
    final locationState = ref.watch(foregroundLocationControllerProvider);
    final profile = profileState.profile;
    final selectedContacts =
        profile?.contacts.where((contact) => contact.selectedForSos).toList() ??
        const <EmergencyContact>[];
    final location = _includeLocation ? _snapshotLocation(locationState) : null;
    final message = _messageController.text.trim();
    final body = buildSosMessage(
      strings: strings,
      profileName: profile?.displayName ?? '',
      location: location,
      userMessage: message,
    );
    final canPrepare =
        profile != null &&
        (selectedContacts.isNotEmpty || _shareNearbySos) &&
        !queueState.isBusy;
    final bleSharingReady = !_shareNearbySos || bleState.supported != false;
    final readinessReady =
        canPrepare &&
        bleSharingReady &&
        (!_includeLocation || location != null);

    return Scaffold(
      appBar: AppBar(title: Text(strings.sosSetupTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              strings.sosSetupDescription,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _ReadinessSummary(
              setupTitle: strings.sosSetupTitle,
              readyTitle: strings.sosReadinessReady,
              needsContactTitle: strings.sosReadinessNeedsContact,
              locationUnavailableTitle: strings.sosReadinessLocationUnavailable,
              hasRecipients: selectedContacts.isNotEmpty,
              nearbySharingEnabled: _shareNearbySos,
              locationSharingEnabled: _includeLocation,
              locationAvailable: location != null,
              bleAvailable: bleState.supported != false,
              queueBusy: queueState.isBusy,
              ready: readinessReady,
            ),
            const SizedBox(height: 16),
            if (queueState.errorKind != null) ...[
              _QueueErrorCard(
                state: queueState,
                onRetry: () =>
                    ref.read(sosDraftQueueControllerProvider.notifier).retry(),
                onReset: () => _confirmQueueReset(strings),
              ),
              const SizedBox(height: 16),
            ],
            _RecipientsCard(
              contacts: selectedContacts,
              onManage: () => context.go('/more/contacts'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLength: maxSosMessageLength,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                labelText: strings.sosOptionalMessageLabel,
                hintText: strings.sosOptionalMessageHint,
                prefixIcon: const Icon(Icons.message_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                value: _includeLocation,
                onChanged: (value) => unawaited(_setLocationSharing(value)),
                title: Text(strings.sosLocationSharingTitle),
                subtitle: Text(strings.sosLocationSharingDescription),
                secondary: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 8),
            _NearbySosCard(
              sharingEnabled: _shareNearbySos,
              onSharingChanged: (value) =>
                  setState(() => _shareNearbySos = value),
              state: bleState,
              onListeningChanged: (value) => ref
                  .read(sosBleControllerProvider.notifier)
                  .setListening(value),
              onOpenAppSettings: () => unawaited(_openSosAppSettings()),
              onRelayChanged: (value) => ref
                  .read(sosBleControllerProvider.notifier)
                  .setRelayEnabled(value),
              onSoundChanged: (value) => ref
                  .read(sosBleControllerProvider.notifier)
                  .setSoundEnabled(value),
              onStopBroadcast: () =>
                  ref.read(sosBleControllerProvider.notifier).stopBroadcast(),
              onDismissEvent: (eventId) => ref
                  .read(sosBleControllerProvider.notifier)
                  .dismissNearbyEvent(eventId),
            ),
            const SizedBox(height: 16),
            _BackgroundSosReceiverCard(
              state: bleState,
              onChanged: (value) => ref
                  .read(sosBleControllerProvider.notifier)
                  .setBackgroundListening(value),
            ),
            const SizedBox(height: 16),
            _SharedDataPreview(
              profile: profile,
              location: location,
              body: body,
            ),
            const SizedBox(height: 16),
            _DisclosureCard(description: strings.sosDirectSmsDisclosure),
            const SizedBox(height: 16),
            HoldToConfirm(
              enabled: canPrepare,
              label: strings.sosHoldToOpen,
              progressLabel: strings.sosHoldProgress,
              cancelledLabel: strings.sosHoldCancelled,
              semanticsHint: strings.sosHoldSemanticsHint,
              accessibleLabel: strings.sosAccessibleConfirmation,
              onConfirmed: _prepareAndOpen,
              onAccessibleConfirm: _accessibleConfirmation,
            ),
            const SizedBox(height: 24),
            Text(
              strings.sosDraftQueueHeading,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (queueState.phase == SosDraftQueuePhase.loading)
              Semantics(
                label: strings.sosQueueLoading,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (queueState.drafts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(strings.sosDraftQueueEmpty),
                ),
              )
            else
              for (final draft in queueState.drafts) ...[
                _DraftCard(
                  draft: draft,
                  enabled: !queueState.isBusy,
                  onOpen: () => _confirmOpenDraft(draft),
                  onCancel: () => _confirmCancelDraft(draft),
                  onRemove: () => _confirmRemoveDraft(draft),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _accessibleConfirmation() async {
    final strings = AppLocalizations.of(context)!;
    final firstConfirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(strings.sosConfirmPreviewTitle),
        content: Text(strings.sosConfirmPreviewDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.sosContinue),
          ),
        ],
      ),
    );
    if (firstConfirmation != true || !mounted) return;
    final secondConfirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(strings.sosConfirmSmsTitle),
        content: Text(strings.sosConfirmSmsDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.sosNotNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.sosSendSms),
          ),
        ],
      ),
    );
    if (secondConfirmation == true && mounted) await _prepareAndOpen();
  }

  Future<void> _prepareAndOpen() async {
    final strings = AppLocalizations.of(context)!;
    final profile = ref.read(localProfileControllerProvider).profile;
    if (profile == null) return;
    final contacts = profile.contacts
        .where((contact) => contact.selectedForSos)
        .toList();
    if (contacts.isEmpty && !_shareNearbySos) return;
    SosLocationSnapshot? location;
    if (_includeLocation) {
      await ref
          .read(foregroundLocationControllerProvider.notifier)
          .requestLocation(confirmed: true);
      if (!mounted) return;
      location = _snapshotLocation(
        ref.read(foregroundLocationControllerProvider),
      );
      if (location == null) {
        setState(() => _includeLocation = false);
        if (!await _confirmContinueWithoutLocation(strings)) return;
      }
    }
    final body = buildSosMessage(
      strings: strings,
      profileName: profile.displayName,
      location: location,
      userMessage: _messageController.text,
    );
    final result = await ref
        .read(sosDraftQueueControllerProvider.notifier)
        .prepare(
          SosDraftPreparation(
            recipients: [
              for (final contact in contacts)
                SosRecipientSnapshot(
                  contactId: contact.id,
                  name: contact.name,
                  phoneNumber: contact.phoneNumber,
                ),
            ],
            message: _messageController.text,
            location: location,
            profileName: profile.displayName,
            body: body,
            allowNoRecipients: _shareNearbySos,
          ),
        );
    if (!mounted) return;
    if (result.result != SosDraftOperationResult.success ||
        result.draft == null) {
      _showNotice(
        result.result == SosDraftOperationResult.maximumDrafts
            ? strings.sosMaximumDrafts
            : strings.sosDraftSaveFailed,
      );
      return;
    }
    setState(() => _includeLocation = false);
    if (_shareNearbySos) {
      await ref
          .read(sosBleControllerProvider.notifier)
          .broadcast(result.draft!);
      if (contacts.isEmpty &&
          ref.read(sosBleControllerProvider).broadcastStatus !=
              SosBleBroadcastStatus.active) {
        if (mounted) _showNotice(strings.sosBluetoothBroadcastFailed);
        return;
      }
    }
    if (contacts.isNotEmpty) {
      await _sendDraft(result.draft!);
    } else if (mounted) {
      _showNotice(strings.sosBluetoothBroadcastStarted);
    }
  }

  Future<void> _setLocationSharing(bool enabled) async {
    if (!enabled) {
      if (mounted) setState(() => _includeLocation = false);
      return;
    }
    await ref
        .read(foregroundLocationControllerProvider.notifier)
        .requestLocation(confirmed: true);
    if (!mounted) return;
    final location = _snapshotLocation(
      ref.read(foregroundLocationControllerProvider),
    );
    if (location == null) {
      setState(() => _includeLocation = false);
      _showNotice(AppLocalizations.of(context)!.sosLocationSharingUnavailable);
      return;
    }
    setState(() => _includeLocation = true);
  }

  Future<bool> _confirmContinueWithoutLocation(AppLocalizations strings) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.sosLocationSharingUnavailableTitle),
        content: Text(strings.sosLocationSharingUnavailableDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.sosContinueWithoutLocation),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _sendDraft(SosDraft draft) async {
    if (_sendingSms) return;
    _sendingSms = true;
    final strings = AppLocalizations.of(context)!;
    try {
      final sim = await _chooseSim();
      if (sim == null) return;
      final queue = ref.read(sosDraftQueueControllerProvider.notifier);
      await queue.setSmsResult(
        draft.id,
        status: SosDraftStatus.smsSending,
        attemptId: null,
        confirmedParts: 0,
        totalParts: 0,
      );
      final sender = ref.read(nativeSmsSenderProvider);
      if (!await sender.requestPermission()) {
        await queue.setSmsResult(
          draft.id,
          status: SosDraftStatus.smsFailed,
          attemptId: null,
          confirmedParts: 0,
          totalParts: 0,
        );
        if (mounted) _showNotice(strings.sosSmsPermissionDenied);
        return;
      }
      final result = await sender.send(
        recipients: draft.recipients
            .map((recipient) => recipient.phoneNumber)
            .toList(),
        body: draft.body,
        subscriptionId: sim.subscriptionId,
      );
      final draftStatus = switch (result.status) {
        NativeSmsSendStatus.sent => SosDraftStatus.smsSent,
        NativeSmsSendStatus.partial => SosDraftStatus.smsPartial,
        NativeSmsSendStatus.unknown => SosDraftStatus.smsUnknown,
        NativeSmsSendStatus.permissionDenied ||
        NativeSmsSendStatus.unavailable ||
        NativeSmsSendStatus.failed => SosDraftStatus.smsFailed,
      };
      await queue.setSmsResult(
        draft.id,
        status: draftStatus,
        attemptId: result.attemptId,
        confirmedParts: result.confirmedParts,
        totalParts: result.totalParts,
      );
      if (!mounted) return;
      _showNotice(
        result.status == NativeSmsSendStatus.sent
            ? strings.sosSmsSentNotice
            : result.status == NativeSmsSendStatus.partial ||
                  result.status == NativeSmsSendStatus.unknown
            ? strings.sosSmsUncertainNotice
            : strings.sosSmsFailedNotice,
      );
    } finally {
      _sendingSms = false;
    }
  }

  Future<SmsSim?> _chooseSim() async {
    final strings = AppLocalizations.of(context)!;
    final sender = ref.read(nativeSmsSenderProvider);
    final sims = await sender.listSims();
    if (!mounted) return null;
    if (sims.isEmpty) {
      _showNotice(strings.sosSimUnavailable);
      return null;
    }
    final preference = ref.read(sosSimPreferenceStoreProvider);
    String? preferredId;
    try {
      preferredId = await preference.readPreferredSubscriptionId();
    } on Object {
      preferredId = null;
    }
    if (!mounted) return null;
    final preferred = sims.where(
      (sim) => sim.subscriptionId.toString() == preferredId,
    );
    final initial = preferred.isNotEmpty ? preferred.first : sims.first;
    if (sims.length == 1) {
      return initial;
    }
    final selection = await showDialog<_SmsSimSelection>(
      context: context,
      builder: (dialogContext) {
        var selectedId = initial.subscriptionId;
        var remember = preferred.isNotEmpty;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(strings.sosChooseSimTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(strings.sosChooseSimDescription),
                const SizedBox(height: 12),
                RadioGroup<int>(
                  groupValue: selectedId,
                  onChanged: (value) {
                    if (value != null) setState(() => selectedId = value);
                  },
                  child: Column(
                    children: [
                      for (final sim in sims)
                        RadioListTile<int>(
                          value: sim.subscriptionId,
                          title: Text(sim.displayLabel),
                        ),
                    ],
                  ),
                ),
                CheckboxListTile(
                  value: remember,
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.sosRememberSim),
                  onChanged: (value) =>
                      setState(() => remember = value ?? false),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _SmsSimSelection(selectedId, remember),
                ),
                child: Text(strings.sosSendUsingSim),
              ),
            ],
          ),
        );
      },
    );
    if (selection == null) return null;
    try {
      await preference.writePreferredSubscriptionId(
        selection.remember ? selection.subscriptionId.toString() : null,
      );
    } on Object {
      // Sending remains available when the optional preference cannot persist.
    }
    return sims.firstWhere(
      (sim) => sim.subscriptionId == selection.subscriptionId,
    );
  }

  Future<void> _confirmOpenDraft(SosDraft draft) async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await _confirmationDialog(
      title: strings.sosRetrySmsTitle,
      description: [
        strings.sosRetrySmsDescription,
        if (draft.status == SosDraftStatus.smsPartial ||
            draft.status == SosDraftStatus.smsUnknown)
          strings.sosRetrySmsUncertainDescription,
        draft.body,
      ].join('\n\n'),
      confirmLabel: strings.sosSendSms,
    );
    if (confirmed && mounted) {
      await _sendDraft(draft);
    }
  }

  Future<void> _confirmCancelDraft(SosDraft draft) async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await _confirmationDialog(
      title: strings.sosCancelDraftTitle,
      description: strings.sosCancelDraftDescription,
      confirmLabel: strings.sosCancelDraft,
    );
    if (confirmed && mounted) {
      await ref
          .read(sosDraftQueueControllerProvider.notifier)
          .setStatus(draft.id, SosDraftStatus.cancelled);
    }
  }

  Future<void> _confirmRemoveDraft(SosDraft draft) async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await _confirmationDialog(
      title: strings.sosRemoveDraftTitle,
      description: strings.sosRemoveDraftDescription,
      confirmLabel: strings.sosRemoveDraft,
      destructive: true,
    );
    if (confirmed && mounted) {
      await ref.read(sosDraftQueueControllerProvider.notifier).remove(draft.id);
    }
  }

  Future<void> _confirmQueueReset(AppLocalizations strings) async {
    final confirmed = await _confirmationDialog(
      title: strings.sosResetQueueTitle,
      description: strings.sosResetQueueDescription,
      confirmLabel: strings.sosResetQueue,
      destructive: true,
    );
    if (confirmed && mounted) {
      await ref
          .read(sosDraftQueueControllerProvider.notifier)
          .resetUnreadableData();
    }
  }

  Future<bool> _confirmationDialog({
    required String title,
    required String description,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final strings = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: Text(title),
            content: Text(description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      )
                    : null,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSosAppSettings() async {
    final opened = await ref.read(sosBlePlatformProvider).openAppSettings();
    if (!opened && mounted) {
      _showNotice(AppLocalizations.of(context)!.sosBluetoothPermissionSettings);
    }
  }
}

final class _SmsSimSelection {
  const _SmsSimSelection(this.subscriptionId, this.remember);

  final int subscriptionId;
  final bool remember;
}

class _RecipientsCard extends StatelessWidget {
  const _RecipientsCard({required this.contacts, required this.onManage});

  final List<EmergencyContact> contacts;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.sosRecipientsHeading,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (contacts.isEmpty) ...[
              Text(
                strings.sosNoRecipientsTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(strings.sosNoRecipientsDescription),
            ] else
              for (final contact in contacts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    strings.sosRecipientPreview(
                      contact.name,
                      contact.phoneNumber,
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.contact_phone_outlined),
              label: Text(strings.sosManageContacts),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessSummary extends StatelessWidget {
  const _ReadinessSummary({
    required this.setupTitle,
    required this.readyTitle,
    required this.needsContactTitle,
    required this.locationUnavailableTitle,
    required this.hasRecipients,
    required this.nearbySharingEnabled,
    required this.locationSharingEnabled,
    required this.locationAvailable,
    required this.bleAvailable,
    required this.queueBusy,
    required this.ready,
  });

  final String setupTitle;
  final String readyTitle;
  final String needsContactTitle;
  final String locationUnavailableTitle;
  final bool hasRecipients;
  final bool nearbySharingEnabled;
  final bool locationSharingEnabled;
  final bool locationAvailable;
  final bool bleAvailable;
  final bool queueBusy;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    late final IconData icon;
    late final String title;
    late final String description;

    if (queueBusy) {
      icon = Icons.hourglass_top_outlined;
      title = strings.sosQueueLoading;
      description = strings.sosDraftCreatedWhenConfirmed;
    } else if (!hasRecipients && !nearbySharingEnabled) {
      icon = Icons.person_search_outlined;
      title = needsContactTitle;
      description = strings.sosNoRecipientsDescription;
    } else if (locationSharingEnabled && !locationAvailable) {
      icon = Icons.location_off_outlined;
      title = locationUnavailableTitle;
      description = strings.sosLocationSharingUnavailableDescription;
    } else if (nearbySharingEnabled && !bleAvailable) {
      icon = Icons.bluetooth_disabled_outlined;
      title = strings.sosBluetoothUnavailable;
      description = strings.sosBluetoothOperationFailed;
    } else if (ready) {
      icon = Icons.check_circle_outline;
      title = readyTitle;
      description = strings.sosHoldToOpen;
    } else {
      icon = Icons.info_outline;
      title = needsContactTitle;
      description = strings.sosNoRecipientsDescription;
    }

    final colors = Theme.of(context).colorScheme;
    final displayTitle = '$setupTitle: $title';
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$displayTitle $description',
      child: Card(
        key: const Key('sos-readiness-summary'),
        color: ready ? colors.primaryContainer : colors.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: ready ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SharedDataPreview extends StatelessWidget {
  const _SharedDataPreview({
    required this.profile,
    required this.location,
    required this.body,
  });

  final LocalProfile? profile;
  final SosLocationSnapshot? location;
  final String body;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.sosSharedDataHeading,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SelectableText(body),
            const Divider(height: 28),
            Text(
              strings.sosStoredDataHeading,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              profile == null || profile!.displayName.trim().isEmpty
                  ? strings.sosProfileNameUnavailable
                  : strings.sosProfileNamePreview(profile!.displayName),
            ),
            const SizedBox(height: 4),
            Text(_locationPreview(context, strings, location)),
            const SizedBox(height: 4),
            Text(strings.sosDraftCreatedWhenConfirmed),
          ],
        ),
      ),
    );
  }
}

class _DisclosureCard extends StatelessWidget {
  const _DisclosureCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 12),
          Expanded(child: Text(description)),
        ],
      ),
    ),
  );
}

class _BackgroundSosReceiverCard extends StatelessWidget {
  const _BackgroundSosReceiverCard({
    required this.state,
    required this.onChanged,
  });

  final SosBleState state;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: state.backgroundListening,
              onChanged: state.supported == true ? onChanged : null,
              title: Text(strings.sosBluetoothBackgroundReceiveTitle),
              subtitle: Text(strings.sosBluetoothBackgroundReceiveDescription),
              secondary: const Icon(Icons.notifications_none_outlined),
            ),
            if (state.error == 'background_scan_failed') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(strings.sosBluetoothOperationFailed),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NearbySosCard extends StatelessWidget {
  const _NearbySosCard({
    required this.sharingEnabled,
    required this.onSharingChanged,
    required this.state,
    required this.onListeningChanged,
    required this.onOpenAppSettings,
    required this.onRelayChanged,
    required this.onSoundChanged,
    required this.onStopBroadcast,
    required this.onDismissEvent,
  });

  final bool sharingEnabled;
  final ValueChanged<bool> onSharingChanged;
  final SosBleState state;
  final ValueChanged<bool> onListeningChanged;
  final VoidCallback onOpenAppSettings;
  final ValueChanged<bool> onRelayChanged;
  final ValueChanged<bool> onSoundChanged;
  final VoidCallback onStopBroadcast;
  final ValueChanged<String> onDismissEvent;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: sharingEnabled,
              onChanged: state.supported == false
                  ? null
                  : (value) => onSharingChanged(value ?? false),
              title: Text(strings.sosBluetoothShareTitle),
              subtitle: Text(strings.sosBluetoothShareDescription),
              secondary: const Icon(Icons.bluetooth),
            ),
            if (sharingEnabled) ...[
              const Divider(),
              Text(strings.sosBluetoothFields),
              const SizedBox(height: 8),
              Text(strings.sosBluetoothTenMinuteLimit),
            ],
            if (state.supported == false) ...[
              const SizedBox(height: 8),
              Text(strings.sosBluetoothUnavailable),
            ],
            if (state.error == 'permission_denied') ...[
              const SizedBox(height: 8),
              Text(strings.sosBluetoothPermissionRequired),
            ],
            if (state.error == 'bluetooth_disabled') ...[
              const SizedBox(height: 8),
              Text(strings.sosBluetoothDisabled),
            ],
            if (state.error == 'permission_denied' ||
                state.error == 'notification_denied' ||
                state.error == 'bluetooth_disabled')
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onOpenAppSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(strings.openAppSettings),
                ),
              ),
            if (state.error == 'scan_failed' ||
                state.error == 'broadcast_failed' ||
                state.error == 'broadcast_timeout' ||
                state.error == 'broadcast_in_progress' ||
                state.error == 'unavailable' ||
                state.error == 'unsupported') ...[
              const SizedBox(height: 8),
              Text(strings.sosBluetoothOperationFailed),
            ],
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: state.listening,
              onChanged: state.supported == true ? onListeningChanged : null,
              title: Text(strings.sosBluetoothReceiveTitle),
              subtitle: Text(strings.sosBluetoothReceiveDescription),
              secondary: const Icon(Icons.notifications_active_outlined),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: state.relayEnabled,
              onChanged: state.supported == true ? onRelayChanged : null,
              title: Text(strings.sosBluetoothRelayTitle),
              subtitle: Text(strings.sosBluetoothRelayDescription),
              secondary: const Icon(Icons.repeat),
            ),
            if (state.relayCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(strings.sosBluetoothRelayCount(state.relayCount)),
              ),
            if (state.listening)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: state.soundEnabled,
                onChanged: onSoundChanged,
                title: Text(strings.sosBluetoothSoundTitle),
                subtitle: Text(strings.sosBluetoothSoundDescription),
              ),
            if (state.isBroadcasting) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    const Icon(Icons.radio, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(strings.sosBluetoothBroadcasting)),
                    TextButton(
                      onPressed: onStopBroadcast,
                      child: Text(strings.sosBluetoothStop),
                    ),
                  ],
                ),
              ),
              if (state.activeEvent case final event?) ...[
                const SizedBox(height: 8),
                Text(
                  strings.sosBluetoothBroadcastFrameDetails,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(_eventDescription(context, strings, event, peer: false)),
                if (sosBleGoogleMapsUrl(event) case final url?)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openMaps(url),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(strings.sosBluetoothOpenMaps),
                    ),
                  ),
              ],
            ],
            for (final event in state.nearbyEvents) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.warning_amber_outlined),
                        title: Text(strings.sosBluetoothNearbyAlert),
                        subtitle: Text(
                          _eventDescription(
                            context,
                            strings,
                            event,
                            peer: true,
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: strings.sosBluetoothDismiss,
                          onPressed: () => onDismissEvent(event.eventId),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                      if (sosBleGoogleMapsUrl(event) case final url?)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _openMaps(url),
                            icon: const Icon(Icons.open_in_new),
                            label: Text(strings.sosBluetoothOpenMaps),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _eventDescription(
    BuildContext context,
    AppLocalizations strings,
    SosBleEvent event, {
    required bool peer,
  }) {
    final location = event.hasLocation
        ? strings.sosBluetoothGridLocation(
            event.latitude!.toStringAsFixed(6),
            event.longitude!.toStringAsFixed(6),
          )
        : strings.sosBluetoothLocationUnavailable;
    final status = switch (event.locationStatus) {
      SosBleLocationStatus.current => strings.sosBluetoothCurrentLocation,
      SosBleLocationStatus.lastKnown => strings.sosBluetoothLastKnownLocation,
      SosBleLocationStatus.unavailable =>
        strings.sosBluetoothLocationUnavailable,
    };
    final battery = event.batteryPercent == null
        ? strings.sosBluetoothUnknownValue
        : strings.sosBluetoothBatteryValue(event.batteryPercent!);
    final signal = event.rssi == null
        ? strings.sosBluetoothUnknownValue
        : strings.sosBluetoothRssiValue(event.rssi!);
    return [
      if (peer) strings.sosBluetoothUnverified,
      location,
      status,
      strings.sosBluetoothEventId(event.eventId),
      strings.sosBluetoothTimestamp(
        _formatUtc(context, strings, event.createdAt),
      ),
      battery,
      signal,
      strings.sosBluetoothProtocol(event.protocolVersion, event.ttlMinutes),
      strings.sosBluetoothRelayHops(event.hopCount),
      if (sosBleGoogleMapsUrl(event) case final url?)
        strings.sosBluetoothMapsLink(url),
      strings.sosBluetoothApproximateNotice,
    ].join('\n');
  }

  Future<void> _openMaps(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.enabled,
    required this.onOpen,
    required this.onCancel,
    required this.onRemove,
  });

  final SosDraft draft;
  final bool enabled;
  final VoidCallback onOpen;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final status = switch (draft.status) {
      SosDraftStatus.prepared => strings.sosStatusPrepared,
      SosDraftStatus.smsSending => strings.sosStatusSmsSending,
      SosDraftStatus.smsSent => strings.sosStatusSmsSent,
      SosDraftStatus.smsPartial => strings.sosStatusSmsPartial,
      SosDraftStatus.smsUnknown => strings.sosStatusSmsUnknown,
      SosDraftStatus.smsFailed => strings.sosStatusSmsFailed,
      SosDraftStatus.composerOpened => strings.sosStatusComposerOpened,
      SosDraftStatus.failedToOpen => strings.sosStatusFailedToOpen,
      SosDraftStatus.cancelled => strings.sosStatusCancelled,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.sosStatusLabel(status),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              strings.sosDraftCreatedAt(
                _formatUtc(context, strings, draft.createdAt),
              ),
            ),
            const SizedBox(height: 6),
            for (final recipient in draft.recipients)
              Text(
                strings.sosRecipientPreview(
                  recipient.name,
                  recipient.phoneNumber,
                ),
              ),
            const SizedBox(height: 6),
            Text(_locationPreview(context, strings, draft.location)),
            const SizedBox(height: 8),
            SelectableText(draft.body),
            if (draft.status == SosDraftStatus.composerOpened) ...[
              const SizedBox(height: 8),
              Text(strings.sosComposerOpenedNotice),
            ],
            if (draft.status == SosDraftStatus.smsSent) ...[
              const SizedBox(height: 8),
              Text(strings.sosSmsSentNotice),
            ],
            if (draft.status == SosDraftStatus.smsFailed) ...[
              const SizedBox(height: 8),
              Text(strings.sosSmsFailedNotice),
            ],
            if (draft.status == SosDraftStatus.smsPartial ||
                draft.status == SosDraftStatus.smsUnknown) ...[
              const SizedBox(height: 8),
              Text(strings.sosSmsUncertainNotice),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (draft.status != SosDraftStatus.cancelled)
                  OutlinedButton.icon(
                    onPressed: enabled ? onOpen : null,
                    icon: const Icon(Icons.sms_outlined),
                    label: Text(strings.sosOpenAgain),
                  ),
                if (draft.status != SosDraftStatus.cancelled)
                  OutlinedButton.icon(
                    onPressed: enabled ? onCancel : null,
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(strings.sosCancelDraft),
                  ),
                OutlinedButton.icon(
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(strings.sosRemoveDraft),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueErrorCard extends StatelessWidget {
  const _QueueErrorCard({
    required this.state,
    required this.onRetry,
    required this.onReset,
  });

  final SosDraftQueueState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final corrupt =
        state.errorKind == SosDraftQueueErrorKind.corruptOrUnsupported;
    final write = state.errorKind == SosDraftQueueErrorKind.write;
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                write
                    ? strings.sosQueueWriteErrorTitle
                    : corrupt
                    ? strings.sosQueueDataErrorTitle
                    : strings.sosQueueReadErrorTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                write
                    ? strings.sosQueueWriteErrorDescription
                    : corrupt
                    ? strings.sosQueueDataErrorDescription
                    : strings.sosQueueReadErrorDescription,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(strings.retry),
              ),
              if (corrupt) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(strings.sosResetQueue),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

SosLocationSnapshot? _snapshotLocation(ForegroundLocationState state) {
  final location = state.location;
  if (location == null) return null;
  return SosLocationSnapshot.fromForegroundLocation(
    location,
    isLastKnown:
        state.phase == ForegroundLocationPhase.liveUnavailableWithLastKnown,
  );
}

String _locationPreview(
  BuildContext context,
  AppLocalizations strings,
  SosLocationSnapshot? location,
) {
  if (location == null) return strings.sosLocationUnavailable;
  final precision = location.precision.name == 'precise'
      ? strings.sosPrecise
      : strings.sosApproximate;
  final latitude = location.latitude.toStringAsFixed(6);
  final longitude = location.longitude.toStringAsFixed(6);
  final time = _formatUtc(context, strings, location.timestamp);
  return location.isLastKnown
      ? strings.sosLastKnownLocationPreview(
          precision,
          latitude,
          longitude,
          time,
        )
      : strings.sosCurrentLocationPreview(precision, latitude, longitude, time);
}

String _formatUtc(
  BuildContext context,
  AppLocalizations strings,
  DateTime value,
) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return strings.utcTimestamp(
    DateFormat.yMMMd(locale).add_Hms().format(value.toUtc()),
  );
}
