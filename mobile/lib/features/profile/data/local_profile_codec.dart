import 'dart:convert';

import '../domain/local_profile.dart';
import '../domain/local_profile_repository.dart';
import '../domain/phone_number.dart';

abstract final class LocalProfileCodec {
  static const version = 1;

  static String encode(LocalProfile profile) => jsonEncode({
    'version': version,
    'profile': {'displayName': profile.displayName},
    'emergencyContacts': [
      for (final contact in profile.contacts)
        {
          'id': contact.id,
          'name': contact.name,
          'phoneNumber': contact.phoneNumber,
          'label': contact.label,
          'selectedForSos': contact.selectedForSos,
        },
    ],
  });

  static LocalProfile decode(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      final storedVersion = decoded['version'];
      if (storedVersion is! int) throw const FormatException();
      if (storedVersion != version) {
        throw const LocalProfileReadException(
          LocalProfileReadFailureKind.unsupportedVersion,
        );
      }

      final profileJson = decoded['profile'];
      final contactsJson = decoded['emergencyContacts'];
      if (profileJson is! Map<String, dynamic> || contactsJson is! List) {
        throw const FormatException();
      }
      final displayName = profileJson['displayName'];
      if (displayName is! String ||
          displayName.length > maxProfileDisplayNameLength ||
          contactsJson.length > maxEmergencyContacts) {
        throw const FormatException();
      }

      final contacts = <EmergencyContact>[];
      final ids = <String>{};
      for (final value in contactsJson) {
        if (value is! Map<String, dynamic>) throw const FormatException();
        final id = value['id'];
        final name = value['name'];
        final phoneNumber = value['phoneNumber'];
        final label = value['label'];
        final selectedForSos = value['selectedForSos'];
        if (id is! String ||
            id.isEmpty ||
            id.length > maxEmergencyContactIdLength ||
            !ids.add(id) ||
            name is! String ||
            name.trim().isEmpty ||
            name.length > maxEmergencyContactNameLength ||
            phoneNumber is! String ||
            label is! String ||
            label.trim().isEmpty ||
            label.length > maxEmergencyContactLabelLength ||
            selectedForSos is! bool) {
          throw const FormatException();
        }
        final validation = validateAndNormalizePhoneNumber(phoneNumber);
        if (!validation.isValid || validation.normalized != phoneNumber) {
          throw const FormatException();
        }
        contacts.add(
          EmergencyContact(
            id: id,
            name: name,
            phoneNumber: phoneNumber,
            label: label,
            selectedForSos: selectedForSos,
          ),
        );
      }
      return LocalProfile(displayName: displayName, contacts: contacts);
    } on LocalProfileReadException {
      rethrow;
    } on Object {
      throw const LocalProfileReadException(
        LocalProfileReadFailureKind.corrupt,
      );
    }
  }
}
