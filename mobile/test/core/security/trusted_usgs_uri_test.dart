import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/security/trusted_usgs_uri.dart';

void main() {
  test('accepts exact USGS earthquake host and its subdomains over HTTPS', () {
    for (final value in <String>[
      'https://earthquake.usgs.gov/event',
      'https://events.earthquake.usgs.gov/event',
      'https://deep.events.earthquake.usgs.gov/event',
    ]) {
      expect(parseTrustedUsgsUri(value), Uri.parse(value));
    }
  });

  test('rejects non-HTTPS and deceptive USGS host suffixes', () {
    for (final value in <String>[
      'http://earthquake.usgs.gov/event',
      'https://earthquake.usgs.gov.example.com/event',
      'https://evilearthquake.usgs.gov/event',
      'https://earthquake.usgs.gov.evil.example/event',
      'https://events.earthquake.usgs.gov@example.com/event',
      'not a URI',
    ]) {
      expect(parseTrustedUsgsUri(value), isNull);
    }
  });
}
