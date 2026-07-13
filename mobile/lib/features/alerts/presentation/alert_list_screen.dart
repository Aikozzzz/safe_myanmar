import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/alert_list_state.dart';
import '../application/providers.dart';
import 'widgets/data_status_banner.dart';
import 'widgets/earthquake_card.dart';

class AlertListScreen extends ConsumerWidget {
  const AlertListScreen({this.onOpenEarthquake, super.key});

  final ValueChanged<String>? onOpenEarthquake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final state = ref.watch(alertListControllerProvider);

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
        child: switch (state.phase) {
          AlertListPhase.loading => _LoadingContent(
            label: strings.loadingEarthquakes,
          ),
          AlertListPhase.unavailable => _UnavailableContent(
            refreshing: state.isRefreshing,
            onRefresh: () =>
                ref.read(alertListControllerProvider.notifier).refresh(),
          ),
          AlertListPhase.data || AlertListPhase.empty => _DataContent(
            state: state,
            onRefresh: () =>
                ref.read(alertListControllerProvider.notifier).refresh(),
            onOpenEarthquake: onOpenEarthquake,
          ),
        },
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

class _UnavailableContent extends StatelessWidget {
  const _UnavailableContent({
    required this.refreshing,
    required this.onRefresh,
  });

  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              strings.liveEarthquakeDataUnavailable,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: refreshing ? null : onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(strings.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataContent extends StatelessWidget {
  const _DataContent({
    required this.state,
    required this.onRefresh,
    required this.onOpenEarthquake,
  });

  final AlertListState state;
  final VoidCallback onRefresh;
  final ValueChanged<String>? onOpenEarthquake;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final status = state.presentationStatus!;
    final showSavedInformation =
        status == AlertPresentationStatus.stale &&
        (state.errorKind != null || state.phase == AlertListPhase.empty);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        DataStatusBanner(
          status: status,
          lastSuccessfulRefreshAt: state.lastSuccessfulRefreshAt,
        ),
        if (state.isRefreshing)
          _InformationNotice(
            icon: Icons.sync,
            message: strings.loadingEarthquakes,
            progress: true,
          ),
        if (state.errorKind != null)
          _InformationNotice(
            icon: Icons.sync_problem_outlined,
            message: strings.couldNotUpdateLiveInformation,
          ),
        if (showSavedInformation)
          _InformationNotice(
            icon: Icons.save_outlined,
            message: strings.savedInformationRemains,
          ),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: state.isRefreshing ? null : onRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(strings.refresh),
          ),
        ),
        if (state.phase == AlertListPhase.empty &&
            status != AlertPresentationStatus.stale)
          _InformationNotice(
            icon: Icons.info_outline,
            message: strings.noRecentEarthquakes,
          ),
        for (final earthquake in state.items)
          EarthquakeCard(
            earthquake: earthquake,
            status: status,
            onPressed: () => onOpenEarthquake?.call(earthquake.id),
          ),
      ],
    );
  }
}

class _InformationNotice extends StatelessWidget {
  const _InformationNotice({
    required this.icon,
    required this.message,
    this.progress = false,
  });

  final IconData icon;
  final String message;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Semantics(
        label: message,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (progress)
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
