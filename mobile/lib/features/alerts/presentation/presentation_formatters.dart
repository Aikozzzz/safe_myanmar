import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatDecimal(BuildContext context, double value) {
  return NumberFormat(
    '0.0',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value);
}

String formatUtcTimestamp(BuildContext context, DateTime value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final formatted = DateFormat(
    'MMM d, y, HH:mm:ss',
    locale,
  ).format(value.toUtc());
  return '$formatted UTC';
}
