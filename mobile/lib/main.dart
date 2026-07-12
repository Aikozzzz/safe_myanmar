import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/theme/safe_theme.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const SafeMyanmarApp());
}

class SafeMyanmarApp extends StatelessWidget {
  const SafeMyanmarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const SizedBox.shrink(),
    );
  }
}
