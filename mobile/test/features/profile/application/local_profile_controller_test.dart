import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/application/local_profile_controller.dart';
import 'package:mobile/features/profile/application/local_profile_state.dart';
import 'package:mobile/features/profile/application/providers.dart';
import 'package:mobile/features/profile/domain/local_profile.dart';
import 'package:mobile/features/profile/domain/local_profile_repository.dart';

import '../../../support/fake_local_profile_repository.dart';

void main() {
  late FakeLocalProfileRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeLocalProfileRepository();
    var id = 0;
    container = ProviderContainer(
      overrides: [
        localProfileRepositoryProvider.overrideWithValue(repository),
        contactIdFactoryProvider.overrideWithValue(() => 'contact-${++id}'),
      ],
    );
    addTearDown(container.dispose);
  });

  LocalProfileController controller() =>
      container.read(localProfileControllerProvider.notifier);

  LocalProfileState state() => container.read(localProfileControllerProvider);

  Future<void> load() async {
    state();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('exposes loading then ready including an empty profile', () async {
    final completer = Completer<LocalProfile>();
    repository.readCompleter = completer;

    expect(state().phase, LocalProfilePhase.loading);
    await Future<void>.delayed(Duration.zero);
    expect(state().phase, LocalProfilePhase.loading);

    completer.complete(LocalProfile.empty());
    await Future<void>.delayed(Duration.zero);
    expect(state().phase, LocalProfilePhase.ready);
    expect(state().profile, LocalProfile.empty());
  });

  test('saves trimmed display name', () async {
    await load();

    expect(
      await controller().saveDisplayName('  Test User  '),
      LocalProfileOperationResult.success,
    );

    expect(state().profile?.displayName, 'Test User');
    expect(repository.writes, 1);
  });

  test(
    'adds, edits, selects, and deletes a stable normalized contact',
    () async {
      await load();

      expect(
        await controller().saveContact(
          name: ' Test Contact ',
          phoneNumber: ' +1 (202) 555-0123 ',
          label: ' Family ',
          selectedForSos: false,
        ),
        LocalProfileOperationResult.success,
      );
      final created = state().profile!.contacts.single;
      expect(created.id, 'contact-1');
      expect(created.phoneNumber, '+12025550123');

      await controller().saveContact(
        id: created.id,
        name: 'Updated Contact',
        phoneNumber: '0123456789',
        label: 'Friend',
        selectedForSos: false,
      );
      expect(state().profile!.contacts.single.id, created.id);
      expect(state().profile!.contacts.single.name, 'Updated Contact');

      await controller().setSelectedForSos(created.id, true);
      expect(state().profile!.contacts.single.selectedForSos, isTrue);

      await controller().deleteContact(created.id);
      expect(state().profile!.contacts, isEmpty);
    },
  );

  test('enforces ten-contact maximum without another write', () async {
    repository.profile = LocalProfile(
      displayName: '',
      contacts: List.generate(
        maxEmergencyContacts,
        (index) => EmergencyContact(
          id: 'id-$index',
          name: 'Contact $index',
          phoneNumber: '1234567',
          label: 'Label',
          selectedForSos: false,
        ),
      ),
    );
    await load();

    expect(
      await controller().saveContact(
        name: 'Extra Contact',
        phoneNumber: '1234567',
        label: 'Friend',
        selectedForSos: false,
      ),
      LocalProfileOperationResult.maximumContacts,
    );
    expect(repository.writes, 0);
  });

  test('read failure is recoverable without exposing data', () async {
    repository.readError = const LocalProfileReadException(
      LocalProfileReadFailureKind.unavailable,
    );
    await load();

    expect(state().phase, LocalProfilePhase.recoverableError);
    expect(state().errorKind, LocalProfileErrorKind.read);
    expect(state().profile, isNull);

    repository.readError = null;
    await controller().retry();
    expect(state().phase, LocalProfilePhase.ready);
  });

  test(
    'corrupt read requires explicit reset and then recovers empty',
    () async {
      repository.readError = const LocalProfileReadException(
        LocalProfileReadFailureKind.corrupt,
      );
      await load();

      expect(state().errorKind, LocalProfileErrorKind.corruptOrUnsupported);
      expect(repository.clears, 0);

      repository.readError = null;
      expect(
        await controller().resetUnreadableData(),
        LocalProfileOperationResult.success,
      );
      expect(repository.clears, 1);
      expect(state().profile, LocalProfile.empty());
    },
  );

  test(
    'write error preserves saved state and retries pending change',
    () async {
      repository.profile = LocalProfile(
        displayName: 'Saved',
        contacts: const [],
      );
      await load();
      repository.writeError = const LocalProfileWriteException();

      expect(
        await controller().saveDisplayName('Pending'),
        LocalProfileOperationResult.failed,
      );
      expect(state().phase, LocalProfilePhase.recoverableError);
      expect(state().errorKind, LocalProfileErrorKind.write);
      expect(state().profile?.displayName, 'Saved');

      repository.writeError = null;
      await controller().retry();
      expect(state().phase, LocalProfilePhase.ready);
      expect(state().profile?.displayName, 'Pending');
    },
  );

  test('invalid contact is rejected before storage', () async {
    await load();

    expect(
      await controller().saveContact(
        name: 'Contact',
        phoneNumber: '12letters',
        label: 'Friend',
        selectedForSos: false,
      ),
      LocalProfileOperationResult.invalid,
    );
    expect(repository.writes, 0);
  });

  test('rejects profile fields that cannot be safely persisted', () async {
    await load();

    expect(
      await controller().saveDisplayName(
        List.filled(maxProfileDisplayNameLength + 1, 'x').join(),
      ),
      LocalProfileOperationResult.invalid,
    );
    expect(
      await controller().saveContact(
        name: List.filled(maxEmergencyContactNameLength + 1, 'x').join(),
        phoneNumber: '1234567',
        label: 'Family',
        selectedForSos: true,
      ),
      LocalProfileOperationResult.invalid,
    );
    expect(
      await controller().saveContact(
        name: 'Contact',
        phoneNumber: '1234567',
        label: List.filled(maxEmergencyContactLabelLength + 1, 'x').join(),
        selectedForSos: true,
      ),
      LocalProfileOperationResult.invalid,
    );
    expect(repository.writes, 0);
  });
}
