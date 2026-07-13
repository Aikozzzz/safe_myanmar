import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/alerts/presentation/alert_detail_screen.dart';
import '../features/alerts/presentation/alert_list_screen.dart';
import '../l10n/app_localizations.dart';

GoRouter createRouter({String initialLocation = '/alerts'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/alerts',
        builder: (context, _) => AlertListScreen(
          onOpenEarthquake: (id) =>
              context.push('/alerts/${Uri.encodeComponent(id)}'),
        ),
      ),
      GoRoute(
        path: '/alerts/:id',
        builder: (_, state) => AlertDetailScreen(
          earthquakeId: Uri.decodeComponent(state.pathParameters['id']!),
        ),
      ),
    ],
    errorBuilder: (_, _) => const _NotFoundScreen(),
  );
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(strings.appName)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_outlined, size: 40),
                const SizedBox(height: 12),
                Text(
                  strings.earthquakeInformationNotFound,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.go('/alerts'),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(strings.backToEarthquakeInformation),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
