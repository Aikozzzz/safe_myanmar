import 'dart:convert';

import '../../location/domain/foreground_location.dart';
import '../../profile/domain/phone_number.dart';
import '../domain/sos_draft.dart';
import '../domain/sos_draft_repository.dart';

abstract final class SosDraftCodec {
  static const version = 4;

  static String encode(List<SosDraft> drafts) => jsonEncode({
    'version': version,
    'drafts': [for (final draft in drafts) _encodeDraft(draft)],
  });

  static List<SosDraft> decode(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      final storedVersion = decoded['version'];
      if (storedVersion is! int) throw const FormatException();
      if (storedVersion < 1 || storedVersion > version) {
        throw const SosDraftReadException(
          SosDraftReadFailureKind.unsupportedVersion,
        );
      }
      final draftsJson = decoded['drafts'];
      if (draftsJson is! List || draftsJson.length > maxSosDrafts) {
        throw const FormatException();
      }
      final ids = <String>{};
      return List.unmodifiable([
        for (final value in draftsJson)
          _decodeDraft(value, ids, storedVersion: storedVersion),
      ]);
    } on SosDraftReadException {
      rethrow;
    } on Object {
      throw const SosDraftReadException(SosDraftReadFailureKind.corrupt);
    }
  }

  static Map<String, Object?> _encodeDraft(SosDraft draft) => {
    'id': draft.id,
    'createdAt': draft.createdAt.toUtc().toIso8601String(),
    'selectedContactIds': draft.selectedContactIds,
    'recipients': [
      for (final recipient in draft.recipients)
        {
          'contactId': recipient.contactId,
          'name': recipient.name,
          'phoneNumber': recipient.phoneNumber,
        },
    ],
    'message': draft.message,
    'location': switch (draft.location) {
      null => null,
      final location => {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': location.timestamp.toUtc().toIso8601String(),
        'precision': location.precision.name,
        'isLastKnown': location.isLastKnown,
      },
    },
    'profileName': draft.profileName,
    'body': draft.body,
    'status': draft.status.name,
    'bleAlias': draft.bleAlias,
    'bleMessage': draft.bleMessage,
    'smsAttemptId': draft.smsAttemptId,
    'smsConfirmedParts': draft.smsConfirmedParts,
    'smsTotalParts': draft.smsTotalParts,
  };

  static SosDraft _decodeDraft(
    Object? value,
    Set<String> ids, {
    required int storedVersion,
  }) {
    if (value is! Map<String, dynamic>) throw const FormatException();
    final id = value['id'];
    final createdAt = _utcDate(value['createdAt']);
    final contactIdsJson = value['selectedContactIds'];
    final recipientsJson = value['recipients'];
    final message = value['message'];
    final status = _status(value['status']);
    final storedProfileName = value['profileName'];
    final storedBody = value['body'];
    final bleAlias = value['bleAlias'];
    final bleMessage = value['bleMessage'];
    final smsAttemptId = value['smsAttemptId'];
    final smsConfirmedParts = value['smsConfirmedParts'] ?? 0;
    final smsTotalParts = value['smsTotalParts'] ?? 0;
    if (id is! String ||
        id.isEmpty ||
        id.length > 100 ||
        !ids.add(id) ||
        contactIdsJson is! List ||
        recipientsJson is! List ||
        recipientsJson.length > 10 ||
        contactIdsJson.length != recipientsJson.length ||
        message is! String? ||
        (message != null &&
            (message.isEmpty || message.length > maxSosMessageLength))) {
      throw const FormatException();
    }
    if ((storedVersion >= 3 &&
            (storedProfileName is! String ||
                storedProfileName.length > maxSosProfileNameLength ||
                storedBody is! String ||
                storedBody.trim().isEmpty ||
                storedBody.length > maxSosBodyLength)) ||
        (storedVersion >= version &&
            (bleAlias is! String? ||
                bleMessage is! String? ||
                !isValidSosBleAlias(bleAlias) ||
                !isValidSosBleMessage(bleMessage))) ||
        smsAttemptId is! String? ||
        smsConfirmedParts is! int ||
        smsTotalParts is! int ||
        smsConfirmedParts < 0 ||
        smsTotalParts < 0 ||
        smsConfirmedParts > smsTotalParts ||
        (smsAttemptId != null &&
            (smsAttemptId.isEmpty || smsAttemptId.length > 100))) {
      throw const FormatException();
    }

    final contactIds = <String>[];
    final contactIdSet = <String>{};
    for (final contactId in contactIdsJson) {
      if (contactId is! String ||
          contactId.isEmpty ||
          contactId.length > 100 ||
          !contactIdSet.add(contactId)) {
        throw const FormatException();
      }
      contactIds.add(contactId);
    }
    final recipients = <SosRecipientSnapshot>[];
    for (final recipientJson in recipientsJson) {
      if (recipientJson is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final contactId = recipientJson['contactId'];
      final name = recipientJson['name'];
      final phoneNumber = recipientJson['phoneNumber'];
      final phoneValidation = phoneNumber is String
          ? validateAndNormalizePhoneNumber(phoneNumber)
          : null;
      if (contactId is! String ||
          !contactIdSet.contains(contactId) ||
          name is! String ||
          name.trim().isEmpty ||
          name.length > 200 ||
          phoneValidation == null ||
          !phoneValidation.isValid ||
          phoneValidation.normalized != phoneNumber) {
        throw const FormatException();
      }
      recipients.add(
        SosRecipientSnapshot(
          contactId: contactId,
          name: name,
          phoneNumber: phoneNumber,
        ),
      );
    }
    if (!_sameOrder(contactIds, recipients.map((e) => e.contactId).toList())) {
      throw const FormatException();
    }

    final location = _location(value['location']);
    final profileName = storedVersion >= 3 ? storedProfileName! as String : '';
    final body = storedVersion >= 3
        ? storedBody! as String
        : _legacyBody(location: location, message: message);
    return SosDraft(
      id: id,
      createdAt: createdAt,
      selectedContactIds: contactIds,
      recipients: recipients,
      message: message,
      location: location,
      profileName: profileName,
      body: body,
      status: status,
      bleAlias: storedVersion >= version ? normalizeSosBleText(bleAlias) : null,
      bleMessage: storedVersion >= version
          ? normalizeSosBleText(bleMessage)
          : null,
      smsAttemptId: storedVersion >= 3 ? smsAttemptId : null,
      smsConfirmedParts: storedVersion >= 3 ? smsConfirmedParts : 0,
      smsTotalParts: storedVersion >= 3 ? smsTotalParts : 0,
    );
  }

  static SosLocationSnapshot? _location(Object? value) {
    if (value == null) return null;
    if (value is! Map<String, dynamic>) throw const FormatException();
    final latitude = value['latitude'];
    final longitude = value['longitude'];
    final isLastKnown = value['isLastKnown'];
    final precisionName = value['precision'];
    if (latitude is! num ||
        longitude is! num ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        isLastKnown is! bool ||
        precisionName is! String) {
      throw const FormatException();
    }
    final precision = LocationPrecision.values
        .where((value) => value.name == precisionName)
        .firstOrNull;
    if (precision == null) throw const FormatException();
    return SosLocationSnapshot(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      timestamp: _utcDate(value['timestamp']),
      precision: precision,
      isLastKnown: isLastKnown,
    );
  }

  static DateTime _utcDate(Object? value) {
    if (value is! String || !value.endsWith('Z')) {
      throw const FormatException();
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc) throw const FormatException();
    return parsed;
  }

  static SosDraftStatus _status(Object? value) {
    if (value is! String) throw const FormatException();
    final status = SosDraftStatus.values
        .where((status) => status.name == value)
        .firstOrNull;
    if (status == null) throw const FormatException();
    return status;
  }

  static bool _sameOrder(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static String _legacyBody({
    required SosLocationSnapshot? location,
    required String? message,
  }) {
    final lines = <String>['User-prepared SafeMyanmar emergency message.'];
    if (location == null) {
      lines.add('Location unavailable; no coordinates included.');
    } else {
      final latitude = location.latitude.toStringAsFixed(6);
      final longitude = location.longitude.toStringAsFixed(6);
      final precision = location.precision.name;
      final kind = location.isLastKnown ? 'Last-known' : 'Current';
      lines.add(
        '$kind $precision location: $latitude, $longitude at '
        '${location.timestamp.toUtc().toIso8601String()}. '
        'Map: https://maps.google.com/?q=$latitude,$longitude',
      );
    }
    if (message != null && message.isNotEmpty) lines.add('Message: $message');
    lines.add(
      'Please contact authorized emergency or medical help when possible.',
    );
    return lines.join('\n');
  }
}
