// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SafeMyanmar';

  @override
  String get earthquakeInformation => 'Earthquake information';

  @override
  String get dataSourceUsGS => 'Source: USGS';

  @override
  String get preliminaryNotice => 'Preliminary earthquake values may change.';

  @override
  String get loadingEarthquakes => 'Updating earthquake information';
}
