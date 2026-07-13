import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/alert_list_state.dart';
import '../../domain/earthquake.dart';
import '../presentation_formatters.dart';

class EarthquakeCard extends StatelessWidget {
  const EarthquakeCard({
    required this.earthquake,
    required this.status,
    required this.onPressed,
    super.key,
  });

  final Earthquake earthquake;
  final AlertPresentationStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final magnitude = strings.magnitudeValue(
      formatDecimal(context, earthquake.magnitude),
    );
    final location = strings.locationValue(earthquake.place);
    final eventTime = strings.eventTimeValue(
      formatUtcTimestamp(context, earthquake.eventAt),
    );
    final statusLabel = switch (status) {
      AlertPresentationStatus.live => strings.liveInformation,
      AlertPresentationStatus.cached => strings.cachedInformation,
      AlertPresentationStatus.stale => strings.staleInformation,
    };

    return Semantics(
      button: true,
      onTap: onPressed,
      label: strings.earthquakeCardSemantics(
        strings.earthquakeInformation,
        magnitude,
        location,
        eventTime,
        statusLabel,
        strings.dataSourceUsGS,
      ),
      hint: strings.earthquakeCardHint,
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.public),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.earthquakeInformation,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(magnitude, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(location),
                const SizedBox(height: 8),
                Text(eventTime),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(statusLabel)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(strings.dataSourceUsGS)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
