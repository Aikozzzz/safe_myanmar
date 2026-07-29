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
  String get navigationHome => 'Home';

  @override
  String get navigationMap => 'Map';

  @override
  String get navigationSos => 'SOS';

  @override
  String get navigationGuide => 'Guide';

  @override
  String get navigationMore => 'More';

  @override
  String get homeTitle => 'SafeMyanmar';

  @override
  String get homeDescription =>
      'Emergency information and tools based on currently available information.';

  @override
  String get viewEarthquakeInformation => 'View earthquake information';

  @override
  String get mapTitle => 'Map';

  @override
  String get locationHeading => 'Your location';

  @override
  String get locationNotRequestedTitle => 'Location access is off';

  @override
  String get locationExplanation =>
      'Mapbox may receive SDK, device, and usage telemetry when the app starts, before location permission; your device location is not included then. Choosing Use my location constructs and centers the remote Mapbox map, disclosing the viewed map area. Your exact origin goes to the SafeMyanmar backend and Mapbox Directions only after you request a route.';

  @override
  String get locationPrivacyDescription =>
      'Before you choose Use my location, SafeMyanmar does not request device location or construct the map. Shelter refresh and Mapbox telemetry may use the network without device location. SafeMyanmar does not keep a location history or request background location.';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get tryLocationAgain => 'Try location again';

  @override
  String get locationRequestingTitle => 'Requesting location';

  @override
  String get locationRequestingDescription =>
      'Checking permission and finding your current location.';

  @override
  String get findingYourLocation => 'Finding your location';

  @override
  String get preciseLocationAvailable => 'Precise location available';

  @override
  String get preciseLocationDescription =>
      'Your device provided precise foreground location access.';

  @override
  String get approximateLocationAvailable => 'Approximate location available';

  @override
  String get approximateLocationDescription =>
      'Your device provided approximate foreground location access. The position may cover a wider area.';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get locationPermissionDeniedDescription =>
      'SafeMyanmar cannot access location unless you choose to allow it.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Location permission permanently denied';

  @override
  String get locationPermissionPermanentlyDeniedDescription =>
      'SafeMyanmar will not ask again. You can change location permission in app settings.';

  @override
  String get locationServicesDisabled => 'Location services are off';

  @override
  String get locationServicesDisabledDescription =>
      'Turn on device location services before trying again.';

  @override
  String get lastKnownLocation => 'Last known location';

  @override
  String get lastKnownLocationDescription =>
      'A live location was unavailable. This is the last known location reported by your device.';

  @override
  String get locationRecoverableError => 'Location temporarily unavailable';

  @override
  String get locationRecoverableErrorDescription =>
      'SafeMyanmar could not get a current or last known location. You can try again.';

  @override
  String get openAppSettings => 'Open app settings';

  @override
  String get openLocationSettings => 'Open location settings';

  @override
  String get couldNotOpenLocationSettings =>
      'Could not open location settings.';

  @override
  String locationCoordinates(String latitude, String longitude) {
    return 'Location: $latitude, $longitude';
  }

  @override
  String locationCapturedAt(String time) {
    return 'Location time: $time';
  }

  @override
  String lastKnownLocationAt(String time) {
    return 'Last known at: $time';
  }

  @override
  String get simulationLabel => 'SIMULATION';

  @override
  String get simulationNavigationHeading =>
      'Simulation shelter and route information';

  @override
  String navigationSource(String source) {
    return 'Source: $source';
  }

  @override
  String shelterDataTime(String time) {
    return 'Shelter data: $time';
  }

  @override
  String hazardDataTime(String time) {
    return 'Hazard data: $time';
  }

  @override
  String navigationCachedAt(String time) {
    return 'Saved for offline use: $time';
  }

  @override
  String get navigationDataLoading => 'Loading simulation shelters and hazards';

  @override
  String get navigationDataUnavailable =>
      'Simulation shelter or hazard information could not be updated.';

  @override
  String get navigationCachedWarning =>
      'Previously loaded simulation information remains visible and is stale.';

  @override
  String get retryNavigationData => 'Retry shelter and hazard data';

  @override
  String get mapConfigurationUnavailableTitle =>
      'Map configuration unavailable';

  @override
  String get mapConfigurationUnavailableDescription =>
      'A valid public Mapbox token was not provided. Location, shelter, hazard, and route controls remain available, but the map cannot be displayed.';

  @override
  String get mapTemporarilyUnavailableTitle => 'Map temporarily unavailable';

  @override
  String get mapTemporarilyUnavailableDescription =>
      'Mapbox map or style data could not load because the device may be offline or the map configuration may be unavailable. Shelter details and controls remain available.';

  @override
  String get mapContentSemantics =>
      'Interactive map showing current or last-known location, simulation shelters, relevant hazards, and route options. The selected route uses a wider line.';

  @override
  String get chooseShelter => 'Shelter';

  @override
  String get shelterListHeading => 'Available simulation shelters';

  @override
  String get shelterListEmpty =>
      'No cached simulation shelter details are available.';

  @override
  String get chooseDisasterType => 'Disaster type';

  @override
  String get chooseTravelProfile => 'Travel profile';

  @override
  String get earthquakeDisaster => 'Earthquake';

  @override
  String get floodDisaster => 'Flood';

  @override
  String get fireDisaster => 'Fire';

  @override
  String get cycloneDisaster => 'Cyclone';

  @override
  String get landslideDisaster => 'Landslide';

  @override
  String get severeWeatherDisaster => 'Severe weather';

  @override
  String get walkingProfile => 'Walking';

  @override
  String get drivingProfile => 'Driving';

  @override
  String get requestRouteSuggestions => 'Request route suggestions';

  @override
  String get retryRouteSuggestions => 'Retry route suggestions';

  @override
  String get updatingRouteSuggestions => 'Requesting route suggestions';

  @override
  String get routingUnavailable =>
      'Route suggestions could not be updated. Shelters and hazards remain visible; try again.';

  @override
  String get cachedRouteWarning =>
      'A previously loaded route response remains visible and is stale.';

  @override
  String cachedRouteAt(String time) {
    return 'Route saved at: $time';
  }

  @override
  String get noRoutesReturned =>
      'The server returned no route options. No alternative was created by SafeMyanmar.';

  @override
  String get routeSuggested => 'Suggested';

  @override
  String routeAlternative(int number) {
    return 'Alternative $number';
  }

  @override
  String get routeSelected => 'Selected route';

  @override
  String routeProfileValue(String profile) {
    return 'Profile: $profile';
  }

  @override
  String routeDistanceValue(String distance) {
    return 'Distance: $distance m';
  }

  @override
  String routeDurationValue(String duration) {
    return 'Duration: $duration min';
  }

  @override
  String routeHazardIntersections(int count) {
    return 'Hazard intersections: $count';
  }

  @override
  String routeRationale(String rationale) {
    return 'Rationale: $rationale';
  }

  @override
  String routeGeneratedAt(String time) {
    return 'Generated: $time';
  }

  @override
  String routeHazardDataAt(String time) {
    return 'Hazard data: $time';
  }

  @override
  String routeDirectionsProvider(String provider) {
    return 'Directions provider: $provider';
  }

  @override
  String routeProfileReason(String reason) {
    return 'Profile selection: $reason';
  }

  @override
  String uncertaintyNotice(String notice) {
    return 'Uncertainty: $notice';
  }

  @override
  String get mapSuggestedSelectedLabel => 'Suggested selected route';

  @override
  String mapAlternativeLabel(int number) {
    return 'Alternative $number';
  }

  @override
  String get sosTitle => 'SOS';

  @override
  String get sosIntroduction =>
      'Prepare an emergency SMS for people you selected. Opening this screen does not prepare or send anything.';

  @override
  String get sosRecipientsHeading => 'Selected recipients';

  @override
  String sosRecipientPreview(String name, String phoneNumber) {
    return '$name: $phoneNumber';
  }

  @override
  String get sosNoRecipientsTitle => 'No contacts selected';

  @override
  String get sosNoRecipientsDescription =>
      'Select at least one saved emergency contact before preparing an SOS draft.';

  @override
  String get sosManageContacts => 'Open More contacts';

  @override
  String get sosSharedDataHeading => 'Exact SMS preview';

  @override
  String get sosStoredDataHeading => 'Draft details stored securely';

  @override
  String sosProfileNamePreview(String name) {
    return 'Profile name: $name';
  }

  @override
  String get sosProfileNameUnavailable => 'Profile name: Not included';

  @override
  String sosCurrentLocationPreview(
    String precision,
    String latitude,
    String longitude,
    String time,
  ) {
    return 'Current $precision location: $latitude, $longitude. Captured $time.';
  }

  @override
  String sosLastKnownLocationPreview(
    String precision,
    String latitude,
    String longitude,
    String time,
  ) {
    return 'Last-known $precision location: $latitude, $longitude. Captured $time.';
  }

  @override
  String get sosLocationUnavailable =>
      'Location unavailable. No coordinates will be included.';

  @override
  String get sosPrecise => 'precise';

  @override
  String get sosApproximate => 'approximate';

  @override
  String sosDraftCreatedAt(String time) {
    return 'Created: $time';
  }

  @override
  String get sosDraftCreatedWhenConfirmed =>
      'Created time will be recorded when you confirm.';

  @override
  String get sosOptionalMessageLabel => 'Optional concise message';

  @override
  String get sosOptionalMessageHint =>
      'For example: I need help leaving this area.';

  @override
  String get sosComposerDisclosure =>
      'SafeMyanmar only opens your phone\'s messaging app. That app controls SMS transmission and delivery, and SafeMyanmar cannot verify either.';

  @override
  String get sosHoldToOpen =>
      'Hold for 3 seconds to prepare and open messaging';

  @override
  String sosHoldProgress(int percent) {
    return 'Keep holding: $percent%';
  }

  @override
  String get sosHoldCancelled => 'Hold cancelled. Nothing was opened.';

  @override
  String get sosHoldSemanticsHint =>
      'Press and hold continuously for 3 seconds. Activate for an accessible confirmation path.';

  @override
  String get sosAccessibleConfirmation => 'Use confirmation dialogs instead';

  @override
  String get sosConfirmPreviewTitle => 'Confirm SOS draft details';

  @override
  String get sosConfirmPreviewDescription =>
      'Review the recipients and exact SMS preview on this screen. Continue only if you want to prepare this draft.';

  @override
  String get sosContinue => 'Continue';

  @override
  String get sosConfirmComposerTitle => 'Open the messaging app?';

  @override
  String get sosConfirmComposerDescription =>
      'This second confirmation prepares the secure draft and asks your phone to open its messaging app with the recipients and body filled in. You must choose whether to send it there.';

  @override
  String get sosOpenMessaging => 'Prepare and open messaging';

  @override
  String get sosNotNow => 'Not now';

  @override
  String get sosComposerOpenedNotice =>
      'Messaging was opened. SafeMyanmar cannot verify SMS transmission or delivery. The draft is retained for retry or removal.';

  @override
  String get sosComposerFailedNotice =>
      'The messaging app could not be opened. The prepared draft was retained so you can retry or remove it.';

  @override
  String get sosDraftSaveFailed =>
      'The SOS draft could not be saved securely. No messaging app was opened.';

  @override
  String get sosMaximumDrafts =>
      'The secure SOS queue already has 5 drafts. Remove one before preparing another.';

  @override
  String get sosDraftQueueHeading => 'SOS drafts and history';

  @override
  String get sosDraftQueueEmpty =>
      'No SOS drafts have been prepared on this device.';

  @override
  String sosStatusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String get sosStatusPrepared => 'Prepared';

  @override
  String get sosStatusComposerOpened => 'Messaging app opened; outcome unknown';

  @override
  String get sosStatusFailedToOpen => 'Messaging app failed to open';

  @override
  String get sosStatusCancelled => 'Cancelled';

  @override
  String get sosOpenAgain => 'Open again';

  @override
  String get sosCancelDraft => 'Cancel draft';

  @override
  String get sosRemoveDraft => 'Remove draft';

  @override
  String get sosRetryComposerTitle => 'Open this draft again?';

  @override
  String get sosRetryComposerDescription =>
      'SafeMyanmar will ask your phone to open messaging with this saved draft. You must choose whether to send it there.';

  @override
  String get sosCancelDraftTitle => 'Cancel this draft?';

  @override
  String get sosCancelDraftDescription =>
      'The draft will remain in history with a Cancelled status and will not open automatically.';

  @override
  String get sosRemoveDraftTitle => 'Remove this draft?';

  @override
  String get sosRemoveDraftDescription =>
      'This permanently removes the draft snapshot from secure storage on this device.';

  @override
  String get sosQueueLoading => 'Loading secure SOS drafts';

  @override
  String get sosQueueReadErrorTitle => 'SOS drafts temporarily unavailable';

  @override
  String get sosQueueReadErrorDescription =>
      'SafeMyanmar could not read the secure SOS queue. No private draft details were exposed. Try again.';

  @override
  String get sosQueueDataErrorTitle => 'Stored SOS drafts cannot be opened';

  @override
  String get sosQueueDataErrorDescription =>
      'The secure SOS queue is damaged or uses an unsupported version. It has not been changed. Retry, or reset only this queue.';

  @override
  String get sosQueueWriteErrorTitle => 'SOS draft change was not saved';

  @override
  String get sosQueueWriteErrorDescription =>
      'The previously saved SOS queue remains available. Try the change again.';

  @override
  String get sosResetQueue => 'Reset SOS queue';

  @override
  String get sosResetQueueTitle => 'Reset unreadable SOS queue?';

  @override
  String get sosResetQueueDescription =>
      'This permanently removes only the unreadable SOS drafts from this device. Your profile and contacts remain unchanged.';

  @override
  String get sosMessageHeader => 'User-prepared SafeMyanmar emergency message.';

  @override
  String sosMessageProfileName(String name) {
    return 'Profile name: $name';
  }

  @override
  String sosMessageCurrentLocation(
    String precision,
    String latitude,
    String longitude,
    String time,
    String mapsLink,
  ) {
    return 'Current $precision location: $latitude, $longitude at $time. Map: $mapsLink';
  }

  @override
  String sosMessageLastKnownLocation(
    String precision,
    String latitude,
    String longitude,
    String time,
    String mapsLink,
  ) {
    return 'Last-known $precision location: $latitude, $longitude at $time. Map: $mapsLink';
  }

  @override
  String get sosMessageLocationUnavailable =>
      'Location unavailable; no coordinates included.';

  @override
  String sosMessageUserText(String message) {
    return 'Message: $message';
  }

  @override
  String get sosMessageAuthorizedHelp =>
      'Please contact authorized emergency or medical help when possible.';

  @override
  String get guideTitle => 'Guide';

  @override
  String get guideIntroduction =>
      'Search a small, reviewed emergency guide stored on this device. It works without a network connection.';

  @override
  String get guideOfflineVerifiedLabel => 'Offline verified-content retrieval';

  @override
  String get guideAskAssistant => 'Ask the constrained assistant';

  @override
  String get guideSearchLabel => 'Search emergency guidance';

  @override
  String get guideSearchHint => 'Earthquake, trapped, flood, fire, first aid';

  @override
  String get guideSearchAction => 'Search';

  @override
  String get guideCategories => 'Categories';

  @override
  String get guideCategoryAll => 'All';

  @override
  String get guideCategoryEarthquake => 'Earthquake';

  @override
  String get guideCategoryFlood => 'Flood';

  @override
  String get guideCategoryFire => 'Fire';

  @override
  String get guideCategoryFirstAid => 'First aid';

  @override
  String get guideLoading => 'Loading offline emergency guidance';

  @override
  String get guideNoResults =>
      'No approved offline article matched this search.';

  @override
  String get guideStorageError =>
      'Offline guidance could not be read from this device.';

  @override
  String get guideTranslationWarning =>
      'Academic prototype: Burmese translations require review by qualified local language and emergency experts before deployment.';

  @override
  String get guideArticleTitle => 'Emergency guide';

  @override
  String get guideArticleUnavailable =>
      'This approved offline article is unavailable.';

  @override
  String get guideOpenArticleHint => 'Open approved emergency article';

  @override
  String get guideApprovedSource => 'Approved source record';

  @override
  String guideSourceName(String source) {
    return 'Source: $source';
  }

  @override
  String guideContentVersion(int version) {
    return 'Content version: $version';
  }

  @override
  String guideReviewedDate(String date) {
    return 'Reviewed: $date';
  }

  @override
  String guideSourceDate(String date) {
    return 'Source updated: $date';
  }

  @override
  String get guideContentWarning =>
      'Emergency information may not cover every situation. Follow authorized local instructions and contact authorized local emergency or medical services when possible.';

  @override
  String guideSourceSemantics(String source, int version) {
    return 'Approved source $source, content version $version';
  }

  @override
  String get assistantTitle => 'Offline assistant';

  @override
  String get assistantOfflineVerified =>
      'Offline verified-content retrieval (source-backed, not generative)';

  @override
  String get assistantDeterministicActive =>
      'Deterministic offline verified-content retrieval is active.';

  @override
  String get assistantOnnxChecking =>
      'Checking optional ONNX intent refinement availability.';

  @override
  String get assistantOnnxAvailable =>
      'Optional ONNX intent refinement is available for deterministic unknown results.';

  @override
  String get assistantOnnxUnavailable =>
      'Optional ONNX intent refinement is unavailable. Missing optional models are normal; deterministic retrieval remains active.';

  @override
  String get assistantGemmaChecking =>
      'Checking optional Gemma local rewording availability.';

  @override
  String get assistantGemmaAvailable =>
      'Optional Gemma local rewording is available for eligible noncritical articles.';

  @override
  String get assistantGemmaUnavailable =>
      'Optional Gemma local rewording is unavailable. Missing optional models are normal; exact verified articles remain available.';

  @override
  String get assistantIntroduction =>
      'This tool always matches questions with a deterministic classifier and retrieves approved articles on this device. Optional local models cannot create instructions, calculate routes, or activate SOS.';

  @override
  String get assistantSuggestedQuestions => 'Suggested questions';

  @override
  String get assistantSuggestionEarthquake =>
      'What should I do during an earthquake?';

  @override
  String get assistantSuggestionTrapped => 'I am trapped after an earthquake';

  @override
  String get assistantSuggestionFirstAid =>
      'What should I check before giving first aid?';

  @override
  String get assistantSuggestionFlood => 'How do I avoid floodwater?';

  @override
  String get assistantSearching => 'Searching approved offline content';

  @override
  String get assistantDisclaimer =>
      'This academic prototype retrieves only fixed, reviewed content. It is not a diagnosis or a replacement for authorized emergency or medical services.';

  @override
  String get assistantInputLabel => 'Emergency question';

  @override
  String get assistantInputHint => 'Type in English or Burmese';

  @override
  String get assistantSend => 'Send question';

  @override
  String get assistantVerifiedAnswer => 'Retrieved approved content';

  @override
  String assistantConfidence(int confidence, String explanation) {
    return 'Intent confidence: $confidence%\n$explanation';
  }

  @override
  String assistantClassifierMatched(String terms) {
    return 'Matched weighted offline terms: $terms. No machine-learning model was used.';
  }

  @override
  String get assistantClassifierLowConfidence =>
      'The closest offline match was below the confidence threshold. No machine-learning model was used.';

  @override
  String get assistantClassifierNoMatch =>
      'No approved offline intent terms matched. No machine-learning model was used.';

  @override
  String get assistantClassifierOnnx =>
      'The deterministic classifier returned unknown, then the optional local ONNX classifier recognized this intent at or above the safety threshold.';

  @override
  String get assistantEngineDeterministic =>
      'Response engine: deterministic offline classifier';

  @override
  String get assistantEngineOnnx =>
      'Response engine: optional local ONNX intent classifier';

  @override
  String get assistantLocalRewordingTitle => 'Optional local rewording';

  @override
  String get assistantLocalRewordingWarning =>
      'Model-generated wording may be inaccurate. Verify it against the exact source-backed guidance shown above.';

  @override
  String assistantLocalRewordingSemantics(String text) {
    return 'Optional model-generated local rewording. $text Warning: verify against the exact source-backed guidance.';
  }

  @override
  String get assistantMapResponse =>
      'SafeMyanmar does not calculate routes in the assistant. Open Map to view available shelters and request uncertain, timestamped route suggestions.';

  @override
  String get assistantSosResponse =>
      'The assistant cannot activate or send an SOS. Open SOS to review recipients, information, and explicit confirmation controls.';

  @override
  String get assistantMissingResponse =>
      'No approved missing-person procedure is available in this Tier 1 offline set. Contact authorized local services and share personal information only with trusted recipients.';

  @override
  String get assistantDamageResponse =>
      'No approved damage-report procedure is available in this Tier 1 offline set. Do not enter a damaged building to collect information.';

  @override
  String get assistantUnknownResponse =>
      'I could not confidently match that question to approved offline content. Try a suggested question or browse the Guide categories.';

  @override
  String get assistantUnavailableResponse =>
      'Approved offline content for that request is unavailable.';

  @override
  String get assistantReviewSos => 'Open SOS for user review';

  @override
  String get assistantOpenMap => 'Open Map';

  @override
  String get assistantSosDraftTitle =>
      'Draft details extracted for your review';

  @override
  String get assistantSosDraftWarning =>
      'Draft only. Check every field. Nothing was sent and SOS was not activated.';

  @override
  String assistantDraftIncident(String value) {
    return 'Incident: $value';
  }

  @override
  String assistantDraftStatus(String value) {
    return 'Status: $value';
  }

  @override
  String assistantDraftInjury(String value) {
    return 'Injury text: $value';
  }

  @override
  String assistantDraftLocation(String value) {
    return 'Location phrase: $value';
  }

  @override
  String assistantDraftBattery(int value) {
    return 'Battery: $value%';
  }

  @override
  String get moreTitle => 'More';

  @override
  String get profileOverviewTitle => 'Your local profile';

  @override
  String get profileNotSet => 'Display name not set';

  @override
  String get profileLocalOnlyLabel => 'Stored on this device';

  @override
  String get profileOverviewDescription =>
      'Keep a display name and the people you may choose to include in a future SOS message.';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get emergencyContacts => 'Emergency contacts';

  @override
  String contactsSummary(int count, int selected) {
    return '$count contacts, $selected selected for SOS';
  }

  @override
  String get manageContacts => 'Manage contacts';

  @override
  String get profilePrivacyTitle => 'Private by default';

  @override
  String get profilePrivacyDescription =>
      'Your profile and contacts are encrypted in secure device storage. SafeMyanmar does not read your device contacts, and saving a contact does not send an SOS message.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get displayNameRequired => 'Enter a display name.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get profileLoading => 'Loading your local profile';

  @override
  String get profileSaving => 'Saving securely';

  @override
  String get profileReadErrorTitle => 'Profile temporarily unavailable';

  @override
  String get profileReadErrorDescription =>
      'SafeMyanmar could not read secure local profile data. No profile details were exposed. Try again.';

  @override
  String get profileDataErrorTitle => 'Stored profile cannot be opened';

  @override
  String get profileDataErrorDescription =>
      'The encrypted local profile is damaged or uses an unsupported version. It has not been changed. Retry, or reset it to start again.';

  @override
  String get profileWriteErrorTitle => 'Changes were not saved';

  @override
  String get profileWriteErrorDescription =>
      'Your last securely saved profile remains available. Try saving the change again.';

  @override
  String get retry => 'Retry';

  @override
  String get resetLocalProfile => 'Reset local profile';

  @override
  String get resetLocalProfileTitle => 'Reset unreadable profile?';

  @override
  String get resetLocalProfileDescription =>
      'This permanently removes the unreadable local profile and emergency contacts from this device. This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get contactsTitle => 'Emergency contacts';

  @override
  String get addContact => 'Add contact';

  @override
  String get contactsEmptyTitle => 'No emergency contacts yet';

  @override
  String get contactsEmptyDescription =>
      'Add people you trust, then choose who may be included in a future SOS message.';

  @override
  String get contactsPrivacyDescription =>
      'Contacts stay encrypted on this device. SafeMyanmar does not request access to your device contact list.';

  @override
  String maximumContactsReached(int count) {
    return 'You can save up to $count emergency contacts.';
  }

  @override
  String get selectedForSos => 'Selected for SOS';

  @override
  String get notSelectedForSos => 'Not selected for SOS';

  @override
  String get sosSelectionDescription =>
      'Choose whether this person may be included in a future SOS message. This does not send anything.';

  @override
  String get editContact => 'Edit contact';

  @override
  String get addContactTitle => 'Add emergency contact';

  @override
  String get editContactTitle => 'Edit emergency contact';

  @override
  String get contactNameLabel => 'Contact name';

  @override
  String get contactNameRequired => 'Enter a contact name.';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberRequired => 'Enter a phone number.';

  @override
  String get phoneNumberInvalidCharacters =>
      'Use digits with an optional leading +. Spaces, hyphens, periods, and parentheses are allowed.';

  @override
  String get phoneNumberInvalidLength =>
      'Enter a phone number containing 7 to 15 digits.';

  @override
  String get relationshipLabel => 'Relationship or label';

  @override
  String get relationshipRequired => 'Enter a relationship or label.';

  @override
  String get deleteContact => 'Delete contact';

  @override
  String deleteContactTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteContactDescription =>
      'This removes the contact from secure local storage. No message will be sent.';

  @override
  String get delete => 'Delete';

  @override
  String get contactNotFound => 'This emergency contact was not found.';

  @override
  String get backToContacts => 'Back to emergency contacts';

  @override
  String get earthquakeInformation => 'Earthquake information';

  @override
  String get refresh => 'Refresh';

  @override
  String get liveInformation => 'Live information';

  @override
  String get cachedInformation => 'Cached information';

  @override
  String get staleInformation => 'Stale information';

  @override
  String lastSuccessfulUpdate(String time) {
    return 'Last successful update: $time';
  }

  @override
  String dataStatusSemantics(String status, String lastUpdate) {
    return '$status. $lastUpdate';
  }

  @override
  String get noRecentEarthquakes =>
      'No recent earthquakes were found in the covered area. This does not guarantee there is no danger.';

  @override
  String get liveEarthquakeDataUnavailable =>
      'Live earthquake data unavailable.';

  @override
  String get savedInformationRemains =>
      'Previously saved information remains available below.';

  @override
  String get couldNotUpdateLiveInformation =>
      'Could not update live information.';

  @override
  String magnitudeValue(String magnitude) {
    return 'Magnitude $magnitude';
  }

  @override
  String locationValue(String place) {
    return 'Location: $place';
  }

  @override
  String eventTimeValue(String time) {
    return 'Event time: $time';
  }

  @override
  String utcTimestamp(String value) {
    return '$value UTC';
  }

  @override
  String depthValue(String depth) {
    return 'Depth: $depth km';
  }

  @override
  String providerUpdateValue(String time) {
    return 'Provider update: $time';
  }

  @override
  String retrievedValue(String time) {
    return 'Retrieved: $time';
  }

  @override
  String reviewStatusValue(String status) {
    return 'Review status: $status';
  }

  @override
  String get dataSourceUsGS => 'Source: USGS';

  @override
  String get openUsGSsource => 'Open USGS source';

  @override
  String get couldNotOpenUsGSsource => 'Could not open USGS source.';

  @override
  String get earthquakeInformationNotFound =>
      'Earthquake information was not found.';

  @override
  String get backToEarthquakeInformation => 'Back to earthquake information';

  @override
  String earthquakeCardSemantics(
    String type,
    String magnitude,
    String location,
    String eventTime,
    String status,
    String source,
  ) {
    return '$type. $magnitude. $location. $eventTime. $status. $source';
  }

  @override
  String get earthquakeCardHint => 'Open earthquake information details';

  @override
  String get preliminaryNotice => 'Preliminary earthquake values may change.';

  @override
  String get loadingEarthquakes => 'Updating earthquake information';
}
