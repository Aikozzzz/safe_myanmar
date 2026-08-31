import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/sos/data/sos_draft_codec.dart';
import 'package:mobile/features/sos/domain/sos_draft.dart';
import 'package:mobile/features/sos/domain/sos_draft_repository.dart';

void main() {
  final draft = SosDraft(
    id: 'draft-1',
    createdAt: DateTime.utc(2026, 7, 23, 1, 2, 3),
    selectedContactIds: const ['contact-1'],
    recipients: const [
      SosRecipientSnapshot(
        contactId: 'contact-1',
        name: 'Test Contact',
        phoneNumber: '+12025550123',
      ),
    ],
    message: 'I need help.',
    location: SosLocationSnapshot(
      latitude: 16.8409,
      longitude: 96.1735,
      timestamp: DateTime.utc(2026, 7, 23, 1),
      precision: LocationPrecision.precise,
      isLastKnown: false,
    ),
    profileName: 'Test User',
    body: 'Exact immutable body for Test User.',
    status: SosDraftStatus.composerOpened,
  );

  test('round trips one small versioned secure queue document', () {
    final encoded = SosDraftCodec.encode([draft]);
    final json = jsonDecode(encoded) as Map<String, dynamic>;

    expect(json['version'], 3);
    expect(json.keys, {'version', 'drafts'});
    expect(SosDraftCodec.decode(encoded), [draft]);
  });

  test('rejects unsupported and corrupt values without exposing payload', () {
    for (final payload in [
      '{"version":4,"drafts":[]}',
      'Sensitive Name +12025550123',
      '{"version":2,"drafts":[{"id":"bad"}]}',
    ]) {
      Object? thrown;
      try {
        SosDraftCodec.decode(payload);
      } on Object catch (error) {
        thrown = error;
      }
      expect(thrown, isA<SosDraftReadException>());
      expect(thrown.toString(), isNot(contains('Sensitive Name')));
      expect(thrown.toString(), isNot(contains('+12025550123')));
    }
  });

  test('migrates a v1 draft to a safe immutable body snapshot', () {
    final current =
        jsonDecode(SosDraftCodec.encode([draft])) as Map<String, dynamic>;
    current['version'] = 1;
    final stored = (current['drafts'] as List).single as Map<String, dynamic>;
    stored.remove('profileName');
    stored.remove('body');

    final migrated = SosDraftCodec.decode(jsonEncode(current)).single;

    expect(migrated.profileName, isEmpty);
    expect(
      migrated.body,
      contains('User-prepared SafeMyanmar emergency message.'),
    );
    expect(migrated.body, contains('I need help.'));
    expect(migrated.body, isNot(contains('Test User')));
    expect((jsonDecode(SosDraftCodec.encode([migrated])) as Map)['version'], 3);
  });

  test('rejects unknown statuses and preserves the SMS lifecycle statuses', () {
    final json =
        jsonDecode(SosDraftCodec.encode([draft])) as Map<String, dynamic>;
    final values = json['drafts'] as List<dynamic>;
    final storedDraft = values.single as Map<String, dynamic>;
    storedDraft['status'] = 'sent';

    expect(
      () => SosDraftCodec.decode(jsonEncode(json)),
      throwsA(isA<SosDraftReadException>()),
    );
    expect(SosDraftStatus.values.map((value) => value.name), [
      'prepared',
      'smsSending',
      'smsSent',
      'smsPartial',
      'smsUnknown',
      'smsFailed',
      'composerOpened',
      'failedToOpen',
      'cancelled',
    ]);
  });

  test('persists partial or unknown native SMS attempt metadata', () {
    final partial = draft.withSmsResult(
      status: SosDraftStatus.smsPartial,
      attemptId: 'attempt-1',
      confirmedParts: 1,
      totalParts: 2,
    );

    expect(SosDraftCodec.decode(SosDraftCodec.encode([partial])), [partial]);
  });
}
