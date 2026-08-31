import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_my.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('my'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar'**
  String get appName;

  /// No description provided for @navigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navigationHome;

  /// No description provided for @navigationMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navigationMap;

  /// No description provided for @navigationSos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get navigationSos;

  /// No description provided for @navigationGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get navigationGuide;

  /// No description provided for @navigationMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navigationMore;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar'**
  String get homeTitle;

  /// No description provided for @homeWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency response at a glance'**
  String get homeWelcomeTitle;

  /// No description provided for @homeDescription.
  ///
  /// In en, this message translates to:
  /// **'Emergency information and tools based on currently available information.'**
  String get homeDescription;

  /// No description provided for @homeSafetyCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Center'**
  String get homeSafetyCenterTitle;

  /// No description provided for @homeSafetyCenterDescription.
  ///
  /// In en, this message translates to:
  /// **'Review available information and open key safety tools.'**
  String get homeSafetyCenterDescription;

  /// No description provided for @homeOpenMapAction.
  ///
  /// In en, this message translates to:
  /// **'Open Map'**
  String get homeOpenMapAction;

  /// No description provided for @homeOpenSosAction.
  ///
  /// In en, this message translates to:
  /// **'Open SOS setup'**
  String get homeOpenSosAction;

  /// No description provided for @homeOpenGuideAction.
  ///
  /// In en, this message translates to:
  /// **'Open Guide'**
  String get homeOpenGuideAction;

  /// No description provided for @homeEarthquakeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Live earthquake information'**
  String get homeEarthquakeCardTitle;

  /// No description provided for @viewEarthquakeInformation.
  ///
  /// In en, this message translates to:
  /// **'View earthquake information'**
  String get viewEarthquakeInformation;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitle;

  /// No description provided for @locationHeading.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get locationHeading;

  /// No description provided for @locationMapAction.
  ///
  /// In en, this message translates to:
  /// **'Show my location details'**
  String get locationMapAction;

  /// No description provided for @locationDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your location details'**
  String get locationDetailsTitle;

  /// No description provided for @locationDetailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the location currently available on this device.'**
  String get locationDetailsDescription;

  /// No description provided for @locationDetailsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Access precision'**
  String get locationDetailsAccuracy;

  /// No description provided for @locationDetailsCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get locationDetailsCoordinates;

  /// No description provided for @locationDetailsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get locationDetailsUpdated;

  /// No description provided for @locationNotRequestedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location access is off'**
  String get locationNotRequestedTitle;

  /// No description provided for @locationPermissionExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow location access?'**
  String get locationPermissionExplanationTitle;

  /// No description provided for @locationPermissionExplanationDescription.
  ///
  /// In en, this message translates to:
  /// **'Your location helps us provide nearby results and location-based features. It will only be used when needed.'**
  String get locationPermissionExplanationDescription;

  /// No description provided for @allowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow Location'**
  String get allowLocation;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @locationExplanation.
  ///
  /// In en, this message translates to:
  /// **'Mapbox may receive SDK, device, and usage telemetry when the app starts, before location permission; your device location is not included then. Choosing Use my location constructs and centers the remote Mapbox map, disclosing the viewed map area. Your exact origin goes to the SafeMyanmar backend and Mapbox Directions only after you request a route.'**
  String get locationExplanation;

  /// No description provided for @locationPrivacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Before you choose Use my location, SafeMyanmar does not request device location or construct the map. After you choose it, later launches reuse that permission while it remains granted. Shelter refresh and Mapbox telemetry may use the network without device location. SafeMyanmar does not keep a location history or request background location.'**
  String get locationPrivacyDescription;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @tryLocationAgain.
  ///
  /// In en, this message translates to:
  /// **'Try location again'**
  String get tryLocationAgain;

  /// No description provided for @locationRequestingTitle.
  ///
  /// In en, this message translates to:
  /// **'Requesting location'**
  String get locationRequestingTitle;

  /// No description provided for @locationRequestingDescription.
  ///
  /// In en, this message translates to:
  /// **'Checking permission and finding your current location.'**
  String get locationRequestingDescription;

  /// No description provided for @findingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding your location'**
  String get findingYourLocation;

  /// No description provided for @preciseLocationAvailable.
  ///
  /// In en, this message translates to:
  /// **'Precise location available'**
  String get preciseLocationAvailable;

  /// No description provided for @preciseLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Your device provided precise foreground location access.'**
  String get preciseLocationDescription;

  /// No description provided for @approximateLocationAvailable.
  ///
  /// In en, this message translates to:
  /// **'Approximate location available'**
  String get approximateLocationAvailable;

  /// No description provided for @approximateLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Your device provided approximate foreground location access. The position may cover a wider area.'**
  String get approximateLocationDescription;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedDescription.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar cannot access location unless you choose to allow it.'**
  String get locationPermissionDeniedDescription;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @locationPermissionPermanentlyDeniedDescription.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar will not ask again. You can change location permission in app settings.'**
  String get locationPermissionPermanentlyDeniedDescription;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are off'**
  String get locationServicesDisabled;

  /// No description provided for @locationServicesDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn on device location services before trying again.'**
  String get locationServicesDisabledDescription;

  /// No description provided for @lastKnownLocation.
  ///
  /// In en, this message translates to:
  /// **'Last known location'**
  String get lastKnownLocation;

  /// No description provided for @lastKnownLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'A live location was unavailable. This is the last known location reported by your device.'**
  String get lastKnownLocationDescription;

  /// No description provided for @locationRecoverableError.
  ///
  /// In en, this message translates to:
  /// **'Location temporarily unavailable'**
  String get locationRecoverableError;

  /// No description provided for @locationRecoverableErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar could not get a current or last known location. You can try again.'**
  String get locationRecoverableErrorDescription;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get openAppSettings;

  /// No description provided for @openLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open location settings'**
  String get openLocationSettings;

  /// No description provided for @couldNotOpenLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not open location settings.'**
  String get couldNotOpenLocationSettings;

  /// No description provided for @locationCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Location: {latitude}, {longitude}'**
  String locationCoordinates(String latitude, String longitude);

  /// No description provided for @locationCapturedAt.
  ///
  /// In en, this message translates to:
  /// **'Location time: {time}'**
  String locationCapturedAt(String time);

  /// No description provided for @lastKnownLocationAt.
  ///
  /// In en, this message translates to:
  /// **'Last known at: {time}'**
  String lastKnownLocationAt(String time);

  /// No description provided for @simulationLabel.
  ///
  /// In en, this message translates to:
  /// **'SIMULATION'**
  String get simulationLabel;

  /// No description provided for @simulationNavigationHeading.
  ///
  /// In en, this message translates to:
  /// **'Simulation shelter and route information'**
  String get simulationNavigationHeading;

  /// No description provided for @navigationSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String navigationSource(String source);

  /// No description provided for @openStreetMapAttribution.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get openStreetMapAttribution;

  /// No description provided for @shelterDataTime.
  ///
  /// In en, this message translates to:
  /// **'Shelter data: {time}'**
  String shelterDataTime(String time);

  /// No description provided for @hazardDataTime.
  ///
  /// In en, this message translates to:
  /// **'Hazard data: {time}'**
  String hazardDataTime(String time);

  /// No description provided for @navigationCachedAt.
  ///
  /// In en, this message translates to:
  /// **'Saved for offline use: {time}'**
  String navigationCachedAt(String time);

  /// No description provided for @navigationDataLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading shelter and hazard data'**
  String get navigationDataLoading;

  /// No description provided for @navigationDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Shelter or hazard information could not be updated.'**
  String get navigationDataUnavailable;

  /// No description provided for @contextAnalysisUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Nearby analysis is unavailable. Check the backend connection or choose earthquake or flood analysis.'**
  String get contextAnalysisUnavailable;

  /// No description provided for @navigationCachedWarning.
  ///
  /// In en, this message translates to:
  /// **'Previously loaded information remains visible and may be stale.'**
  String get navigationCachedWarning;

  /// No description provided for @retryNavigationData.
  ///
  /// In en, this message translates to:
  /// **'Retry shelter and hazard data'**
  String get retryNavigationData;

  /// No description provided for @mapConfigurationUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Map configuration unavailable'**
  String get mapConfigurationUnavailableTitle;

  /// No description provided for @mapConfigurationUnavailableDescription.
  ///
  /// In en, this message translates to:
  /// **'A valid public Mapbox token was not provided. Location, shelter, hazard, and route controls remain available, but the map cannot be displayed.'**
  String get mapConfigurationUnavailableDescription;

  /// No description provided for @mapTemporarilyUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Map temporarily unavailable'**
  String get mapTemporarilyUnavailableTitle;

  /// No description provided for @mapTemporarilyUnavailableDescription.
  ///
  /// In en, this message translates to:
  /// **'Mapbox map or style data could not load because the device may be offline or the map configuration may be unavailable. Shelter details and controls remain available.'**
  String get mapTemporarilyUnavailableDescription;

  /// No description provided for @mapContentSemantics.
  ///
  /// In en, this message translates to:
  /// **'Interactive map showing current or last-known location, mapped shelters, relevant hazards, and route options. Tap the location button or your location marker for details. The selected route uses a wider line.'**
  String get mapContentSemantics;

  /// No description provided for @mapLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Map legend'**
  String get mapLegendTitle;

  /// No description provided for @mapLegendLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get mapLegendLocation;

  /// No description provided for @mapLegendShelter.
  ///
  /// In en, this message translates to:
  /// **'Mapped shelter'**
  String get mapLegendShelter;

  /// No description provided for @mapLegendHazard.
  ///
  /// In en, this message translates to:
  /// **'Mapped hazard'**
  String get mapLegendHazard;

  /// No description provided for @mapLegendContextArea.
  ///
  /// In en, this message translates to:
  /// **'Suggested area'**
  String get mapLegendContextArea;

  /// No description provided for @mapLegendRoute.
  ///
  /// In en, this message translates to:
  /// **'Suggested route'**
  String get mapLegendRoute;

  /// No description provided for @mapLegendNearbySos.
  ///
  /// In en, this message translates to:
  /// **'Unverified nearby SOS'**
  String get mapLegendNearbySos;

  /// No description provided for @chooseShelter.
  ///
  /// In en, this message translates to:
  /// **'Shelter or suggested place'**
  String get chooseShelter;

  /// No description provided for @shelterListHeading.
  ///
  /// In en, this message translates to:
  /// **'Available mapped shelters'**
  String get shelterListHeading;

  /// No description provided for @shelterListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cached shelter details are available.'**
  String get shelterListEmpty;

  /// No description provided for @contextAreasHeading.
  ///
  /// In en, this message translates to:
  /// **'Top lower-exposure suggestions'**
  String get contextAreasHeading;

  /// No description provided for @contextAreasDescription.
  ///
  /// In en, this message translates to:
  /// **'Suggestions use names from mapped parks, fields, and other place features when available. Compare the available mapped metrics and limits; these are not official shelters or guarantees.'**
  String get contextAreasDescription;

  /// No description provided for @contextSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Context summary'**
  String get contextSummaryTitle;

  /// No description provided for @contextSummaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the selected candidate\'s mapped metrics, rationale, source, timestamp, and limits. It is not an official shelter or a guarantee.'**
  String get contextSummaryDescription;

  /// No description provided for @contextSummaryNoMappedHazards.
  ///
  /// In en, this message translates to:
  /// **'No mapped hazards found. This does not confirm the area is safe.'**
  String get contextSummaryNoMappedHazards;

  /// No description provided for @analyzeContext.
  ///
  /// In en, this message translates to:
  /// **'Analyze nearby areas'**
  String get analyzeContext;

  /// No description provided for @analyzingContext.
  ///
  /// In en, this message translates to:
  /// **'Analyzing context'**
  String get analyzingContext;

  /// No description provided for @noContextAreas.
  ///
  /// In en, this message translates to:
  /// **'No lower-exposure area was identified for this scenario. Follow authorized local instructions.'**
  String get noContextAreas;

  /// No description provided for @contextSelectedCandidate.
  ///
  /// In en, this message translates to:
  /// **'Selected candidate'**
  String get contextSelectedCandidate;

  /// No description provided for @contextSelectCandidate.
  ///
  /// In en, this message translates to:
  /// **'Select candidate'**
  String get contextSelectCandidate;

  /// No description provided for @contextSuggestionRank.
  ///
  /// In en, this message translates to:
  /// **'Suggestion {rank}'**
  String contextSuggestionRank(int rank);

  /// No description provided for @contextCandidateSelectionHint.
  ///
  /// In en, this message translates to:
  /// **'Select this candidate to review its details. Requesting a route is a separate action.'**
  String get contextCandidateSelectionHint;

  /// No description provided for @contextNoCandidateSelected.
  ///
  /// In en, this message translates to:
  /// **'No candidate is selected. Select one above to review its details.'**
  String get contextNoCandidateSelected;

  /// No description provided for @chooseContextScenario.
  ///
  /// In en, this message translates to:
  /// **'Earthquake context'**
  String get chooseContextScenario;

  /// No description provided for @outdoorsAfterShaking.
  ///
  /// In en, this message translates to:
  /// **'After shaking stops: analyze open areas'**
  String get outdoorsAfterShaking;

  /// No description provided for @activeShaking.
  ///
  /// In en, this message translates to:
  /// **'During active shaking: show immediate guidance'**
  String get activeShaking;

  /// No description provided for @contextDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} m'**
  String contextDistance(int distance);

  /// No description provided for @contextElevation.
  ///
  /// In en, this message translates to:
  /// **'Relative elevation: {elevation} m'**
  String contextElevation(String elevation);

  /// No description provided for @contextClearance.
  ///
  /// In en, this message translates to:
  /// **'Building clearance: {building} m; tree clearance: {tree} m'**
  String contextClearance(int building, int tree);

  /// No description provided for @contextMetricsHeading.
  ///
  /// In en, this message translates to:
  /// **'Mapped comparison metrics'**
  String get contextMetricsHeading;

  /// No description provided for @contextBuildingDensity.
  ///
  /// In en, this message translates to:
  /// **'Mapped building density: {density}%'**
  String contextBuildingDensity(String density);

  /// No description provided for @contextTreeDensity.
  ///
  /// In en, this message translates to:
  /// **'Mapped tree density: {density}%'**
  String contextTreeDensity(String density);

  /// No description provided for @contextHazardIntersections.
  ///
  /// In en, this message translates to:
  /// **'Mapped hazard intersections: {count}'**
  String contextHazardIntersections(int count);

  /// No description provided for @contextRationaleHeading.
  ///
  /// In en, this message translates to:
  /// **'Why this area is listed'**
  String get contextRationaleHeading;

  /// No description provided for @contextDataAt.
  ///
  /// In en, this message translates to:
  /// **'Analysis data: {time}'**
  String contextDataAt(String time);

  /// No description provided for @contextDataHeading.
  ///
  /// In en, this message translates to:
  /// **'Data, source, and limits'**
  String get contextDataHeading;

  /// No description provided for @contextRouteSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Select a candidate above, then request a route separately. No route is requested automatically.'**
  String get contextRouteSelectionDescription;

  /// No description provided for @sosBluetoothShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share limited SOS data nearby'**
  String get sosBluetoothShareTitle;

  /// No description provided for @sosBluetoothShareDescription.
  ///
  /// In en, this message translates to:
  /// **'Broadcast a temporary ID, timestamp, exact coordinates when available, location status, and battery level to nearby SafeMyanmar users for 10 minutes.'**
  String get sosBluetoothShareDescription;

  /// No description provided for @sosBluetoothFields.
  ///
  /// In en, this message translates to:
  /// **'Shared: temporary event ID, UTC timestamp, exact coordinates when available, location status, and battery level.'**
  String get sosBluetoothFields;

  /// No description provided for @sosBluetoothTenMinuteLimit.
  ///
  /// In en, this message translates to:
  /// **'The broadcast stops automatically after 10 minutes. Names, contacts, and message text are not broadcast.'**
  String get sosBluetoothTenMinuteLimit;

  /// No description provided for @sosBluetoothUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth SOS is unavailable on this device or Bluetooth is disabled.'**
  String get sosBluetoothUnavailable;

  /// No description provided for @sosBluetoothPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Nearby-device and notification permissions are required before Bluetooth SOS can be used.'**
  String get sosBluetoothPermissionRequired;

  /// No description provided for @sosBluetoothPermissionSettings.
  ///
  /// In en, this message translates to:
  /// **'Check Bluetooth and notification permissions in app settings.'**
  String get sosBluetoothPermissionSettings;

  /// No description provided for @sosBluetoothDisabled.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is turned off. Turn it on and try again.'**
  String get sosBluetoothDisabled;

  /// No description provided for @sosBluetoothReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive nearby SOS alerts'**
  String get sosBluetoothReceiveTitle;

  /// No description provided for @sosBluetoothReceiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Listen while this screen is open. Received events are unverified and do not confirm rescue response.'**
  String get sosBluetoothReceiveDescription;

  /// No description provided for @sosBluetoothBackgroundReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive SOS alerts in the background'**
  String get sosBluetoothBackgroundReceiveTitle;

  /// No description provided for @sosBluetoothBackgroundReceiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep an Android receiver active when SafeMyanmar is not open. It uses a persistent notification, stores only validated temporary frames, and does not relay them.'**
  String get sosBluetoothBackgroundReceiveDescription;

  /// No description provided for @sosBluetoothRelayTitle.
  ///
  /// In en, this message translates to:
  /// **'Relay nearby SOS alerts once'**
  String get sosBluetoothRelayTitle;

  /// No description provided for @sosBluetoothRelayDescription.
  ///
  /// In en, this message translates to:
  /// **'Explicitly allow this device to rebroadcast each valid nearby SOS frame one time over Bluetooth only. Nothing is uploaded.'**
  String get sosBluetoothRelayDescription;

  /// No description provided for @sosBluetoothRelayCount.
  ///
  /// In en, this message translates to:
  /// **'Relayed frames this session: {count}'**
  String sosBluetoothRelayCount(int count);

  /// No description provided for @sosBluetoothSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound an alert'**
  String get sosBluetoothSoundTitle;

  /// No description provided for @sosBluetoothSoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow an optional sound when a nearby unverified SOS is detected.'**
  String get sosBluetoothSoundDescription;

  /// No description provided for @sosBluetoothBroadcasting.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth SOS is broadcasting limited data.'**
  String get sosBluetoothBroadcasting;

  /// No description provided for @sosBluetoothBroadcastFrameDetails.
  ///
  /// In en, this message translates to:
  /// **'Broadcast frame details'**
  String get sosBluetoothBroadcastFrameDetails;

  /// No description provided for @sosBluetoothStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get sosBluetoothStop;

  /// No description provided for @sosBluetoothNearbyAlert.
  ///
  /// In en, this message translates to:
  /// **'Nearby unverified SOS'**
  String get sosBluetoothNearbyAlert;

  /// No description provided for @sosBluetoothDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss nearby SOS'**
  String get sosBluetoothDismiss;

  /// No description provided for @sosBluetoothUnverified.
  ///
  /// In en, this message translates to:
  /// **'Peer-received; delivery to rescue services is not confirmed.'**
  String get sosBluetoothUnverified;

  /// No description provided for @sosBluetoothGridLocation.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: {latitude}, {longitude}'**
  String sosBluetoothGridLocation(String latitude, String longitude);

  /// No description provided for @sosBluetoothCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Reported as current when the SOS was prepared.'**
  String get sosBluetoothCurrentLocation;

  /// No description provided for @sosBluetoothLastKnownLocation.
  ///
  /// In en, this message translates to:
  /// **'Reported as last known when the SOS was prepared.'**
  String get sosBluetoothLastKnownLocation;

  /// No description provided for @sosBluetoothLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location was unavailable.'**
  String get sosBluetoothLocationUnavailable;

  /// No description provided for @sosBluetoothUnknownValue.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get sosBluetoothUnknownValue;

  /// No description provided for @sosBluetoothEventId.
  ///
  /// In en, this message translates to:
  /// **'Event ID: {id}'**
  String sosBluetoothEventId(String id);

  /// No description provided for @sosBluetoothTimestamp.
  ///
  /// In en, this message translates to:
  /// **'UTC time: {time}'**
  String sosBluetoothTimestamp(String time);

  /// No description provided for @sosBluetoothBatteryValue.
  ///
  /// In en, this message translates to:
  /// **'Battery: {value}%'**
  String sosBluetoothBatteryValue(int value);

  /// No description provided for @sosBluetoothRssiValue.
  ///
  /// In en, this message translates to:
  /// **'Signal: {value} dBm; proximity is approximate'**
  String sosBluetoothRssiValue(int value);

  /// No description provided for @sosBluetoothProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol: v{version}; TTL: {ttl} minutes'**
  String sosBluetoothProtocol(int version, int ttl);

  /// No description provided for @sosBluetoothRelayHops.
  ///
  /// In en, this message translates to:
  /// **'Relay hops: {count}'**
  String sosBluetoothRelayHops(int count);

  /// No description provided for @sosBluetoothApproximateNotice.
  ///
  /// In en, this message translates to:
  /// **'Coordinates are supplied by the peer device and are unverified.'**
  String get sosBluetoothApproximateNotice;

  /// No description provided for @sosBluetoothMapsLink.
  ///
  /// In en, this message translates to:
  /// **'Google Maps: {url}'**
  String sosBluetoothMapsLink(String url);

  /// No description provided for @sosBluetoothOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get sosBluetoothOpenMaps;

  /// No description provided for @sosBluetoothShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all SOS markers'**
  String get sosBluetoothShowAll;

  /// No description provided for @sosBluetoothMapEventsHeading.
  ///
  /// In en, this message translates to:
  /// **'Nearby SOS sources'**
  String get sosBluetoothMapEventsHeading;

  /// No description provided for @sosBluetoothSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'SOS source {index}'**
  String sosBluetoothSourceLabel(Object index);

  /// No description provided for @sosBluetoothSelectedEventHeading.
  ///
  /// In en, this message translates to:
  /// **'Selected SOS details'**
  String get sosBluetoothSelectedEventHeading;

  /// No description provided for @sosBluetoothSelectEvent.
  ///
  /// In en, this message translates to:
  /// **'Select nearby SOS {index}'**
  String sosBluetoothSelectEvent(int index);

  /// No description provided for @sosBluetoothBroadcastStarted.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth SOS sharing is active for up to 10 minutes.'**
  String get sosBluetoothBroadcastStarted;

  /// No description provided for @sosBluetoothBroadcastFailed.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth SOS sharing could not be started. No nearby data was broadcast.'**
  String get sosBluetoothBroadcastFailed;

  /// No description provided for @sosBluetoothOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is disabled or the nearby-device operation could not be started.'**
  String get sosBluetoothOperationFailed;

  /// No description provided for @chooseDisasterType.
  ///
  /// In en, this message translates to:
  /// **'Disaster type'**
  String get chooseDisasterType;

  /// No description provided for @chooseTravelProfile.
  ///
  /// In en, this message translates to:
  /// **'Travel profile'**
  String get chooseTravelProfile;

  /// No description provided for @earthquakeDisaster.
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get earthquakeDisaster;

  /// No description provided for @floodDisaster.
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get floodDisaster;

  /// No description provided for @fireDisaster.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get fireDisaster;

  /// No description provided for @cycloneDisaster.
  ///
  /// In en, this message translates to:
  /// **'Cyclone'**
  String get cycloneDisaster;

  /// No description provided for @landslideDisaster.
  ///
  /// In en, this message translates to:
  /// **'Landslide'**
  String get landslideDisaster;

  /// No description provided for @severeWeatherDisaster.
  ///
  /// In en, this message translates to:
  /// **'Severe weather'**
  String get severeWeatherDisaster;

  /// No description provided for @walkingProfile.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get walkingProfile;

  /// No description provided for @drivingProfile.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get drivingProfile;

  /// No description provided for @requestRouteSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Request route suggestions'**
  String get requestRouteSuggestions;

  /// No description provided for @retryRouteSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Retry route suggestions'**
  String get retryRouteSuggestions;

  /// No description provided for @updatingRouteSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Requesting route suggestions'**
  String get updatingRouteSuggestions;

  /// No description provided for @routingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route suggestions could not be updated. Shelters and hazards remain visible; try again.'**
  String get routingUnavailable;

  /// No description provided for @cachedRouteWarning.
  ///
  /// In en, this message translates to:
  /// **'A previously loaded route response remains visible and is stale.'**
  String get cachedRouteWarning;

  /// No description provided for @cachedRouteAt.
  ///
  /// In en, this message translates to:
  /// **'Route saved at: {time}'**
  String cachedRouteAt(String time);

  /// No description provided for @noRoutesReturned.
  ///
  /// In en, this message translates to:
  /// **'The server returned no route options. No alternative was created by SafeMyanmar.'**
  String get noRoutesReturned;

  /// No description provided for @routeSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get routeSuggested;

  /// No description provided for @routeAlternative.
  ///
  /// In en, this message translates to:
  /// **'Alternative {number}'**
  String routeAlternative(int number);

  /// No description provided for @routeSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected route'**
  String get routeSelected;

  /// No description provided for @routeProfileValue.
  ///
  /// In en, this message translates to:
  /// **'Profile: {profile}'**
  String routeProfileValue(String profile);

  /// No description provided for @routeDistanceValue.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} m'**
  String routeDistanceValue(String distance);

  /// No description provided for @routeDurationValue.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration} min'**
  String routeDurationValue(String duration);

  /// No description provided for @routeHazardIntersections.
  ///
  /// In en, this message translates to:
  /// **'Hazard intersections: {count}'**
  String routeHazardIntersections(int count);

  /// No description provided for @routeRationale.
  ///
  /// In en, this message translates to:
  /// **'Rationale: {rationale}'**
  String routeRationale(String rationale);

  /// No description provided for @routeGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated: {time}'**
  String routeGeneratedAt(String time);

  /// No description provided for @routeHazardDataAt.
  ///
  /// In en, this message translates to:
  /// **'Hazard data: {time}'**
  String routeHazardDataAt(String time);

  /// No description provided for @routeDirectionsProvider.
  ///
  /// In en, this message translates to:
  /// **'Directions provider: {provider}'**
  String routeDirectionsProvider(String provider);

  /// No description provided for @routeProfileReason.
  ///
  /// In en, this message translates to:
  /// **'Profile selection: {reason}'**
  String routeProfileReason(String reason);

  /// No description provided for @uncertaintyNotice.
  ///
  /// In en, this message translates to:
  /// **'Uncertainty: {notice}'**
  String uncertaintyNotice(String notice);

  /// No description provided for @mapSuggestedSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested selected route'**
  String get mapSuggestedSelectedLabel;

  /// No description provided for @mapAlternativeLabel.
  ///
  /// In en, this message translates to:
  /// **'Alternative {number}'**
  String mapAlternativeLabel(int number);

  /// No description provided for @sosTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosTitle;

  /// No description provided for @sosIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Prepare an emergency SMS for people you selected. Opening this screen does not prepare or send anything.'**
  String get sosIntroduction;

  /// No description provided for @sosSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS setup'**
  String get sosSetupTitle;

  /// No description provided for @sosSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Review contacts, optional message, location sharing, and the exact message before confirming.'**
  String get sosSetupDescription;

  /// No description provided for @sosReadinessReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to review'**
  String get sosReadinessReady;

  /// No description provided for @sosReadinessNeedsContact.
  ///
  /// In en, this message translates to:
  /// **'Select an emergency contact first'**
  String get sosReadinessNeedsContact;

  /// No description provided for @sosReadinessLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable; continue without coordinates'**
  String get sosReadinessLocationUnavailable;

  /// No description provided for @sosRecipientsHeading.
  ///
  /// In en, this message translates to:
  /// **'Selected recipients'**
  String get sosRecipientsHeading;

  /// No description provided for @sosRecipientPreview.
  ///
  /// In en, this message translates to:
  /// **'{name}: {phoneNumber}'**
  String sosRecipientPreview(String name, String phoneNumber);

  /// No description provided for @sosNoRecipientsTitle.
  ///
  /// In en, this message translates to:
  /// **'No contacts selected'**
  String get sosNoRecipientsTitle;

  /// No description provided for @sosNoRecipientsDescription.
  ///
  /// In en, this message translates to:
  /// **'Select at least one saved emergency contact before preparing an SOS draft.'**
  String get sosNoRecipientsDescription;

  /// No description provided for @sosManageContacts.
  ///
  /// In en, this message translates to:
  /// **'Open More contacts'**
  String get sosManageContacts;

  /// No description provided for @sosSharedDataHeading.
  ///
  /// In en, this message translates to:
  /// **'Exact SMS preview'**
  String get sosSharedDataHeading;

  /// No description provided for @sosStoredDataHeading.
  ///
  /// In en, this message translates to:
  /// **'Draft details stored securely'**
  String get sosStoredDataHeading;

  /// No description provided for @sosProfileNamePreview.
  ///
  /// In en, this message translates to:
  /// **'Profile name: {name}'**
  String sosProfileNamePreview(String name);

  /// No description provided for @sosProfileNameUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile name: Not included'**
  String get sosProfileNameUnavailable;

  /// No description provided for @sosCurrentLocationPreview.
  ///
  /// In en, this message translates to:
  /// **'Current {precision} location: {latitude}, {longitude}. Captured {time}.'**
  String sosCurrentLocationPreview(
    String precision,
    String latitude,
    String longitude,
    String time,
  );

  /// No description provided for @sosLastKnownLocationPreview.
  ///
  /// In en, this message translates to:
  /// **'Last-known {precision} location: {latitude}, {longitude}. Captured {time}.'**
  String sosLastKnownLocationPreview(
    String precision,
    String latitude,
    String longitude,
    String time,
  );

  /// No description provided for @sosLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable. No coordinates will be included.'**
  String get sosLocationUnavailable;

  /// No description provided for @sosPrecise.
  ///
  /// In en, this message translates to:
  /// **'precise'**
  String get sosPrecise;

  /// No description provided for @sosApproximate.
  ///
  /// In en, this message translates to:
  /// **'approximate'**
  String get sosApproximate;

  /// No description provided for @sosDraftCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created: {time}'**
  String sosDraftCreatedAt(String time);

  /// No description provided for @sosDraftCreatedWhenConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Created time will be recorded when you confirm.'**
  String get sosDraftCreatedWhenConfirmed;

  /// No description provided for @sosOptionalMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional concise message'**
  String get sosOptionalMessageLabel;

  /// No description provided for @sosOptionalMessageHint.
  ///
  /// In en, this message translates to:
  /// **'For example: I need help leaving this area.'**
  String get sosOptionalMessageHint;

  /// No description provided for @sosLocationSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Include location in this SOS'**
  String get sosLocationSharingTitle;

  /// No description provided for @sosLocationSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'Location is not shared unless you enable it for this SOS. Your existing location permission will be reused.'**
  String get sosLocationSharingDescription;

  /// No description provided for @sosLocationSharingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location could not be obtained. This SOS will not include coordinates.'**
  String get sosLocationSharingUnavailable;

  /// No description provided for @sosLocationSharingUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get sosLocationSharingUnavailableTitle;

  /// No description provided for @sosLocationSharingUnavailableDescription.
  ///
  /// In en, this message translates to:
  /// **'The SOS can still be prepared without coordinates. Continue without sharing a location?'**
  String get sosLocationSharingUnavailableDescription;

  /// No description provided for @sosContinueWithoutLocation.
  ///
  /// In en, this message translates to:
  /// **'Continue without location'**
  String get sosContinueWithoutLocation;

  /// No description provided for @sosComposerDisclosure.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar only opens your phone\'s messaging app. That app controls SMS transmission and delivery, and SafeMyanmar cannot verify either.'**
  String get sosComposerDisclosure;

  /// No description provided for @sosDirectSmsDisclosure.
  ///
  /// In en, this message translates to:
  /// **'After confirmation, SafeMyanmar requests SMS permission and sends the reviewed message directly through Android. The carrier may still delay delivery; SafeMyanmar can confirm only whether the device accepted the SMS.'**
  String get sosDirectSmsDisclosure;

  /// No description provided for @sosHoldToOpen.
  ///
  /// In en, this message translates to:
  /// **'Hold for 3 seconds to send SMS'**
  String get sosHoldToOpen;

  /// No description provided for @sosHoldProgress.
  ///
  /// In en, this message translates to:
  /// **'Keep holding: {percent}%'**
  String sosHoldProgress(int percent);

  /// No description provided for @sosHoldCancelled.
  ///
  /// In en, this message translates to:
  /// **'Hold cancelled. Nothing was sent.'**
  String get sosHoldCancelled;

  /// No description provided for @sosHoldSemanticsHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold continuously for 3 seconds. Activate for an accessible confirmation path.'**
  String get sosHoldSemanticsHint;

  /// No description provided for @sosAccessibleConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Use confirmation dialogs instead'**
  String get sosAccessibleConfirmation;

  /// No description provided for @sosConfirmPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm SOS draft details'**
  String get sosConfirmPreviewTitle;

  /// No description provided for @sosConfirmPreviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the recipients and exact SMS preview on this screen. Continue only if you want to prepare this draft.'**
  String get sosConfirmPreviewDescription;

  /// No description provided for @sosContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get sosContinue;

  /// No description provided for @sosConfirmComposerTitle.
  ///
  /// In en, this message translates to:
  /// **'Open the messaging app?'**
  String get sosConfirmComposerTitle;

  /// No description provided for @sosConfirmComposerDescription.
  ///
  /// In en, this message translates to:
  /// **'This second confirmation prepares the secure draft and asks your phone to open its messaging app with the recipients and body filled in. You must choose whether to send it there.'**
  String get sosConfirmComposerDescription;

  /// No description provided for @sosOpenMessaging.
  ///
  /// In en, this message translates to:
  /// **'Prepare and open messaging'**
  String get sosOpenMessaging;

  /// No description provided for @sosConfirmSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Send SOS SMS directly?'**
  String get sosConfirmSmsTitle;

  /// No description provided for @sosConfirmSmsDescription.
  ///
  /// In en, this message translates to:
  /// **'This second confirmation prepares the secure draft and sends the reviewed SMS directly to the selected contacts after Android SMS permission is granted. Device acceptance does not guarantee carrier delivery.'**
  String get sosConfirmSmsDescription;

  /// No description provided for @sosSendSms.
  ///
  /// In en, this message translates to:
  /// **'Send SMS now'**
  String get sosSendSms;

  /// No description provided for @sosRetrySmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Send this SOS draft again?'**
  String get sosRetrySmsTitle;

  /// No description provided for @sosRetrySmsDescription.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar will send this saved message directly through Android SMS. Device acceptance does not guarantee carrier delivery.'**
  String get sosRetrySmsDescription;

  /// No description provided for @sosRetrySmsUncertainDescription.
  ///
  /// In en, this message translates to:
  /// **'The previous SMS attempt has a partial or unknown result. Retrying can create duplicate messages, so continue only if that risk is acceptable.'**
  String get sosRetrySmsUncertainDescription;

  /// No description provided for @sosNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get sosNotNow;

  /// No description provided for @sosComposerOpenedNotice.
  ///
  /// In en, this message translates to:
  /// **'Messaging was opened. SafeMyanmar cannot verify SMS transmission or delivery. The draft is retained for retry or removal.'**
  String get sosComposerOpenedNotice;

  /// No description provided for @sosComposerFailedNotice.
  ///
  /// In en, this message translates to:
  /// **'The messaging app could not be opened. The prepared draft was retained so you can retry or remove it.'**
  String get sosComposerFailedNotice;

  /// No description provided for @sosDraftSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The SOS draft could not be saved securely. No SMS was sent.'**
  String get sosDraftSaveFailed;

  /// No description provided for @sosSmsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'SMS permission was not granted. No SMS was sent; the draft was retained for retry.'**
  String get sosSmsPermissionDenied;

  /// No description provided for @sosSmsSentNotice.
  ///
  /// In en, this message translates to:
  /// **'The device accepted the SMS for sending. Carrier delivery is not confirmed; the draft was retained.'**
  String get sosSmsSentNotice;

  /// No description provided for @sosSmsFailedNotice.
  ///
  /// In en, this message translates to:
  /// **'The device could not accept the SMS. Check SIM/service and SMS permission, then retry the draft.'**
  String get sosSmsFailedNotice;

  /// No description provided for @sosSmsUncertainNotice.
  ///
  /// In en, this message translates to:
  /// **'The SMS result was partial or unknown. Some messages may have been accepted; retrying can create duplicates.'**
  String get sosSmsUncertainNotice;

  /// No description provided for @sosSimUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No active SIM could be selected. Check your SIM service and try again. No SMS was sent.'**
  String get sosSimUnavailable;

  /// No description provided for @sosChooseSimTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose SIM'**
  String get sosChooseSimTitle;

  /// No description provided for @sosChooseSimDescription.
  ///
  /// In en, this message translates to:
  /// **'Select which active SIM should send this SOS message.'**
  String get sosChooseSimDescription;

  /// No description provided for @sosRememberSim.
  ///
  /// In en, this message translates to:
  /// **'Remember my preferred SIM'**
  String get sosRememberSim;

  /// No description provided for @sosSendUsingSim.
  ///
  /// In en, this message translates to:
  /// **'Send using SIM'**
  String get sosSendUsingSim;

  /// No description provided for @sosSimLabel.
  ///
  /// In en, this message translates to:
  /// **'SIM {slot}: {label}'**
  String sosSimLabel(int slot, String label);

  /// No description provided for @sosMaximumDrafts.
  ///
  /// In en, this message translates to:
  /// **'The secure SOS queue already has 5 drafts. Remove one before preparing another.'**
  String get sosMaximumDrafts;

  /// No description provided for @sosDraftQueueHeading.
  ///
  /// In en, this message translates to:
  /// **'SOS drafts and history'**
  String get sosDraftQueueHeading;

  /// No description provided for @sosDraftQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No SOS drafts have been prepared on this device.'**
  String get sosDraftQueueEmpty;

  /// No description provided for @sosStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String sosStatusLabel(String status);

  /// No description provided for @sosStatusPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get sosStatusPrepared;

  /// No description provided for @sosStatusSmsSending.
  ///
  /// In en, this message translates to:
  /// **'Sending SMS'**
  String get sosStatusSmsSending;

  /// No description provided for @sosStatusSmsSent.
  ///
  /// In en, this message translates to:
  /// **'SMS accepted by device; delivery unconfirmed'**
  String get sosStatusSmsSent;

  /// No description provided for @sosStatusSmsPartial.
  ///
  /// In en, this message translates to:
  /// **'SMS partially accepted; delivery unconfirmed'**
  String get sosStatusSmsPartial;

  /// No description provided for @sosStatusSmsUnknown.
  ///
  /// In en, this message translates to:
  /// **'SMS result unknown; retry may duplicate'**
  String get sosStatusSmsUnknown;

  /// No description provided for @sosStatusSmsFailed.
  ///
  /// In en, this message translates to:
  /// **'SMS failed; retry available'**
  String get sosStatusSmsFailed;

  /// No description provided for @sosStatusComposerOpened.
  ///
  /// In en, this message translates to:
  /// **'Messaging app opened; outcome unknown'**
  String get sosStatusComposerOpened;

  /// No description provided for @sosStatusFailedToOpen.
  ///
  /// In en, this message translates to:
  /// **'Messaging app failed to open'**
  String get sosStatusFailedToOpen;

  /// No description provided for @sosStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get sosStatusCancelled;

  /// No description provided for @sosOpenAgain.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get sosOpenAgain;

  /// No description provided for @sosCancelDraft.
  ///
  /// In en, this message translates to:
  /// **'Cancel draft'**
  String get sosCancelDraft;

  /// No description provided for @sosRemoveDraft.
  ///
  /// In en, this message translates to:
  /// **'Remove draft'**
  String get sosRemoveDraft;

  /// No description provided for @sosRetryComposerTitle.
  ///
  /// In en, this message translates to:
  /// **'Open this draft again?'**
  String get sosRetryComposerTitle;

  /// No description provided for @sosRetryComposerDescription.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar will ask your phone to open messaging with this saved draft. You must choose whether to send it there.'**
  String get sosRetryComposerDescription;

  /// No description provided for @sosCancelDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this draft?'**
  String get sosCancelDraftTitle;

  /// No description provided for @sosCancelDraftDescription.
  ///
  /// In en, this message translates to:
  /// **'The draft will remain in history with a Cancelled status and will not open automatically.'**
  String get sosCancelDraftDescription;

  /// No description provided for @sosRemoveDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this draft?'**
  String get sosRemoveDraftTitle;

  /// No description provided for @sosRemoveDraftDescription.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the draft snapshot from secure storage on this device.'**
  String get sosRemoveDraftDescription;

  /// No description provided for @sosQueueLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading secure SOS drafts'**
  String get sosQueueLoading;

  /// No description provided for @sosQueueReadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS drafts temporarily unavailable'**
  String get sosQueueReadErrorTitle;

  /// No description provided for @sosQueueReadErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar could not read the secure SOS queue. No private draft details were exposed. Try again.'**
  String get sosQueueReadErrorDescription;

  /// No description provided for @sosQueueDataErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Stored SOS drafts cannot be opened'**
  String get sosQueueDataErrorTitle;

  /// No description provided for @sosQueueDataErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'The secure SOS queue is damaged or uses an unsupported version. It has not been changed. Retry, or reset only this queue.'**
  String get sosQueueDataErrorDescription;

  /// No description provided for @sosQueueWriteErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS draft change was not saved'**
  String get sosQueueWriteErrorTitle;

  /// No description provided for @sosQueueWriteErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'The previously saved SOS queue remains available. Try the change again.'**
  String get sosQueueWriteErrorDescription;

  /// No description provided for @sosResetQueue.
  ///
  /// In en, this message translates to:
  /// **'Reset SOS queue'**
  String get sosResetQueue;

  /// No description provided for @sosResetQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset unreadable SOS queue?'**
  String get sosResetQueueTitle;

  /// No description provided for @sosResetQueueDescription.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes only the unreadable SOS drafts from this device. Your profile and contacts remain unchanged.'**
  String get sosResetQueueDescription;

  /// No description provided for @sosMessageHeader.
  ///
  /// In en, this message translates to:
  /// **'User-prepared SafeMyanmar emergency message.'**
  String get sosMessageHeader;

  /// No description provided for @sosMessageProfileName.
  ///
  /// In en, this message translates to:
  /// **'Profile name: {name}'**
  String sosMessageProfileName(String name);

  /// No description provided for @sosMessageCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current {precision} location: {latitude}, {longitude} at {time}. Map: {mapsLink}'**
  String sosMessageCurrentLocation(
    String precision,
    String latitude,
    String longitude,
    String time,
    String mapsLink,
  );

  /// No description provided for @sosMessageLastKnownLocation.
  ///
  /// In en, this message translates to:
  /// **'Last-known {precision} location: {latitude}, {longitude} at {time}. Map: {mapsLink}'**
  String sosMessageLastKnownLocation(
    String precision,
    String latitude,
    String longitude,
    String time,
    String mapsLink,
  );

  /// No description provided for @sosMessageLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable; no coordinates included.'**
  String get sosMessageLocationUnavailable;

  /// No description provided for @sosMessageUserText.
  ///
  /// In en, this message translates to:
  /// **'Message: {message}'**
  String sosMessageUserText(String message);

  /// No description provided for @sosMessageAuthorizedHelp.
  ///
  /// In en, this message translates to:
  /// **'Please contact authorized emergency or medical help when possible.'**
  String get sosMessageAuthorizedHelp;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guideTitle;

  /// No description provided for @guideIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Search a small, reviewed emergency guide stored on this device. It works without a network connection.'**
  String get guideIntroduction;

  /// No description provided for @guideOfflineVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline verified-content retrieval'**
  String get guideOfflineVerifiedLabel;

  /// No description provided for @guideQuickActionsHeading.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get guideQuickActionsHeading;

  /// No description provided for @guideActionEarthquake.
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get guideActionEarthquake;

  /// No description provided for @guideActionFlood.
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get guideActionFlood;

  /// No description provided for @guideActionFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get guideActionFire;

  /// No description provided for @guideActionFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First aid'**
  String get guideActionFirstAid;

  /// No description provided for @guideActionMap.
  ///
  /// In en, this message translates to:
  /// **'Open Map'**
  String get guideActionMap;

  /// No description provided for @guideActionSos.
  ///
  /// In en, this message translates to:
  /// **'Open SOS'**
  String get guideActionSos;

  /// No description provided for @guideNextStepsHeading.
  ///
  /// In en, this message translates to:
  /// **'Next steps'**
  String get guideNextStepsHeading;

  /// No description provided for @guideNextStepMap.
  ///
  /// In en, this message translates to:
  /// **'Check Map'**
  String get guideNextStepMap;

  /// No description provided for @guideNextStepSos.
  ///
  /// In en, this message translates to:
  /// **'Review SOS'**
  String get guideNextStepSos;

  /// No description provided for @guideNextStepAssistant.
  ///
  /// In en, this message translates to:
  /// **'Ask assistant'**
  String get guideNextStepAssistant;

  /// No description provided for @guideAskAssistant.
  ///
  /// In en, this message translates to:
  /// **'Ask the constrained assistant'**
  String get guideAskAssistant;

  /// No description provided for @guideSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search emergency guidance'**
  String get guideSearchLabel;

  /// No description provided for @guideSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Earthquake, trapped, flood, fire, first aid'**
  String get guideSearchHint;

  /// No description provided for @guideSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get guideSearchAction;

  /// No description provided for @guideCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get guideCategories;

  /// No description provided for @guideCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get guideCategoryAll;

  /// No description provided for @guideCategoryEarthquake.
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get guideCategoryEarthquake;

  /// No description provided for @guideCategoryFlood.
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get guideCategoryFlood;

  /// No description provided for @guideCategoryFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get guideCategoryFire;

  /// No description provided for @guideCategoryFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First aid'**
  String get guideCategoryFirstAid;

  /// No description provided for @guideLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading offline emergency guidance'**
  String get guideLoading;

  /// No description provided for @guideNoResults.
  ///
  /// In en, this message translates to:
  /// **'No approved offline article matched this search.'**
  String get guideNoResults;

  /// No description provided for @guideStorageError.
  ///
  /// In en, this message translates to:
  /// **'Offline guidance could not be read from this device.'**
  String get guideStorageError;

  /// No description provided for @guideArticleTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency guide'**
  String get guideArticleTitle;

  /// No description provided for @guideArticleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This approved offline article is unavailable.'**
  String get guideArticleUnavailable;

  /// No description provided for @guideOpenArticleHint.
  ///
  /// In en, this message translates to:
  /// **'Open approved emergency article'**
  String get guideOpenArticleHint;

  /// No description provided for @guideApprovedSource.
  ///
  /// In en, this message translates to:
  /// **'Approved source record'**
  String get guideApprovedSource;

  /// No description provided for @guideSourceName.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String guideSourceName(String source);

  /// No description provided for @guideContentVersion.
  ///
  /// In en, this message translates to:
  /// **'Content version: {version}'**
  String guideContentVersion(int version);

  /// No description provided for @guideReviewedDate.
  ///
  /// In en, this message translates to:
  /// **'Reviewed: {date}'**
  String guideReviewedDate(String date);

  /// No description provided for @guideSourceDate.
  ///
  /// In en, this message translates to:
  /// **'Source updated: {date}'**
  String guideSourceDate(String date);

  /// No description provided for @guideContentWarning.
  ///
  /// In en, this message translates to:
  /// **'Emergency information may not cover every situation. Follow authorized local instructions and contact authorized local emergency or medical services when possible.'**
  String get guideContentWarning;

  /// No description provided for @guideSourceSemantics.
  ///
  /// In en, this message translates to:
  /// **'Approved source {source}, content version {version}'**
  String guideSourceSemantics(String source, int version);

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline assistant'**
  String get assistantTitle;

  /// No description provided for @assistantOfflineVerified.
  ///
  /// In en, this message translates to:
  /// **'Offline verified-content retrieval (source-backed, not generative)'**
  String get assistantOfflineVerified;

  /// No description provided for @assistantDeterministicActive.
  ///
  /// In en, this message translates to:
  /// **'Deterministic offline verified-content retrieval is active.'**
  String get assistantDeterministicActive;

  /// No description provided for @assistantOnnxChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking optional ONNX intent refinement availability.'**
  String get assistantOnnxChecking;

  /// No description provided for @assistantOnnxAvailable.
  ///
  /// In en, this message translates to:
  /// **'Optional ONNX intent refinement is available for deterministic unknown results.'**
  String get assistantOnnxAvailable;

  /// No description provided for @assistantOnnxUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Optional ONNX intent refinement is unavailable. Missing optional models are normal; deterministic retrieval remains active.'**
  String get assistantOnnxUnavailable;

  /// No description provided for @assistantGemmaChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking optional Gemma 3 local assistant availability.'**
  String get assistantGemmaChecking;

  /// No description provided for @assistantGemmaAvailable.
  ///
  /// In en, this message translates to:
  /// **'Optional local Gemma 3 can answer general questions, with extra focus on disaster and preparedness topics.'**
  String get assistantGemmaAvailable;

  /// No description provided for @assistantGemmaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Optional local Gemma 3 is unavailable. Missing model files are normal; deterministic approved content remains available.'**
  String get assistantGemmaUnavailable;

  /// No description provided for @assistantSuggestedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Suggested questions'**
  String get assistantSuggestedQuestions;

  /// No description provided for @assistantSuggestionEarthquake.
  ///
  /// In en, this message translates to:
  /// **'What should I do during an earthquake?'**
  String get assistantSuggestionEarthquake;

  /// No description provided for @assistantSuggestionTrapped.
  ///
  /// In en, this message translates to:
  /// **'I am trapped after an earthquake'**
  String get assistantSuggestionTrapped;

  /// No description provided for @assistantSuggestionFirstAid.
  ///
  /// In en, this message translates to:
  /// **'What should I check before giving first aid?'**
  String get assistantSuggestionFirstAid;

  /// No description provided for @assistantSuggestionFlood.
  ///
  /// In en, this message translates to:
  /// **'How do I avoid floodwater?'**
  String get assistantSuggestionFlood;

  /// No description provided for @assistantSearching.
  ///
  /// In en, this message translates to:
  /// **'Preparing an offline answer'**
  String get assistantSearching;

  /// No description provided for @assistantInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency question'**
  String get assistantInputLabel;

  /// No description provided for @assistantInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type in English or Burmese'**
  String get assistantInputHint;

  /// No description provided for @assistantSend.
  ///
  /// In en, this message translates to:
  /// **'Send question'**
  String get assistantSend;

  /// No description provided for @assistantVerifiedAnswer.
  ///
  /// In en, this message translates to:
  /// **'Retrieved approved content'**
  String get assistantVerifiedAnswer;

  /// No description provided for @assistantConfidence.
  ///
  /// In en, this message translates to:
  /// **'Intent confidence: {confidence}%\n{explanation}'**
  String assistantConfidence(int confidence, String explanation);

  /// No description provided for @assistantClassifierMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched weighted offline terms: {terms}. No machine-learning model was used.'**
  String assistantClassifierMatched(String terms);

  /// No description provided for @assistantClassifierLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'The closest offline match was below the confidence threshold. No machine-learning model was used.'**
  String get assistantClassifierLowConfidence;

  /// No description provided for @assistantClassifierNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No approved offline intent terms matched. No machine-learning model was used.'**
  String get assistantClassifierNoMatch;

  /// No description provided for @assistantClassifierOnnx.
  ///
  /// In en, this message translates to:
  /// **'The deterministic classifier returned unknown, then the optional local ONNX classifier recognized this intent at or above the safety threshold.'**
  String get assistantClassifierOnnx;

  /// No description provided for @assistantClassifierGemma.
  ///
  /// In en, this message translates to:
  /// **'Answered by the optional local Gemma 3 model. Relevant disaster guidance is grounded in approved offline content when available.'**
  String get assistantClassifierGemma;

  /// No description provided for @assistantEngineDeterministic.
  ///
  /// In en, this message translates to:
  /// **'Response engine: deterministic offline classifier'**
  String get assistantEngineDeterministic;

  /// No description provided for @assistantEngineOnnx.
  ///
  /// In en, this message translates to:
  /// **'Response engine: optional local ONNX intent classifier'**
  String get assistantEngineOnnx;

  /// No description provided for @assistantEngineGemma.
  ///
  /// In en, this message translates to:
  /// **'Response engine: local Gemma 3 assistant'**
  String get assistantEngineGemma;

  /// No description provided for @assistantGemmaAnswerTitle.
  ///
  /// In en, this message translates to:
  /// **'Gemma 3 answer'**
  String get assistantGemmaAnswerTitle;

  /// No description provided for @assistantLocalRewordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional local rewording'**
  String get assistantLocalRewordingTitle;

  /// No description provided for @assistantLocalRewordingWarning.
  ///
  /// In en, this message translates to:
  /// **'Model-generated wording may be inaccurate. Verify it against the exact source-backed guidance shown above.'**
  String get assistantLocalRewordingWarning;

  /// No description provided for @assistantLocalRewordingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Optional model-generated local rewording. {text} Warning: verify against the exact source-backed guidance.'**
  String assistantLocalRewordingSemantics(String text);

  /// No description provided for @assistantMapResponse.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar does not calculate routes in the assistant. Open Map to view available shelters and request uncertain, timestamped route suggestions.'**
  String get assistantMapResponse;

  /// No description provided for @assistantSosResponse.
  ///
  /// In en, this message translates to:
  /// **'The assistant cannot activate or send an SOS. Open SOS to review recipients, information, and explicit confirmation controls.'**
  String get assistantSosResponse;

  /// No description provided for @assistantMissingResponse.
  ///
  /// In en, this message translates to:
  /// **'No approved missing-person procedure is available in this Tier 1 offline set. Contact authorized local services and share personal information only with trusted recipients.'**
  String get assistantMissingResponse;

  /// No description provided for @assistantDamageResponse.
  ///
  /// In en, this message translates to:
  /// **'No approved damage-report procedure is available in this Tier 1 offline set. Do not enter a damaged building to collect information.'**
  String get assistantDamageResponse;

  /// No description provided for @assistantUnknownResponse.
  ///
  /// In en, this message translates to:
  /// **'I could not confidently match that question to approved offline content. Try a suggested question or browse the Guide categories.'**
  String get assistantUnknownResponse;

  /// No description provided for @assistantUnavailableResponse.
  ///
  /// In en, this message translates to:
  /// **'Approved offline content for that request is unavailable.'**
  String get assistantUnavailableResponse;

  /// No description provided for @assistantReviewSos.
  ///
  /// In en, this message translates to:
  /// **'Open SOS for user review'**
  String get assistantReviewSos;

  /// No description provided for @assistantOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open Map'**
  String get assistantOpenMap;

  /// No description provided for @assistantSosDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Draft details extracted for your review'**
  String get assistantSosDraftTitle;

  /// No description provided for @assistantSosDraftWarning.
  ///
  /// In en, this message translates to:
  /// **'Draft only. Check every field. Nothing was sent and SOS was not activated.'**
  String get assistantSosDraftWarning;

  /// No description provided for @assistantDraftIncident.
  ///
  /// In en, this message translates to:
  /// **'Incident: {value}'**
  String assistantDraftIncident(String value);

  /// No description provided for @assistantDraftStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {value}'**
  String assistantDraftStatus(String value);

  /// No description provided for @assistantDraftInjury.
  ///
  /// In en, this message translates to:
  /// **'Injury text: {value}'**
  String assistantDraftInjury(String value);

  /// No description provided for @assistantDraftLocation.
  ///
  /// In en, this message translates to:
  /// **'Location phrase: {value}'**
  String assistantDraftLocation(String value);

  /// No description provided for @assistantDraftBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery: {value}%'**
  String assistantDraftBattery(int value);

  /// No description provided for @languageSettingsTitle.
  String get languageSettingsTitle;

  /// No description provided for @languageSettingsDescription.
  String get languageSettingsDescription;

  /// No description provided for @languageEnglish.
  String get languageEnglish;

  /// No description provided for @languageBurmese.
  String get languageBurmese;

  /// No description provided for @languageSaving.
  String get languageSaving;

  /// No description provided for @languageReadErrorTitle.
  String get languageReadErrorTitle;

  /// No description provided for @languageReadErrorDescription.
  String get languageReadErrorDescription;

  /// No description provided for @languageWriteErrorTitle.
  String get languageWriteErrorTitle;

  /// No description provided for @languageWriteErrorDescription.
  String get languageWriteErrorDescription;

  /// No description provided for @originalSourceTextNotice.
  String get originalSourceTextNotice;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @profileOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your local profile'**
  String get profileOverviewTitle;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Display name not set'**
  String get profileNotSet;

  /// No description provided for @profileLocalOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device'**
  String get profileLocalOnlyLabel;

  /// No description provided for @profileOverviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep a display name and the people you may choose to include in a future SOS message.'**
  String get profileOverviewDescription;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get emergencyContacts;

  /// No description provided for @contactsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} contacts, {selected} selected for SOS'**
  String contactsSummary(int count, int selected);

  /// No description provided for @manageContacts.
  ///
  /// In en, this message translates to:
  /// **'Manage contacts'**
  String get manageContacts;

  /// No description provided for @profilePrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Private by default'**
  String get profilePrivacyTitle;

  /// No description provided for @profilePrivacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Your profile and contacts are encrypted in secure device storage. SafeMyanmar does not read your device contacts, and saving a contact does not send an SOS message.'**
  String get profilePrivacyDescription;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @displayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a display name.'**
  String get displayNameRequired;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @profileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your local profile'**
  String get profileLoading;

  /// No description provided for @profileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving securely'**
  String get profileSaving;

  /// No description provided for @profileReadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile temporarily unavailable'**
  String get profileReadErrorTitle;

  /// No description provided for @profileReadErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'SafeMyanmar could not read secure local profile data. No profile details were exposed. Try again.'**
  String get profileReadErrorDescription;

  /// No description provided for @profileDataErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Stored profile cannot be opened'**
  String get profileDataErrorTitle;

  /// No description provided for @profileDataErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'The encrypted local profile is damaged or uses an unsupported version. It has not been changed. Retry, or reset it to start again.'**
  String get profileDataErrorDescription;

  /// No description provided for @profileWriteErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes were not saved'**
  String get profileWriteErrorTitle;

  /// No description provided for @profileWriteErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Your last securely saved profile remains available. Try saving the change again.'**
  String get profileWriteErrorDescription;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @resetLocalProfile.
  ///
  /// In en, this message translates to:
  /// **'Reset local profile'**
  String get resetLocalProfile;

  /// No description provided for @resetLocalProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset unreadable profile?'**
  String get resetLocalProfileTitle;

  /// No description provided for @resetLocalProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the unreadable local profile and emergency contacts from this device. This cannot be undone.'**
  String get resetLocalProfileDescription;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get contactsTitle;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get addContact;

  /// No description provided for @contactsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No emergency contacts yet'**
  String get contactsEmptyTitle;

  /// No description provided for @contactsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add people you trust, then choose who may be included in a future SOS message.'**
  String get contactsEmptyDescription;

  /// No description provided for @contactsPrivacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Contacts stay encrypted on this device. SafeMyanmar does not request access to your device contact list.'**
  String get contactsPrivacyDescription;

  /// No description provided for @maximumContactsReached.
  ///
  /// In en, this message translates to:
  /// **'You can save up to {count} emergency contacts.'**
  String maximumContactsReached(int count);

  /// No description provided for @selectedForSos.
  ///
  /// In en, this message translates to:
  /// **'Selected for SOS'**
  String get selectedForSos;

  /// No description provided for @notSelectedForSos.
  ///
  /// In en, this message translates to:
  /// **'Not selected for SOS'**
  String get notSelectedForSos;

  /// No description provided for @sosSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose whether this person may be included in a future SOS message. This does not send anything.'**
  String get sosSelectionDescription;

  /// No description provided for @editContact.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get editContact;

  /// No description provided for @addContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Add emergency contact'**
  String get addContactTitle;

  /// No description provided for @editContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit emergency contact'**
  String get editContactTitle;

  /// No description provided for @contactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get contactNameLabel;

  /// No description provided for @contactNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a contact name.'**
  String get contactNameRequired;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number.'**
  String get phoneNumberRequired;

  /// No description provided for @phoneNumberInvalidCharacters.
  ///
  /// In en, this message translates to:
  /// **'Use digits with an optional leading +. Spaces, hyphens, periods, and parentheses are allowed.'**
  String get phoneNumberInvalidCharacters;

  /// No description provided for @phoneNumberInvalidLength.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number containing 7 to 15 digits.'**
  String get phoneNumberInvalidLength;

  /// No description provided for @relationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship or label'**
  String get relationshipLabel;

  /// No description provided for @relationshipRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a relationship or label.'**
  String get relationshipRequired;

  /// No description provided for @deleteContact.
  ///
  /// In en, this message translates to:
  /// **'Delete contact'**
  String get deleteContact;

  /// No description provided for @deleteContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteContactTitle(String name);

  /// No description provided for @deleteContactDescription.
  ///
  /// In en, this message translates to:
  /// **'This removes the contact from secure local storage. No message will be sent.'**
  String get deleteContactDescription;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @contactNotFound.
  ///
  /// In en, this message translates to:
  /// **'This emergency contact was not found.'**
  String get contactNotFound;

  /// No description provided for @backToContacts.
  ///
  /// In en, this message translates to:
  /// **'Back to emergency contacts'**
  String get backToContacts;

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

  /// No description provided for @dataStatusSemantics.
  ///
  /// In en, this message translates to:
  /// **'{status}. {lastUpdate}'**
  String dataStatusSemantics(String status, String lastUpdate);

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

  /// No description provided for @utcTimestamp.
  ///
  /// In en, this message translates to:
  /// **'{value} UTC'**
  String utcTimestamp(String value);

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
      <String>['en', 'my'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'my':
      return AppLocalizationsMy();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
