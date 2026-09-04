import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/local_emergency_contact.dart';

typedef EmergencyPhoneLauncher = Future<bool> Function(Uri uri);

class YangonEmergencyContactsScreen extends StatelessWidget {
  const YangonEmergencyContactsScreen({
    this.launchPhone = _launchPhone,
    super.key,
  });

  final EmergencyPhoneLauncher launchPhone;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(title: Text(strings.guideEmergencyContactsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              strings.guideEmergencyContactsDescription,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            for (final contact in yangonEmergencyContacts) ...[
              _EmergencyContactCard(
                contact: contact,
                onCall: (uri) => _call(context, uri),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.guideEmergencyContactsSource,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(yangonEmergencyContactSourceUrl),
                    const SizedBox(height: 8),
                    Text(
                      strings.guideEmergencyContactsCheckedAt(
                        DateFormat.yMMMd(
                          locale,
                        ).format(yangonEmergencyContactsCheckedAt),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(strings.guideEmergencyContactsWarning),
                    const SizedBox(height: 8),
                    Text(strings.guideEmergencyContactsDialingNote),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _call(BuildContext context, Uri uri) async {
    final strings = AppLocalizations.of(context)!;
    if (await launchPhone(uri) || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.guideEmergencyContactsCallUnavailable)),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({required this.contact, required this.onCall});

  final YangonEmergencyContact contact;
  final ValueChanged<Uri> onCall;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_phone_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _serviceLabel(strings, contact.service),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            for (final phone in contact.phones) ...[
              const SizedBox(height: 12),
              Text(
                phone.displayNumber,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: ValueKey(
                  'yangon-emergency-call-${contact.service.name}-${phone.dialNumber}',
                ),
                onPressed: () => onCall(phone.uri),
                icon: const Icon(Icons.call_outlined),
                label: Text(strings.guideEmergencyContactsCall),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<bool> _launchPhone(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

String _serviceLabel(
  AppLocalizations strings,
  YangonEmergencyService service,
) => switch (service) {
  YangonEmergencyService.ambulance => strings.guideEmergencyContactAmbulance,
  YangonEmergencyService.fire => strings.guideEmergencyContactFire,
  YangonEmergencyService.police => strings.guideEmergencyContactPolice,
  YangonEmergencyService.yangonGeneralHospital =>
    strings.guideEmergencyContactYangonGeneralHospital,
};
