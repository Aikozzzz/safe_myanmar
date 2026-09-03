import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/phone_number.dart';
import '../domain/sos_draft.dart';
import '../domain/sos_draft_repository.dart';
import 'providers.dart';
import 'sos_draft_queue_state.dart';

enum SosDraftOperationResult {
  success,
  busy,
  invalid,
  notFound,
  maximumDrafts,
  failed,
}

final class SosDraftPreparation {
  SosDraftPreparation({
    required List<SosRecipientSnapshot> recipients,
    required this.message,
    required this.location,
    required this.profileName,
    required this.body,
    this.bleAlias,
    this.bleMessage,
    this.allowNoRecipients = false,
  }) : recipients = List.unmodifiable(recipients);

  final List<SosRecipientSnapshot> recipients;
  final String? message;
  final SosLocationSnapshot? location;
  final String profileName;
  final String body;
  final String? bleAlias;
  final String? bleMessage;
  final bool allowNoRecipients;
}

final class SosPrepareResult {
  const SosPrepareResult(this.result, [this.draft]);

  final SosDraftOperationResult result;
  final SosDraft? draft;
}

final class SosDraftQueueController extends Notifier<SosDraftQueueState> {
  late SosDraftRepository _repository;
  late DateTime Function() _clock;
  late String Function() _createId;
  List<SosDraft>? _retryDrafts;

  @override
  SosDraftQueueState build() {
    _repository = ref.watch(sosDraftRepositoryProvider);
    _clock = ref.watch(sosClockProvider);
    _createId = ref.watch(sosDraftIdFactoryProvider);
    unawaited(Future<void>.microtask(_load));
    return const SosDraftQueueState.loading();
  }

  Future<void> retry() async {
    final drafts = _retryDrafts;
    if (state.errorKind == SosDraftQueueErrorKind.write && drafts != null) {
      await _save(drafts);
      return;
    }
    await _load();
  }

  Future<SosPrepareResult> prepare(SosDraftPreparation preparation) async {
    if (state.isBusy) {
      return const SosPrepareResult(SosDraftOperationResult.busy);
    }
    final recipients = preparation.recipients;
    final normalizedMessage = preparation.message?.trim();
    final normalizedBleAlias = normalizeSosBleText(preparation.bleAlias);
    final normalizedBleMessage = normalizeSosBleText(preparation.bleMessage);
    if ((!preparation.allowNoRecipients && !_validRecipients(recipients)) ||
        (preparation.allowNoRecipients &&
            recipients.isNotEmpty &&
            !_validRecipients(recipients)) ||
        preparation.profileName.length > maxSosProfileNameLength ||
        preparation.body.trim().isEmpty ||
        preparation.body.length > maxSosBodyLength ||
        (normalizedMessage != null &&
            normalizedMessage.length > maxSosMessageLength) ||
        !isValidSosBleAlias(preparation.bleAlias) ||
        !isValidSosBleMessage(preparation.bleMessage)) {
      return const SosPrepareResult(SosDraftOperationResult.invalid);
    }
    final message = normalizedMessage == null || normalizedMessage.isEmpty
        ? null
        : normalizedMessage;
    final contactIds = recipients.map((value) => value.contactId).toList();
    final now = _clock().toUtc();
    final existingIndex = state.drafts.indexWhere((draft) {
      final age = now.difference(draft.createdAt);
      return draft.isActive &&
          !age.isNegative &&
          age <= sosDuplicateWindow &&
          draft.isEquivalentTo(
            contactIds: contactIds,
            recipientSnapshots: recipients,
            userMessage: message,
            bodySnapshot: preparation.body,
            bleAlias: normalizedBleAlias,
            bleMessage: normalizedBleMessage,
          );
    });

    late final SosDraft draft;
    late final List<SosDraft> updated;
    if (existingIndex >= 0) {
      draft = state.drafts[existingIndex].withStatus(SosDraftStatus.prepared);
      updated = state.drafts.toList()..[existingIndex] = draft;
    } else {
      if (state.drafts.length >= maxSosDrafts) {
        return const SosPrepareResult(SosDraftOperationResult.maximumDrafts);
      }
      draft = SosDraft(
        id: _createId(),
        createdAt: now,
        selectedContactIds: contactIds,
        recipients: recipients,
        message: message,
        location: preparation.location,
        profileName: preparation.profileName,
        body: preparation.body,
        status: SosDraftStatus.prepared,
        bleAlias: normalizedBleAlias,
        bleMessage: normalizedBleMessage,
      );
      updated = [draft, ...state.drafts];
    }
    if (!await _save(updated)) {
      return const SosPrepareResult(SosDraftOperationResult.failed);
    }
    return SosPrepareResult(SosDraftOperationResult.success, draft);
  }

  Future<SosDraftOperationResult> setStatus(
    String id,
    SosDraftStatus status,
  ) async {
    if (state.isBusy) return SosDraftOperationResult.busy;
    final index = state.drafts.indexWhere((draft) => draft.id == id);
    if (index < 0) return SosDraftOperationResult.notFound;
    final updated = state.drafts.toList();
    updated[index] = updated[index].withStatus(status);
    return await _save(updated)
        ? SosDraftOperationResult.success
        : SosDraftOperationResult.failed;
  }

  Future<SosDraftOperationResult> setSmsResult(
    String id, {
    required SosDraftStatus status,
    required String? attemptId,
    required int confirmedParts,
    required int totalParts,
  }) async {
    if (state.isBusy) return SosDraftOperationResult.busy;
    if (confirmedParts < 0 ||
        totalParts < 0 ||
        confirmedParts > totalParts ||
        !{
          SosDraftStatus.smsSending,
          SosDraftStatus.smsSent,
          SosDraftStatus.smsPartial,
          SosDraftStatus.smsUnknown,
          SosDraftStatus.smsFailed,
        }.contains(status)) {
      return SosDraftOperationResult.invalid;
    }
    final index = state.drafts.indexWhere((draft) => draft.id == id);
    if (index < 0) return SosDraftOperationResult.notFound;
    final updated = state.drafts.toList();
    updated[index] = updated[index].withSmsResult(
      status: status,
      attemptId: attemptId,
      confirmedParts: confirmedParts,
      totalParts: totalParts,
    );
    return await _save(updated)
        ? SosDraftOperationResult.success
        : SosDraftOperationResult.failed;
  }

  Future<SosDraftOperationResult> remove(String id) async {
    if (state.isBusy) return SosDraftOperationResult.busy;
    if (!state.drafts.any((draft) => draft.id == id)) {
      return SosDraftOperationResult.notFound;
    }
    final updated = state.drafts.where((draft) => draft.id != id).toList();
    return await _save(updated)
        ? SosDraftOperationResult.success
        : SosDraftOperationResult.failed;
  }

  Future<SosDraftOperationResult> resetUnreadableData() async {
    if (state.isBusy ||
        state.errorKind != SosDraftQueueErrorKind.corruptOrUnsupported) {
      return SosDraftOperationResult.busy;
    }
    state = const SosDraftQueueState.loading();
    try {
      await _repository.clear();
      _retryDrafts = null;
      state = const SosDraftQueueState.ready([]);
      return SosDraftOperationResult.success;
    } on Object {
      state = const SosDraftQueueState.error(kind: SosDraftQueueErrorKind.read);
      return SosDraftOperationResult.failed;
    }
  }

  Future<void> _load() async {
    state = const SosDraftQueueState.loading();
    try {
      final drafts = await _repository.read();
      _retryDrafts = null;
      state = SosDraftQueueState.ready(drafts);
    } on SosDraftReadException catch (error) {
      state = SosDraftQueueState.error(
        kind: error.kind == SosDraftReadFailureKind.unavailable
            ? SosDraftQueueErrorKind.read
            : SosDraftQueueErrorKind.corruptOrUnsupported,
      );
    } on Object {
      state = const SosDraftQueueState.error(kind: SosDraftQueueErrorKind.read);
    }
  }

  Future<bool> _save(List<SosDraft> drafts) async {
    final previous = state.drafts;
    _retryDrafts = List.unmodifiable(drafts);
    state = SosDraftQueueState.saving(_retryDrafts!);
    try {
      await _repository.write(_retryDrafts!);
      _retryDrafts = null;
      state = SosDraftQueueState.ready(List.unmodifiable(drafts));
      return true;
    } on Object {
      state = SosDraftQueueState.error(
        kind: SosDraftQueueErrorKind.write,
        drafts: previous,
      );
      return false;
    }
  }

  bool _validRecipients(List<SosRecipientSnapshot> recipients) {
    if (recipients.isEmpty || recipients.length > 10) return false;
    final ids = <String>{};
    for (final recipient in recipients) {
      final phone = validateAndNormalizePhoneNumber(recipient.phoneNumber);
      if (recipient.contactId.isEmpty ||
          !ids.add(recipient.contactId) ||
          recipient.name.trim().isEmpty ||
          !phone.isValid ||
          phone.normalized != recipient.phoneNumber) {
        return false;
      }
    }
    return true;
  }
}
