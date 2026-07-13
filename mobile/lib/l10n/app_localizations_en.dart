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
