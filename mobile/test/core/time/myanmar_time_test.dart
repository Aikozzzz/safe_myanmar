import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/core/time/myanmar_time.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en_GB'));

  test('converts UTC values to fixed Myanmar Time', () {
    final value = DateTime.utc(2026, 7, 13, 18);

    expect(toMyanmarTime(value), DateTime.utc(2026, 7, 14, 0, 30));
    expect(formatMyanmarDateTime(value, 'en_GB'), '14 Jul 2026 00:30:00');
    expect(formatMyanmarDate(value, 'en_GB'), '14 Jul 2026');
  });
}
