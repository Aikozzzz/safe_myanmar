import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/alert_list_state.dart';
import '../presentation_formatters.dart';

class DataStatusBanner extends StatelessWidget {
  const DataStatusBanner({
    required this.status,
    required this.lastSuccessfulRefreshAt,
    super.key,
  });

  final AlertPresentationStatus status;
  final DateTime? lastSuccessfulRefreshAt;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final (icon, label) = switch (status) {
      AlertPresentationStatus.live => (
        Icons.cloud_done_outlined,
        strings.liveInformation,
      ),
      AlertPresentationStatus.cached => (
        Icons.save_outlined,
        strings.cachedInformation,
      ),
      AlertPresentationStatus.stale => (
        Icons.history_outlined,
        strings.staleInformation,
      ),
    };
    final lastUpdate = switch (lastSuccessfulRefreshAt) {
      final refreshedAt? => strings.lastSuccessfulUpdate(
        formatUtcTimestamp(context, strings, refreshedAt),
      ),
      null => null,
    };
    final semanticLabel = lastUpdate == null
        ? label
        : strings.dataStatusSemantics(label, lastUpdate);

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                    if (lastUpdate != null) ...[
                      const SizedBox(height: 4),
                      Text(lastUpdate),
                    ],
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
