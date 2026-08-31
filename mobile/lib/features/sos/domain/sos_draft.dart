import '../../location/domain/foreground_location.dart';

const maxSosDrafts = 5;
const maxSosMessageLength = 240;
const maxSosBodyLength = 4000;
const maxSosProfileNameLength = 500;
const sosDuplicateWindow = Duration(minutes: 5);

enum SosDraftStatus {
  prepared,
  smsSending,
  smsSent,
  smsPartial,
  smsUnknown,
  smsFailed,
  composerOpened,
  failedToOpen,
  cancelled,
}

final class SosRecipientSnapshot {
  const SosRecipientSnapshot({
    required this.contactId,
    required this.name,
    required this.phoneNumber,
  });

  final String contactId;
  final String name;
  final String phoneNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SosRecipientSnapshot &&
          contactId == other.contactId &&
          name == other.name &&
          phoneNumber == other.phoneNumber;

  @override
  int get hashCode => Object.hash(contactId, name, phoneNumber);
}

final class SosLocationSnapshot {
  const SosLocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.precision,
    required this.isLastKnown,
  });

  factory SosLocationSnapshot.fromForegroundLocation(
    ForegroundLocation location, {
    required bool isLastKnown,
  }) => SosLocationSnapshot(
    latitude: location.latitude,
    longitude: location.longitude,
    timestamp: location.timestamp.toUtc(),
    precision: location.precision,
    isLastKnown: isLastKnown,
  );

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final LocationPrecision precision;
  final bool isLastKnown;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SosLocationSnapshot &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timestamp == other.timestamp &&
          precision == other.precision &&
          isLastKnown == other.isLastKnown;

  @override
  int get hashCode =>
      Object.hash(latitude, longitude, timestamp, precision, isLastKnown);
}

final class SosDraft {
  SosDraft({
    required this.id,
    required this.createdAt,
    required List<String> selectedContactIds,
    required List<SosRecipientSnapshot> recipients,
    required this.message,
    required this.location,
    required this.profileName,
    required this.body,
    required this.status,
    this.smsAttemptId,
    this.smsConfirmedParts = 0,
    this.smsTotalParts = 0,
  }) : selectedContactIds = List.unmodifiable(selectedContactIds),
       recipients = List.unmodifiable(recipients);

  final String id;
  final DateTime createdAt;
  final List<String> selectedContactIds;
  final List<SosRecipientSnapshot> recipients;
  final String? message;
  final SosLocationSnapshot? location;
  final String profileName;
  final String body;
  final SosDraftStatus status;
  final String? smsAttemptId;
  final int smsConfirmedParts;
  final int smsTotalParts;

  bool get isActive => status != SosDraftStatus.cancelled;

  SosDraft withStatus(SosDraftStatus status) => SosDraft(
    id: id,
    createdAt: createdAt,
    selectedContactIds: selectedContactIds,
    recipients: recipients,
    message: message,
    location: location,
    profileName: profileName,
    body: body,
    status: status,
    smsAttemptId: smsAttemptId,
    smsConfirmedParts: smsConfirmedParts,
    smsTotalParts: smsTotalParts,
  );

  SosDraft withSmsResult({
    required SosDraftStatus status,
    required String? attemptId,
    required int confirmedParts,
    required int totalParts,
  }) => SosDraft(
    id: id,
    createdAt: createdAt,
    selectedContactIds: selectedContactIds,
    recipients: recipients,
    message: message,
    location: location,
    profileName: profileName,
    body: body,
    status: status,
    smsAttemptId: attemptId,
    smsConfirmedParts: confirmedParts,
    smsTotalParts: totalParts,
  );

  bool isEquivalentTo({
    required List<String> contactIds,
    required List<SosRecipientSnapshot> recipientSnapshots,
    required String? userMessage,
    required String bodySnapshot,
  }) =>
      _listEquals(selectedContactIds, contactIds) &&
      _sameRecipientTargets(recipients, recipientSnapshots) &&
      message == userMessage &&
      body == bodySnapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SosDraft &&
          id == other.id &&
          createdAt == other.createdAt &&
          _listEquals(selectedContactIds, other.selectedContactIds) &&
          _listEquals(recipients, other.recipients) &&
          message == other.message &&
          location == other.location &&
          profileName == other.profileName &&
          body == other.body &&
          status == other.status &&
          smsAttemptId == other.smsAttemptId &&
          smsConfirmedParts == other.smsConfirmedParts &&
          smsTotalParts == other.smsTotalParts;

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    Object.hashAll(selectedContactIds),
    Object.hashAll(recipients),
    message,
    location,
    profileName,
    body,
    status,
    smsAttemptId,
    smsConfirmedParts,
    smsTotalParts,
  );
}

bool _listEquals(List<Object?> left, List<Object?> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _sameRecipientTargets(
  List<SosRecipientSnapshot> left,
  List<SosRecipientSnapshot> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index].contactId != right[index].contactId ||
        left[index].phoneNumber != right[index].phoneNumber) {
      return false;
    }
  }
  return true;
}
