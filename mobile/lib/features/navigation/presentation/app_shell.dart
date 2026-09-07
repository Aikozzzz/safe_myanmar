import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/safe_widgets.dart';
import '../../../app/theme/safe_tokens.dart';
import '../../alerts/application/alert_list_state.dart';
import '../../alerts/application/providers.dart';
import '../../alerts/presentation/widgets/data_status_banner.dart';
import '../../alerts/presentation/widgets/earthquake_card.dart';

export '../../sos/presentation/sos_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.navigationHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: strings.navigationMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sos_outlined),
            selectedIcon: const Icon(Icons.sos),
            label: strings.navigationSos,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: strings.navigationGuide,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            selectedIcon: const Icon(Icons.more),
            label: strings.navigationMore,
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    required this.onOpenEarthquakeInformation,
    this.onOpenEarthquake,
    super.key,
  });

  final VoidCallback onOpenEarthquakeInformation;
  final ValueChanged<String>? onOpenEarthquake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final alertState = ref.watch(alertListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.homeTitle)),
      body: SafeArea(
        child: SafeContent(
          child: ListView(
            padding: const EdgeInsets.all(SafeSpacing.lg),
            children: [
              SafePageHeader(
                title: strings.homeSafetyCenterTitle,
                description: strings.homeSafetyCenterDescription,
              ),
              const SizedBox(height: SafeSpacing.xl),
              _HomeEarthquakeSection(
                state: alertState,
                onOpenEarthquakeInformation: onOpenEarthquakeInformation,
                onOpenEarthquake: onOpenEarthquake,
                onRefresh: () {
                  ref.read(alertListControllerProvider.notifier).refresh();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeEarthquakeSection extends StatelessWidget {
  const _HomeEarthquakeSection({
    required this.state,
    required this.onOpenEarthquakeInformation,
    required this.onOpenEarthquake,
    required this.onRefresh,
  });

  final AlertListState state;
  final VoidCallback onOpenEarthquakeInformation;
  final ValueChanged<String>? onOpenEarthquake;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final content = switch (state.phase) {
      AlertListPhase.loading => SafeStatusCard(
        icon: Icons.sync,
        message: strings.loadingEarthquakes,
      ),
      AlertListPhase.unavailable => SafeStatusCard(
        icon: Icons.cloud_off_outlined,
        message: strings.liveEarthquakeDataUnavailable,
        action: OutlinedButton.icon(
          onPressed: state.isRefreshing ? null : onRefresh,
          icon: const Icon(Icons.refresh),
          label: Text(strings.refresh),
        ),
      ),
      AlertListPhase.data || AlertListPhase.empty => _HomeEarthquakeData(
        state: state,
        onOpenEarthquakeInformation: onOpenEarthquakeInformation,
        onOpenEarthquake: onOpenEarthquake,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.homeEarthquakeCardTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: SafeSpacing.sm),
        content,
        const SizedBox(height: SafeSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            key: const ValueKey('home-alerts-card'),
            container: true,
            button: true,
            label:
                '${strings.earthquakeInformation}. ${strings.viewEarthquakeInformation}',
            onTap: onOpenEarthquakeInformation,
            child: ExcludeSemantics(
              child: OutlinedButton.icon(
                onPressed: onOpenEarthquakeInformation,
                icon: const Icon(Icons.list_alt_outlined),
                label: Text(strings.viewEarthquakeInformation),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeEarthquakeData extends StatelessWidget {
  const _HomeEarthquakeData({
    required this.state,
    required this.onOpenEarthquakeInformation,
    required this.onOpenEarthquake,
  });

  final AlertListState state;
  final VoidCallback onOpenEarthquakeInformation;
  final ValueChanged<String>? onOpenEarthquake;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final status = state.presentationStatus!;
    final showSavedInformation =
        status == AlertPresentationStatus.stale &&
        (state.errorKind != null || state.phase == AlertListPhase.empty);
    final latest = state.items.isEmpty ? null : state.items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataStatusBanner(
          status: status,
          lastSuccessfulRefreshAt: state.lastSuccessfulRefreshAt,
        ),
        if (state.isRefreshing)
          const _HomeInformationNotice(
            icon: Icons.sync,
            messageKey: _HomeNoticeMessage.loading,
          ),
        if (state.errorKind != null)
          const _HomeInformationNotice(
            icon: Icons.sync_problem_outlined,
            messageKey: _HomeNoticeMessage.updateFailure,
          ),
        if (showSavedInformation)
          const _HomeInformationNotice(
            icon: Icons.save_outlined,
            messageKey: _HomeNoticeMessage.savedInformation,
          ),
        if (latest != null) ...[
          const SizedBox(height: SafeSpacing.md),
          EarthquakeCard(
            key: const ValueKey('home-latest-earthquake-card'),
            earthquake: latest,
            status: status,
            onPressed: () {
              final open = onOpenEarthquake;
              if (open != null) {
                open(latest.id);
              } else {
                onOpenEarthquakeInformation();
              }
            },
          ),
        ],
        if (state.phase == AlertListPhase.empty &&
            status != AlertPresentationStatus.stale) ...[
          const SizedBox(height: SafeSpacing.md),
          _HomeInformationNotice(
            icon: Icons.info_outline,
            message: strings.noRecentEarthquakes,
          ),
        ],
      ],
    );
  }
}

enum _HomeNoticeMessage { loading, updateFailure, savedInformation }

class _HomeInformationNotice extends StatelessWidget {
  const _HomeInformationNotice({
    required this.icon,
    this.message,
    this.messageKey,
  }) : assert(message != null || messageKey != null);

  final IconData icon;
  final String? message;
  final _HomeNoticeMessage? messageKey;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final resolvedMessage =
        message ??
        switch (messageKey!) {
          _HomeNoticeMessage.loading => strings.loadingEarthquakes,
          _HomeNoticeMessage.updateFailure =>
            strings.couldNotUpdateLiveInformation,
          _HomeNoticeMessage.savedInformation =>
            strings.savedInformationRemains,
        };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SafeSpacing.xs),
      child: Semantics(
        label: resolvedMessage,
        liveRegion: messageKey == _HomeNoticeMessage.loading,
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: SafeSpacing.sm),
            Expanded(child: Text(resolvedMessage)),
          ],
        ),
      ),
    );
  }
}
