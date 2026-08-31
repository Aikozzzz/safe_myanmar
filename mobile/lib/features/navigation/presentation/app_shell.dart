import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/safe_widgets.dart';
import '../../../app/theme/safe_tokens.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onOpenEarthquakeInformation,
    this.onOpenMap,
    this.onOpenSos,
    this.onOpenGuide,
    super.key,
  });

  final VoidCallback onOpenEarthquakeInformation;
  final VoidCallback? onOpenMap;
  final VoidCallback? onOpenSos;
  final VoidCallback? onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    final actionCards = <Widget>[
      _HomeActionCard(
        semanticKey: const ValueKey('home-alerts-card'),
        icon: Icons.warning_amber_rounded,
        title: strings.homeEarthquakeCardTitle,
        actionLabel: strings.viewEarthquakeInformation,
        onTap: onOpenEarthquakeInformation,
      ),
      _HomeActionCard(
        semanticKey: const ValueKey('home-map-card'),
        icon: Icons.map_outlined,
        title: strings.navigationMap,
        actionLabel: strings.homeOpenMapAction,
        onTap: onOpenMap ?? () => context.go('/map'),
      ),
      _HomeActionCard(
        semanticKey: const ValueKey('home-sos-card'),
        icon: Icons.sos_outlined,
        title: strings.sosTitle,
        actionLabel: strings.homeOpenSosAction,
        onTap: onOpenSos ?? () => context.go('/sos'),
      ),
      _HomeActionCard(
        semanticKey: const ValueKey('home-guide-card'),
        icon: Icons.menu_book_outlined,
        title: strings.guideTitle,
        actionLabel: strings.homeOpenGuideAction,
        onTap: onOpenGuide ?? () => context.go('/guide'),
      ),
    ];

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
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 560
                      ? (constraints.maxWidth - SafeSpacing.md) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: SafeSpacing.md,
                    runSpacing: SafeSpacing.md,
                    children: [
                      for (final card in actionCards)
                        SizedBox(width: cardWidth, child: card),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.semanticKey,
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final Key semanticKey;
  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      key: semanticKey,
      container: true,
      button: true,
      label: '$title. $actionLabel',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 112),
              child: Padding(
                padding: const EdgeInsets.all(SafeSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: SafeRadii.sm,
                          ),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(icon, color: colors.onPrimaryContainer),
                          ),
                        ),
                        const SizedBox(width: SafeSpacing.md),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SafeSpacing.md),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: SafeSpacing.sm,
                      children: [
                        Text(
                          actionLabel,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
