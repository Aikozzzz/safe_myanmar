import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar'**
  String get appName;

  /// No description provided for @earthquakeInformation.
  ///
  /// In en, this message translates to:
  /// **'Earthquake information'**
  String get earthquakeInformation;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @liveInformation.
  ///
  /// In en, this message translates to:
  /// **'Live information'**
  String get liveInformation;

  /// No description provided for @cachedInformation.
  ///
  /// In en, this message translates to:
  /// **'Cached information'**
  String get cachedInformation;

  /// No description provided for @staleInformation.
  ///
  /// In en, this message translates to:
  /// **'Stale information'**
  String get staleInformation;

  /// No description provided for @lastSuccessfulUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last successful update: {time}'**
  String lastSuccessfulUpdate(String time);

  /// No description provided for @noRecentEarthquakes.
  ///
  /// In en, this message translates to:
  /// **'No recent earthquakes were found in the covered area. This does not guarantee there is no danger.'**
  String get noRecentEarthquakes;

  /// No description provided for @liveEarthquakeDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live earthquake data unavailable.'**
  String get liveEarthquakeDataUnavailable;

  /// No description provided for @savedInformationRemains.
  ///
  /// In en, this message translates to:
  /// **'Previously saved information remains available below.'**
  String get savedInformationRemains;

  /// No description provided for @couldNotUpdateLiveInformation.
  ///
  /// In en, this message translates to:
  /// **'Could not update live information.'**
  String get couldNotUpdateLiveInformation;

  /// No description provided for @magnitudeValue.
  ///
  /// In en, this message translates to:
  /// **'Magnitude {magnitude}'**
  String magnitudeValue(String magnitude);

  /// No description provided for @locationValue.
  ///
  /// In en, this message translates to:
  /// **'Location: {place}'**
  String locationValue(String place);

  /// No description provided for @eventTimeValue.
  ///
  /// In en, this message translates to:
  /// **'Event time: {time}'**
  String eventTimeValue(String time);

  /// No description provided for @depthValue.
  ///
  /// In en, this message translates to:
  /// **'Depth: {depth} km'**
  String depthValue(String depth);

  /// No description provided for @providerUpdateValue.
  ///
  /// In en, this message translates to:
  /// **'Provider update: {time}'**
  String providerUpdateValue(String time);

  /// No description provided for @retrievedValue.
  ///
  /// In en, this message translates to:
  /// **'Retrieved: {time}'**
  String retrievedValue(String time);

  /// No description provided for @reviewStatusValue.
  ///
  /// In en, this message translates to:
  /// **'Review status: {status}'**
  String reviewStatusValue(String status);

  /// No description provided for @dataSourceUsGS.
  ///
  /// In en, this message translates to:
  /// **'Source: USGS'**
  String get dataSourceUsGS;

  /// No description provided for @openUsGSsource.
  ///
  /// In en, this message translates to:
  /// **'Open USGS source'**
  String get openUsGSsource;

  /// No description provided for @couldNotOpenUsGSsource.
  ///
  /// In en, this message translates to:
  /// **'Could not open USGS source.'**
  String get couldNotOpenUsGSsource;

  /// No description provided for @earthquakeInformationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Earthquake information was not found.'**
  String get earthquakeInformationNotFound;

  /// No description provided for @backToEarthquakeInformation.
  ///
  /// In en, this message translates to:
  /// **'Back to earthquake information'**
  String get backToEarthquakeInformation;

  /// No description provided for @earthquakeCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'{type}. {magnitude}. {location}. {eventTime}. {status}. {source}'**
  String earthquakeCardSemantics(
    String type,
    String magnitude,
    String location,
    String eventTime,
    String status,
    String source,
  );

  /// No description provided for @earthquakeCardHint.
  ///
  /// In en, this message translates to:
  /// **'Open earthquake information details'**
  String get earthquakeCardHint;

  /// No description provided for @preliminaryNotice.
  ///
  /// In en, this message translates to:
  /// **'Preliminary earthquake values may change.'**
  String get preliminaryNotice;

  /// No description provided for @loadingEarthquakes.
  ///
  /// In en, this message translates to:
  /// **'Updating earthquake information'**
  String get loadingEarthquakes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
