import 'package:intl/intl.dart';

const myanmarTimeOffset = Duration(hours: 6, minutes: 30);

DateTime toMyanmarTime(DateTime value) => value.toUtc().add(myanmarTimeOffset);

String formatMyanmarDateTime(DateTime value, String locale) =>
    DateFormat.yMMMd(locale).add_Hms().format(toMyanmarTime(value));

String formatMyanmarDate(DateTime value, String locale) =>
    DateFormat.yMMMd(locale).format(toMyanmarTime(value));
