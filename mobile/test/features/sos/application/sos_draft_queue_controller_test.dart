import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/sos/application/providers.dart';
import 'package:mobile/features/sos/application/sos_draft_queue_controller.dart';
import 'package:mobile/features/sos/application/sos_draft_queue_state.dart';
import 'package:mobile/features/sos/domain/sos_draft.dart';
import 'package:mobile/features/sos/domain/sos_draft_repository.dart';

import '../../../support/fake_sos_draft_repository.dart';

void main() {
  late FakeSosDraftRepository repository;
  late ProviderContainer container;
  late DateTime now;
  var nextId = 0;

  setUp(() {
    repository = FakeSosDraftRepository();
    now = DateTime.utc(2026, 7, 23, 1);
    nextId = 0;
    container = ProviderContainer(
      overrides: [
        sosDraftRepositoryProvider.overrideWithValue(repository),
        sosClockProvider.overrideWithValue(() => now),
        sosDraftIdFactoryProvider.overrideWithValue(() => 'draft-${++nextId}'),
      ],
    );
    addTearDown(container.dispose);
  });

  SosDraftQueueController controller() =>
      container.read(sosDraftQueueControllerProvider.notifier);

  SosDraftQueueState state() => container.read(sosDraftQueueControllerProvider);

  Future<void> load() async {
    state();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('prepares a stable UTC draft with normalized snapshots', () async {
    await load();

    final result = await controller().prepare(preparation());

    expect(result.result, SosDraftOperationResult.success);
    expect(result.draft?.id, 'draft-1');
    expect(result.draft?.createdAt, now);
    expect(result.draft?.status, SosDraftStatus.prepared);
    expect(result.draft?.selectedContactIds, ['contact-1']);
    expect(result.draft?.profileName, 'Test User');
    expect(result.draft?.body, 'Exact prepared SMS body.');
    expect(repository.writes, 1);
  });

  test('allows a Bluetooth-only draft only when explicitly enabled', () async {
    await load();

    final result = await controller().prepare(
      SosDraftPreparation(
        recipients: const [],
        message: null,
        location: null,
        profileName: 'Test User',
        body: 'Bluetooth-only SOS payload.',
        allowNoRecipients: true,
      ),
    );

    expect(result.result, SosDraftOperationResult.success);
    expect(result.draft?.recipients, isEmpty);
  });

  test('equivalent active draft reuses its immutable body snapshot', () async {
    await load();
    final first = (await controller().prepare(preparation())).draft!;
    await controller().setStatus(first.id, SosDraftStatus.failedToOpen);
    now = now.add(const Duration(minutes: 4));

    final reused = await controller().prepare(preparation());

    expect(reused.draft?.id, first.id);
    expect(reused.draft?.createdAt, first.createdAt);
    expect(reused.draft?.status, SosDraftStatus.prepared);
    expect(reused.draft?.body, first.body);
    expect(state().drafts, hasLength(1));

    final changedSnapshot = await controller().prepare(
      SosDraftPreparation(
        recipients: const [
          SosRecipientSnapshot(
            contactId: 'contact-1',
            name: 'Updated Contact Name',
            phoneNumber: '+12025550123',
          ),
        ],
        message: 'I need help.',
        location: SosLocationSnapshot(
          latitude: 17,
          longitude: 97,
          timestamp: now,
          precision: LocationPrecision.approximate,
          isLastKnown: true,
        ),
        profileName: 'Updated User',
        body: 'Updated exact prepared SMS body.',
      ),
    );

    expect(changedSnapshot.draft?.id, 'draft-2');
    expect(changedSnapshot.draft?.location?.isLastKnown, isTrue);
    expect(
      changedSnapshot.draft?.recipients.single.name,
      'Updated Contact Name',
    );
    expect(changedSnapshot.draft?.profileName, 'Updated User');
    expect(changedSnapshot.draft?.body, 'Updated exact prepared SMS body.');
    expect(first.body, 'Exact prepared SMS body.');
    expect(state().drafts, hasLength(2));

    now = now.add(const Duration(minutes: 2));
    final outsideWindow = await controller().prepare(preparation());
    expect(outsideWindow.draft?.id, 'draft-3');
    expect(state().drafts, hasLength(3));
  });

  test(
    'cancelled drafts are history and are not duplicate candidates',
    () async {
      await load();
      final first = (await controller().prepare(preparation())).draft!;
      await controller().setStatus(first.id, SosDraftStatus.cancelled);

      final second = await controller().prepare(preparation());

      expect(second.draft?.id, 'draft-2');
      expect(state().drafts.map((value) => value.status), [
        SosDraftStatus.prepared,
        SosDraftStatus.cancelled,
      ]);
    },
  );

  test('maximum queue never exceeds five and requires removal', () async {
    repository.drafts = [
      for (var index = 0; index < maxSosDrafts; index++)
        draft(id: 'saved-$index', message: 'message-$index'),
    ];
    await load();

    final result = await controller().prepare(preparation(message: 'new'));

    expect(result.result, SosDraftOperationResult.maximumDrafts);
    expect(state().drafts, hasLength(maxSosDrafts));
    expect(repository.writes, 0);
    await controller().remove('saved-0');
    expect(state().drafts, hasLength(maxSosDrafts - 1));
  });

  test('records only allowed statuses and supports explicit removal', () async {
    await load();
    final prepared = (await controller().prepare(preparation())).draft!;

    for (final status in [
      SosDraftStatus.smsSending,
      SosDraftStatus.smsSent,
      SosDraftStatus.smsFailed,
      SosDraftStatus.composerOpened,
      SosDraftStatus.failedToOpen,
      SosDraftStatus.cancelled,
    ]) {
      expect(
        await controller().setStatus(prepared.id, status),
        SosDraftOperationResult.success,
      );
      expect(state().drafts.single.status, status);
    }
    expect(
      await controller().remove(prepared.id),
      SosDraftOperationResult.success,
    );
    expect(state().drafts, isEmpty);
  });

  test('corrupt queue is recoverable only by explicit reset', () async {
    repository.readError = const SosDraftReadException(
      SosDraftReadFailureKind.corrupt,
    );
    await load();

    expect(state().errorKind, SosDraftQueueErrorKind.corruptOrUnsupported);
    expect(repository.clears, 0);
    repository.readError = null;
    expect(
      await controller().resetUnreadableData(),
      SosDraftOperationResult.success,
    );
    expect(repository.clears, 1);
    expect(state().phase, SosDraftQueuePhase.ready);
  });
}

SosDraftPreparation preparation({
  String message = 'I need help.',
  SosLocationSnapshot? location,
}) => SosDraftPreparation(
  recipients: const [
    SosRecipientSnapshot(
      contactId: 'contact-1',
      name: 'Test Contact',
      phoneNumber: '+12025550123',
    ),
  ],
  message: message,
  profileName: 'Test User',
  body: 'Exact prepared SMS body.',
  location:
      location ??
      SosLocationSnapshot(
        latitude: 16.8409,
        longitude: 96.1735,
        timestamp: DateTime.utc(2026, 7, 23),
        precision: LocationPrecision.precise,
        isLastKnown: false,
      ),
);

SosDraft draft({required String id, required String message}) => SosDraft(
  id: id,
  createdAt: DateTime.utc(2026, 7, 22),
  selectedContactIds: const ['contact-1'],
  recipients: const [
    SosRecipientSnapshot(
      contactId: 'contact-1',
      name: 'Test Contact',
      phoneNumber: '+12025550123',
    ),
  ],
  message: message,
  location: null,
  profileName: 'Test User',
  body: 'Exact prepared SMS body for $message.',
  status: SosDraftStatus.prepared,
);
