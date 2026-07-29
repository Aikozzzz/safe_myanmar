import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/data/local_profile_codec.dart';
import 'package:mobile/features/profile/domain/local_profile.dart';
import 'package:mobile/features/profile/domain/local_profile_repository.dart';

void main() {
  final profile = LocalProfile(
    displayName: 'Test User',
    contacts: const [
      EmergencyContact(
        id: 'contact-1',
        name: 'Test Contact',
        phoneNumber: '+12025550123',
        label: 'Family',
        selectedForSos: true,
      ),
    ],
  );

  test('round trips one versioned JSON document', () {
    final encoded = LocalProfileCodec.encode(profile);
    final json = jsonDecode(encoded) as Map<String, dynamic>;

    expect(json['version'], 1);
    expect(json.keys, {'version', 'profile', 'emergencyContacts'});
    expect(LocalProfileCodec.decode(encoded), profile);
  });

  test('rejects unsupported versions without including payload data', () {
    const payload =
        '{"version":2,"profile":{"displayName":"Sensitive Name"},'
        '"emergencyContacts":[]}';

    expect(
      () => LocalProfileCodec.decode(payload),
      throwsA(
        isA<LocalProfileReadException>()
            .having(
              (error) => error.kind,
              'kind',
              LocalProfileReadFailureKind.unsupportedVersion,
            )
            .having(
              (error) => error.toString(),
              'safe message',
              isNot(contains('Sensitive Name')),
            ),
      ),
    );
  });

  for (final payload in [
    'not-json Sensitive Name +12025550123',
    '{"version":1}',
    '{"version":1,"profile":{"displayName":""},"emergencyContacts":'
        '[{"id":"1","name":"Name","phoneNumber":"202 555 0123",'
        '"label":"Friend","selectedForSos":false}]}',
  ]) {
    test('rejects corrupt document safely', () {
      expect(
        () => LocalProfileCodec.decode(payload),
        throwsA(
          isA<LocalProfileReadException>().having(
            (error) => error.kind,
            'kind',
            LocalProfileReadFailureKind.corrupt,
          ),
        ),
      );
    });
  }

  test('rejects contact fields longer than the SOS snapshot contract', () {
    final payload = jsonEncode({
      'version': 1,
      'profile': {'displayName': ''},
      'emergencyContacts': [
        {
          'id': 'contact-1',
          'name': List.filled(maxEmergencyContactNameLength + 1, 'x').join(),
          'phoneNumber': '1234567',
          'label': 'Family',
          'selectedForSos': true,
        },
      ],
    });

    expect(
      () => LocalProfileCodec.decode(payload),
      throwsA(isA<LocalProfileReadException>()),
    );
  });
}
