import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../location/application/foreground_location_state.dart';
import '../../location/application/providers.dart';
import '../../profile/application/providers.dart';
import '../../profile/domain/local_profile.dart';
import '../application/providers.dart';
import '../application/sos_draft_queue_controller.dart';
import '../application/sos_draft_queue_state.dart';
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
    final locationState = ref.watch(foregroundLocationControllerProvider);
    final profile = profileState.profile;
    final selectedContacts =
        profile?.contacts.where((contact) => contact.selectedForSos).toList() ??
        const <EmergencyContact>[];
    final location = _snapshotLocation(locationState);
    final message = _messageController.text.trim();
    final body = buildSosMessage(
      strings: strings,
      profileName: profile?.displayName ?? '',
      location: location,
      userMessage: message,
    );
    final canPrepare =
        profile != null && selectedContacts.isNotEmpty && !queueState.isBusy;

    return Scaffold(
      appBar: AppBar(title: Text(strings.sosTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              strings.sosIntroduction,
              style: Theme.of(context).textTheme.bodyLarge,
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
            _SharedDataPreview(
              profile: profile,
              location: location,
              body: body,
            ),
            const SizedBox(height: 16),
            _DisclosureCard(description: strings.sosComposerDisclosure),
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
        title: Text(strings.sosConfirmComposerTitle),
        content: Text(strings.sosConfirmComposerDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.sosNotNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.sosOpenMessaging),
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
    if (contacts.isEmpty) return;
    final location = _snapshotLocation(
      ref.read(foregroundLocationControllerProvider),
    );
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
    await _openDraft(result.draft!);
  }

  Future<void> _openDraft(SosDraft draft) async {
    final strings = AppLocalizations.of(context)!;
    final opened = await ref
        .read(nativeSmsComposerProvider)
        .open(
          recipients: draft.recipients
              .map((recipient) => recipient.phoneNumber)
              .toList(),
          body: draft.body,
        );
    await ref
        .read(sosDraftQueueControllerProvider.notifier)
        .setStatus(
          draft.id,
          opened ? SosDraftStatus.composerOpened : SosDraftStatus.failedToOpen,
        );
    if (!mounted) return;
    _showNotice(
      opened
          ? strings.sosComposerOpenedNotice
          : strings.sosComposerFailedNotice,
    );
  }

  Future<void> _confirmOpenDraft(SosDraft draft) async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await _confirmationDialog(
      title: strings.sosRetryComposerTitle,
      description: '${strings.sosRetryComposerDescription}\n\n${draft.body}',
      confirmLabel: strings.sosOpenMessaging,
    );
    if (confirmed && mounted) {
      await _openDraft(draft);
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
