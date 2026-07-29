import '../../../l10n/app_localizations.dart';
import '../domain/sos_draft.dart';

String buildSosMessage({
  required AppLocalizations strings,
  required String profileName,
  required SosLocationSnapshot? location,
  required String? userMessage,
}) {
  final lines = <String>[strings.sosMessageHeader];
  final normalizedName = profileName.trim();
  if (normalizedName.isNotEmpty) {
    lines.add(strings.sosMessageProfileName(normalizedName));
  }
  if (location == null) {
    lines.add(strings.sosMessageLocationUnavailable);
  } else {
    final latitude = location.latitude.toStringAsFixed(6);
    final longitude = location.longitude.toStringAsFixed(6);
    final precision = location.precision.name == 'precise'
        ? strings.sosPrecise
        : strings.sosApproximate;
    final timestamp = location.timestamp.toUtc().toIso8601String();
    final mapsLink = 'https://maps.google.com/?q=$latitude,$longitude';
    lines.add(
      location.isLastKnown
          ? strings.sosMessageLastKnownLocation(
              precision,
              latitude,
              longitude,
              timestamp,
              mapsLink,
            )
          : strings.sosMessageCurrentLocation(
              precision,
              latitude,
              longitude,
              timestamp,
              mapsLink,
            ),
    );
  }
  final normalizedMessage = userMessage?.trim();
  if (normalizedMessage != null && normalizedMessage.isNotEmpty) {
    lines.add(strings.sosMessageUserText(normalizedMessage));
  }
  lines.add(strings.sosMessageAuthorizedHelp);
  return lines.join('\n');
}
