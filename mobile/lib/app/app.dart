import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/safe_theme.dart';

class SafeMyanmarApp extends StatelessWidget {
  SafeMyanmarApp({GoRouter? router, super.key})
    : router = router ?? createRouter();

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
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
      routerConfig: router,
    );
  }
}
