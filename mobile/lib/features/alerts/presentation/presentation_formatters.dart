import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/time/myanmar_time.dart';
import '../../../l10n/app_localizations.dart';

String formatDecimal(BuildContext context, double value) {
  return NumberFormat(
    '0.0',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value);
}

String formatMyanmarTimestamp(
  BuildContext context,
  AppLocalizations strings,
  DateTime value,
) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return strings.myanmarTimeTimestamp(formatMyanmarDateTime(value, locale));
}
