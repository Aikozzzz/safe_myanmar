import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/trusted_usgs_uri.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/earthquake.dart';
import 'presentation_formatters.dart';
import 'source_launcher.dart';

final earthquakeByIdProvider = FutureProvider.autoDispose
    .family<Earthquake?, String>(
      (ref, id) => ref.watch(alertRepositoryProvider).getById(id),
    );

class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({required this.earthquakeId, super.key});

  final String earthquakeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final earthquake = ref.watch(earthquakeByIdProvider(earthquakeId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.public),
            const SizedBox(width: 12),
            Expanded(child: Text(strings.earthquakeInformation)),
          ],
        ),
      ),
      body: SafeArea(
        child: earthquake.when(
          loading: () => _LoadingContent(label: strings.loadingEarthquakes),
          error: (_, _) =>
              _NotFoundContent(message: strings.earthquakeInformationNotFound),
          data: (value) => value == null
              ? _NotFoundContent(message: strings.earthquakeInformationNotFound)
              : _DetailContent(earthquake: value),
        ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFoundContent extends StatelessWidget {
  const _NotFoundContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.earthquake});

  final Earthquake earthquake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final reviewStatus = earthquake.reviewStatus;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DetailRow(
          icon: Icons.public,
          text: strings.earthquakeInformation,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(
          strings.magnitudeValue(formatDecimal(context, earthquake.magnitude)),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        _DetailRow(
          icon: Icons.place_outlined,
          text: strings.locationValue(earthquake.place),
        ),
        _DetailRow(
          icon: Icons.vertical_align_bottom,
          text: strings.depthValue(formatDecimal(context, earthquake.depthKm)),
        ),
        _DetailRow(
          icon: Icons.schedule_outlined,
          text: strings.eventTimeValue(
            formatUtcTimestamp(context, strings, earthquake.eventAt),
          ),
        ),
        _DetailRow(
          icon: Icons.update_outlined,
          text: strings.providerUpdateValue(
            formatUtcTimestamp(context, strings, earthquake.providerUpdatedAt),
          ),
        ),
        _DetailRow(
          icon: Icons.download_done_outlined,
          text: strings.retrievedValue(
            formatUtcTimestamp(context, strings, earthquake.retrievedAt),
          ),
        ),
        if (reviewStatus != null && reviewStatus.isNotEmpty)
          _DetailRow(
            icon: Icons.fact_check_outlined,
            text: strings.reviewStatusValue(reviewStatus),
          ),
        _DetailRow(
          icon: Icons.account_balance_outlined,
          text: strings.dataSourceUsGS,
        ),
        _DetailRow(icon: Icons.info_outline, text: strings.preliminaryNotice),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _openSource(context, ref),
            icon: const Icon(Icons.open_in_new),
            label: Text(strings.openUsGSsource),
          ),
        ),
      ],
    );
  }

  Future<void> _openSource(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context)!;
    final uri = parseTrustedUsgsUri(earthquake.sourceUrl);
    var launched = false;
    if (uri != null) {
      try {
        launched = await ref.read(sourceLauncherProvider)(uri);
      } catch (_) {
        launched = false;
      }
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.couldNotOpenUsGSsource)));
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text, this.style});

  final IconData icon;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
