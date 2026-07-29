import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/local_profile.dart';
import '../domain/local_profile_repository.dart';
import '../domain/phone_number.dart';
import 'local_profile_state.dart';
import 'providers.dart';

enum LocalProfileOperationResult {
  success,
  busy,
  invalid,
  notFound,
  maximumContacts,
  failed,
}

final class LocalProfileController extends Notifier<LocalProfileState> {
  late LocalProfileRepository _repository;
  late String Function() _createContactId;
  LocalProfile? _retryProfile;

  @override
  LocalProfileState build() {
    _repository = ref.watch(localProfileRepositoryProvider);
    _createContactId = ref.watch(contactIdFactoryProvider);
    unawaited(Future<void>.microtask(_load));
    return const LocalProfileState.loading();
  }

  Future<void> retry() async {
    final retryProfile = _retryProfile;
    if (state.errorKind == LocalProfileErrorKind.write &&
        retryProfile != null) {
      await _save(retryProfile);
      return;
    }
    await _load();
  }

  Future<LocalProfileOperationResult> saveDisplayName(String displayName) {
    final profile = state.profile;
    final normalizedName = displayName.trim();
    if (profile == null || state.isBusy) {
      return Future.value(LocalProfileOperationResult.busy);
    }
    if (normalizedName.isEmpty ||
        normalizedName.length > maxProfileDisplayNameLength) {
      return Future.value(LocalProfileOperationResult.invalid);
    }
    return _save(profile.copyWith(displayName: normalizedName));
  }

  Future<LocalProfileOperationResult> saveContact({
    String? id,
    required String name,
    required String phoneNumber,
    required String label,
    required bool selectedForSos,
  }) {
    final profile = state.profile;
    if (profile == null || state.isBusy) {
      return Future.value(LocalProfileOperationResult.busy);
    }
    final normalizedName = name.trim();
    final normalizedLabel = label.trim();
    final phoneValidation = validateAndNormalizePhoneNumber(phoneNumber);
    if (normalizedName.isEmpty ||
        normalizedName.length > maxEmergencyContactNameLength ||
        normalizedLabel.isEmpty ||
        normalizedLabel.length > maxEmergencyContactLabelLength ||
        !phoneValidation.isValid) {
      return Future.value(LocalProfileOperationResult.invalid);
    }

    final contacts = profile.contacts.toList();
    if (id == null) {
      if (contacts.length >= maxEmergencyContacts) {
        return Future.value(LocalProfileOperationResult.maximumContacts);
      }
      contacts.add(
        EmergencyContact(
          id: _createContactId(),
          name: normalizedName,
          phoneNumber: phoneValidation.normalized!,
          label: normalizedLabel,
          selectedForSos: selectedForSos,
        ),
      );
    } else {
      final index = contacts.indexWhere((contact) => contact.id == id);
      if (index < 0) {
        return Future.value(LocalProfileOperationResult.notFound);
      }
      contacts[index] = EmergencyContact(
        id: id,
        name: normalizedName,
        phoneNumber: phoneValidation.normalized!,
        label: normalizedLabel,
        selectedForSos: selectedForSos,
      );
    }
    return _save(profile.copyWith(contacts: contacts));
  }

  Future<LocalProfileOperationResult> deleteContact(String id) {
    final profile = state.profile;
    if (profile == null || state.isBusy) {
      return Future.value(LocalProfileOperationResult.busy);
    }
    if (profile.contactById(id) == null) {
      return Future.value(LocalProfileOperationResult.notFound);
    }
    return _save(
      profile.copyWith(
        contacts: profile.contacts
            .where((contact) => contact.id != id)
            .toList(),
      ),
    );
  }

  Future<LocalProfileOperationResult> setSelectedForSos(
    String id,
    bool selected,
  ) {
    final profile = state.profile;
    if (profile == null || state.isBusy) {
      return Future.value(LocalProfileOperationResult.busy);
    }
    final contacts = profile.contacts.toList();
    final index = contacts.indexWhere((contact) => contact.id == id);
    if (index < 0) {
      return Future.value(LocalProfileOperationResult.notFound);
    }
    contacts[index] = contacts[index].copyWith(selectedForSos: selected);
    return _save(profile.copyWith(contacts: contacts));
  }

  Future<LocalProfileOperationResult> resetUnreadableData() async {
    if (state.isBusy || state.profile != null) {
      return LocalProfileOperationResult.busy;
    }
    state = const LocalProfileState.loading();
    try {
      await _repository.clear();
      _retryProfile = null;
      state = LocalProfileState.ready(LocalProfile.empty());
      return LocalProfileOperationResult.success;
    } on Object {
      state = const LocalProfileState.error(kind: LocalProfileErrorKind.read);
      return LocalProfileOperationResult.failed;
    }
  }

  Future<void> _load() async {
    state = const LocalProfileState.loading();
    try {
      final profile = await _repository.read();
      _retryProfile = null;
      state = LocalProfileState.ready(profile);
    } on LocalProfileReadException catch (error) {
      state = LocalProfileState.error(
        kind: error.kind == LocalProfileReadFailureKind.unavailable
            ? LocalProfileErrorKind.read
            : LocalProfileErrorKind.corruptOrUnsupported,
      );
    } on Object {
      state = const LocalProfileState.error(kind: LocalProfileErrorKind.read);
    }
  }

  Future<LocalProfileOperationResult> _save(LocalProfile profile) async {
    if (state.isBusy) return LocalProfileOperationResult.busy;
    final previous = state.profile;
    if (previous == null) return LocalProfileOperationResult.busy;
    _retryProfile = profile;
    state = LocalProfileState.saving(profile);
    try {
      await _repository.write(profile);
      _retryProfile = null;
      state = LocalProfileState.ready(profile);
      return LocalProfileOperationResult.success;
    } on Object {
      state = LocalProfileState.error(
        kind: LocalProfileErrorKind.write,
        profile: previous,
      );
      return LocalProfileOperationResult.failed;
    }
  }
}
