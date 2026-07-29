import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/domain/phone_number.dart';

void main() {
  test('normalizes common formatting and preserves only a leading plus', () {
    expect(
      validateAndNormalizePhoneNumber('  +1 (202) 555-01.23  ').normalized,
      '+12025550123',
    );
    expect(
      validateAndNormalizePhoneNumber('012 345 6789').normalized,
      '0123456789',
    );
  });

  test('accepts inclusive 7 and 15 digit boundaries', () {
    expect(validateAndNormalizePhoneNumber('1234567').isValid, isTrue);
    expect(validateAndNormalizePhoneNumber('+123456789012345').isValid, isTrue);
  });

  test('rejects values outside digit boundaries', () {
    expect(
      validateAndNormalizePhoneNumber('123456').error,
      PhoneNumberValidationError.invalidLength,
    );
    expect(
      validateAndNormalizePhoneNumber('1234567890123456').error,
      PhoneNumberValidationError.invalidLength,
    );
  });

  for (final value in ['+12A34567', '12/345678', '12+345678', '12_345678']) {
    test('rejects invalid phone characters in $value', () {
      expect(
        validateAndNormalizePhoneNumber(value).error,
        PhoneNumberValidationError.invalidCharacters,
      );
    });
  }

  test('reports empty separately', () {
    expect(
      validateAndNormalizePhoneNumber('   ').error,
      PhoneNumberValidationError.empty,
    );
  });
}
