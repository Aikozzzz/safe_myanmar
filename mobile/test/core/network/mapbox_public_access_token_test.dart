import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/mapbox_public_access_token.dart';

void main() {
  test('accepts only a structurally valid public Mapbox token', () {
    final token = MapboxPublicAccessToken.fromRaw(
      'pk.abcdefghijk.1234567890_-',
    );

    expect(token.isAvailable, isTrue);
    expect(token.value, 'pk.abcdefghijk.1234567890_-');
  });

  test(
    'treats missing, secret, malformed, and padded tokens as unavailable',
    () {
      for (final value in [
        '',
        'pk.short',
        'sk.abcdefghijk.1234567890',
        'pk.abcdefghijk.1234567890!',
        ' pk.abcdefghijk.1234567890',
        'pk.abcdefghijk.1234567890 ',
      ]) {
        final token = MapboxPublicAccessToken.fromRaw(value);
        expect(token.isAvailable, isFalse, reason: value);
        expect(token.value, isNull, reason: value);
      }
    },
  );
}
