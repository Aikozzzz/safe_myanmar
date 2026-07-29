import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/alerts/presentation/alert_detail_screen.dart';
import '../features/alerts/presentation/alert_list_screen.dart';
import '../features/guide/presentation/assistant_screen.dart';
import '../features/guide/presentation/guide_screens.dart';
import '../features/location/presentation/location_screen.dart';
import '../features/navigation/presentation/app_shell.dart';
import '../features/profile/presentation/profile_screens.dart';
import '../l10n/app_localizations.dart';

GoRouter createRouter({String initialLocation = '/home'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, _) => HomeScreen(
                  onOpenEarthquakeInformation: () => context.push('/alerts'),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/map', builder: (_, _) => const LocationScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/sos', builder: (_, _) => const SosScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guide',
                builder: (_, _) => const GuideScreen(),
                routes: [
                  GoRoute(
                    path: 'article/:articleId',
                    builder: (_, state) => ArticleDetailScreen(
                      articleId: Uri.decodeComponent(
                        state.pathParameters['articleId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'assistant',
                    builder: (_, _) => const AssistantScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, _) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, _) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'contacts',
                    builder: (_, _) => const EmergencyContactsScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (_, _) => const ContactFormScreen(),
                      ),
                      GoRoute(
                        path: ':contactId/edit',
                        builder: (_, state) => ContactFormScreen(
                          contactId: Uri.decodeComponent(
                            state.pathParameters['contactId']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
