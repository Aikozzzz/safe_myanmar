import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';

String formatDecimal(BuildContext context, double value) {
  return NumberFormat(
    '0.0',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value);
}

String formatUtcTimestamp(
  BuildContext context,
  AppLocalizations strings,
  DateTime value,
) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final formatted = DateFormat.yMMMd(locale).add_Hms().format(value.toUtc());
  return strings.utcTimestamp(formatted);
}
