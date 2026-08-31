import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/safe_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../application/local_profile_controller.dart';
import '../application/local_profile_state.dart';
import '../application/providers.dart';
import '../domain/local_profile.dart';
import '../domain/phone_number.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final state = ref.watch(localProfileControllerProvider);
    final profile = state.profile;
    return Scaffold(
      appBar: AppBar(title: Text(strings.moreTitle)),
      body: SafeArea(
        child: SafeContent(
          child: switch (profile) {
            null => _ProfileUnavailable(state: state),
            final value => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.phase == LocalProfilePhase.saving) ...[
                  const _SavingBanner(),
                  const SizedBox(height: 12),
                ],
                if (state.errorKind == LocalProfileErrorKind.write) ...[
                  _WriteErrorBanner(
                    onRetry: () => ref
                        .read(localProfileControllerProvider.notifier)
                        .retry(),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  strings.profileOverviewTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                _OverviewCard(profile: value),
                const SizedBox(height: 12),
                _MoreActionCard(
                  icon: Icons.person_outline,
                  title: strings.editProfile,
                  subtitle: value.displayName.isEmpty
                      ? strings.profileNotSet
                      : value.displayName,
                  onTap: state.isBusy
                      ? null
                      : () => context.push('/more/profile'),
                ),
                const SizedBox(height: 12),
                _MoreActionCard(
                  icon: Icons.contact_phone_outlined,
                  title: strings.manageContacts,
                  subtitle: strings.contactsSummary(
                    value.contacts.length,
                    value.contacts
                        .where((contact) => contact.selectedForSos)
                        .length,
                  ),
                  onTap: state.isBusy
                      ? null
                      : () => context.push('/more/contacts'),
                ),
                const SizedBox(height: 16),
                _PrivacyCard(
                  title: strings.profilePrivacyTitle,
                  description: strings.profilePrivacyDescription,
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = ref.watch(localProfileControllerProvider);
    final profile = state.profile;
    if (!_initialized && profile != null) {
      _displayNameController.text = profile.displayName;
      _initialized = true;
    }
    return Scaffold(
      appBar: AppBar(title: Text(strings.editProfileTitle)),
      body: SafeArea(
        child: profile == null
            ? _ProfileUnavailable(state: state)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.errorKind == LocalProfileErrorKind.write) ...[
                    _WriteErrorBanner(onRetry: _save),
                    const SizedBox(height: 12),
                  ],
                  _PrivacyCard(
                    title: strings.profileLocalOnlyLabel,
                    description: strings.profilePrivacyDescription,
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _displayNameController,
                      maxLength: maxProfileDisplayNameLength,
                      decoration: InputDecoration(
                        labelText: strings.displayNameLabel,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.done,
                      enabled: !state.isBusy,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? strings.displayNameRequired
                          : null,
                      onFieldSubmitted: (_) => _save(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: state.isBusy ? null : _save,
                    icon: state.phase == LocalProfilePhase.saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      state.phase == LocalProfilePhase.saving
                          ? strings.profileSaving
                          : strings.saveChanges,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = await ref
        .read(localProfileControllerProvider.notifier)
        .saveDisplayName(_displayNameController.text);
    if (result == LocalProfileOperationResult.success && mounted) {
      context.pop();
    }
  }
}

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final state = ref.watch(localProfileControllerProvider);
    final profile = state.profile;
    return Scaffold(
      appBar: AppBar(title: Text(strings.contactsTitle)),
      body: SafeArea(
        child: profile == null
            ? _ProfileUnavailable(state: state)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.phase == LocalProfilePhase.saving) ...[
                    const _SavingBanner(),
                    const SizedBox(height: 12),
                  ],
                  if (state.errorKind == LocalProfileErrorKind.write) ...[
                    _WriteErrorBanner(
                      onRetry: () => ref
                          .read(localProfileControllerProvider.notifier)
                          .retry(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _PrivacyCard(
                    title: strings.profilePrivacyTitle,
                    description: strings.contactsPrivacyDescription,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed:
                        state.isBusy ||
                            profile.contacts.length >= maxEmergencyContacts
                        ? null
                        : () => context.push('/more/contacts/new'),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: Text(strings.addContact),
                  ),
                  if (profile.contacts.length >= maxEmergencyContacts) ...[
                    const SizedBox(height: 8),
                    Text(
                      strings.maximumContactsReached(maxEmergencyContacts),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (profile.contacts.isEmpty)
                    _EmptyContactsCard()
                  else
                    for (
                      var index = 0;
                      index < profile.contacts.length;
                      index++
                    ) ...[
                      _ContactCard(
                        contact: profile.contacts[index],
                        enabled: !state.isBusy,
                        onSelectionChanged: (selected) => ref
                            .read(localProfileControllerProvider.notifier)
                            .setSelectedForSos(
                              profile.contacts[index].id,
                              selected,
                            ),
                        onEdit: () => context.push(
                          '/more/contacts/'
                          '${Uri.encodeComponent(profile.contacts[index].id)}'
                          '/edit',
                        ),
                        onDelete: () => _confirmDelete(
                          context,
                          ref,
                          profile.contacts[index],
                        ),
                      ),
                      if (index != profile.contacts.length - 1)
                        const SizedBox(height: 12),
                    ],
                ],
              ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EmergencyContact contact,
  ) async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(strings.deleteContactTitle(contact.name)),
        content: Text(strings.deleteContactDescription),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => dialogContext.pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(localProfileControllerProvider.notifier)
        .deleteContact(contact.id);
  }
}

class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({this.contactId, super.key});

  final String? contactId;

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _labelController = TextEditingController();
  bool _selectedForSos = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = ref.watch(localProfileControllerProvider);
    final profile = state.profile;
    final contact = widget.contactId == null
        ? null
        : profile?.contactById(widget.contactId!);
    if (!_initialized && profile != null) {
      if (contact != null) {
        _nameController.text = contact.name;
        _phoneController.text = contact.phoneNumber;
        _labelController.text = contact.label;
        _selectedForSos = contact.selectedForSos;
      }
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.contactId == null
              ? strings.addContactTitle
              : strings.editContactTitle,
        ),
      ),
      body: SafeArea(
        child: profile == null
            ? _ProfileUnavailable(state: state)
            : widget.contactId != null && contact == null
            ? _ContactNotFound()
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (state.errorKind == LocalProfileErrorKind.write) ...[
                      _WriteErrorBanner(onRetry: _save),
                      const SizedBox(height: 12),
                    ],
                    _PrivacyCard(
                      title: strings.profileLocalOnlyLabel,
                      description: strings.contactsPrivacyDescription,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      maxLength: maxEmergencyContactNameLength,
                      decoration: InputDecoration(
                        labelText: strings.contactNameLabel,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      enabled: !state.isBusy,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? strings.contactNameRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: strings.phoneNumberLabel,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      enabled: !state.isBusy,
                      validator: (value) => _phoneError(strings, value ?? ''),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _labelController,
                      maxLength: maxEmergencyContactLabelLength,
                      decoration: InputDecoration(
                        labelText: strings.relationshipLabel,
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                      textInputAction: TextInputAction.done,
                      enabled: !state.isBusy,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? strings.relationshipRequired
                          : null,
                      onFieldSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: SwitchListTile(
                        value: _selectedForSos,
                        onChanged: state.isBusy
                            ? null
                            : (value) => setState(() {
                                _selectedForSos = value;
                              }),
                        title: Text(strings.selectedForSos),
                        subtitle: Text(strings.sosSelectionDescription),
                        secondary: const Icon(Icons.sos_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: state.isBusy ? null : _save,
                      icon: state.phase == LocalProfilePhase.saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        state.phase == LocalProfilePhase.saving
                            ? strings.profileSaving
                            : strings.saveChanges,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String? _phoneError(AppLocalizations strings, String value) {
    final validation = validateAndNormalizePhoneNumber(value);
    return switch (validation.error) {
      null => null,
      PhoneNumberValidationError.empty => strings.phoneNumberRequired,
      PhoneNumberValidationError.invalidCharacters =>
        strings.phoneNumberInvalidCharacters,
      PhoneNumberValidationError.invalidLength =>
        strings.phoneNumberInvalidLength,
    };
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = await ref
        .read(localProfileControllerProvider.notifier)
        .saveContact(
          id: widget.contactId,
          name: _nameController.text,
          phoneNumber: _phoneController.text,
          label: _labelController.text,
          selectedForSos: _selectedForSos,
        );
    if (!mounted) return;
    if (result == LocalProfileOperationResult.success) {
      context.pop();
    } else if (result == LocalProfileOperationResult.maximumContacts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.maximumContactsReached(maxEmergencyContacts),
          ),
        ),
      );
    }
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.profile});

  final LocalProfile profile;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              child: const Icon(Icons.person_outline, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              profile.displayName.isEmpty
                  ? strings.profileNotSet
                  : profile.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(strings.profileLocalOnlyLabel),
            const SizedBox(height: 12),
            Text(strings.profileOverviewDescription),
          ],
        ),
      ),
    );
  }
}

class _MoreActionCard extends StatelessWidget {
  const _MoreActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.enabled,
    required this.onSelectionChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final EmergencyContact contact;
  final bool enabled;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              value: contact.selectedForSos,
              onChanged: enabled ? onSelectionChanged : null,
              title: Text(contact.name),
              subtitle: Text(
                '${contact.label}\n${contact.phoneNumber}\n'
                '${contact.selectedForSos ? strings.selectedForSos : strings.notSelectedForSos}',
              ),
              secondary: const Icon(Icons.contact_phone_outlined),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: enabled ? onEdit : null,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(strings.editContact),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: enabled ? onDelete : null,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(strings.deleteContact),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyContactsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              strings.contactsEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(strings.contactsEmptyDescription, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileUnavailable extends ConsumerWidget {
  const _ProfileUnavailable({required this.state});

  final LocalProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    if (state.phase == LocalProfilePhase.loading) {
      return Center(
        child: Semantics(
          label: strings.profileLoading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    final isCorrupt =
        state.errorKind == LocalProfileErrorKind.corruptOrUnsupported;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  isCorrupt ? Icons.lock_reset : Icons.sync_problem_outlined,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  isCorrupt
                      ? strings.profileDataErrorTitle
                      : strings.profileReadErrorTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  isCorrupt
                      ? strings.profileDataErrorDescription
                      : strings.profileReadErrorDescription,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(localProfileControllerProvider.notifier).retry(),
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.retry),
                ),
                if (isCorrupt) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _confirmReset(context, ref),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: Text(strings.resetLocalProfile),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(strings.resetLocalProfileTitle),
        content: Text(strings.resetLocalProfileDescription),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => dialogContext.pop(true),
            child: Text(strings.reset),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(localProfileControllerProvider.notifier)
          .resetUnreadableData();
    }
  }
}

class _WriteErrorBanner extends StatelessWidget {
  const _WriteErrorBanner({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.profileWriteErrorTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(strings.profileWriteErrorDescription),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(strings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingBanner extends StatelessWidget {
  const _SavingBanner();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      label: strings.profileSaving,
      child: const LinearProgressIndicator(),
    );
  }
}

class _ContactNotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(strings.contactNotFound, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/more/contacts'),
              icon: const Icon(Icons.arrow_back),
              label: Text(strings.backToContacts),
            ),
          ],
        ),
      ),
    );
  }
}
