enum PhoneNumberValidationError { empty, invalidCharacters, invalidLength }

final class PhoneNumberValidation {
  const PhoneNumberValidation._({this.normalized, this.error});

  const PhoneNumberValidation.valid(String value) : this._(normalized: value);

  const PhoneNumberValidation.invalid(PhoneNumberValidationError value)
    : this._(error: value);

  final String? normalized;
  final PhoneNumberValidationError? error;

  bool get isValid => normalized != null;
}

PhoneNumberValidation validateAndNormalizePhoneNumber(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return const PhoneNumberValidation.invalid(
      PhoneNumberValidationError.empty,
    );
  }

  final hasLeadingPlus = trimmed.startsWith('+');
  final body = hasLeadingPlus ? trimmed.substring(1) : trimmed;
  if (body.isEmpty || !RegExp(r'^[0-9\s().-]+$').hasMatch(body)) {
    return const PhoneNumberValidation.invalid(
      PhoneNumberValidationError.invalidCharacters,
    );
  }

  final digits = body.replaceAll(RegExp(r'[\s().-]'), '');
  if (digits.length < 7 || digits.length > 15) {
    return const PhoneNumberValidation.invalid(
      PhoneNumberValidationError.invalidLength,
    );
  }

  return PhoneNumberValidation.valid('${hasLeadingPlus ? '+' : ''}$digits');
}
