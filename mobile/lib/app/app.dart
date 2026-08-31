import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/sos/application/providers.dart';
import '../features/location/application/providers.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/safe_theme.dart';

class SafeMyanmarApp extends ConsumerStatefulWidget {
  SafeMyanmarApp({GoRouter? router, super.key})
    : router = router ?? createRouter();

  final GoRouter router;

  @override
  ConsumerState<SafeMyanmarApp> createState() => _SafeMyanmarAppState();
}

class _SafeMyanmarAppState extends ConsumerState<SafeMyanmarApp>
    with WidgetsBindingObserver {
  var _lastNotificationSequence = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref.read(sosBleControllerProvider.notifier).restoreBackgroundEvents(),
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref
            .read(foregroundLocationControllerProvider.notifier)
            .refreshPermission(),
      );
      unawaited(
        ref.read(sosBleControllerProvider.notifier).restoreBackgroundEvents(),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sosBleControllerProvider, (previous, next) {
      final eventId = next.focusedEventId;
      if (eventId != null &&
          next.notificationSequence != _lastNotificationSequence) {
        _lastNotificationSequence = next.notificationSequence;
        widget.router.go('/map');
      }
    });
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: SafeTheme.light(),
      darkTheme: SafeTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: widget.router,
    );
  }
}
