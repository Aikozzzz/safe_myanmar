import '../domain/sos_draft.dart';

enum SosDraftQueuePhase { loading, ready, saving, recoverableError }

enum SosDraftQueueErrorKind { read, corruptOrUnsupported, write }

final class SosDraftQueueState {
  const SosDraftQueueState({
    required this.phase,
    required this.drafts,
    required this.errorKind,
  });

  const SosDraftQueueState.loading()
    : this(
        phase: SosDraftQueuePhase.loading,
        drafts: const [],
        errorKind: null,
      );

  const SosDraftQueueState.ready(List<SosDraft> drafts)
    : this(phase: SosDraftQueuePhase.ready, drafts: drafts, errorKind: null);

  const SosDraftQueueState.saving(List<SosDraft> drafts)
    : this(phase: SosDraftQueuePhase.saving, drafts: drafts, errorKind: null);

  const SosDraftQueueState.error({
    required SosDraftQueueErrorKind kind,
    List<SosDraft> drafts = const [],
  }) : this(
         phase: SosDraftQueuePhase.recoverableError,
         drafts: drafts,
         errorKind: kind,
       );

  final SosDraftQueuePhase phase;
  final List<SosDraft> drafts;
  final SosDraftQueueErrorKind? errorKind;

  bool get isBusy =>
      phase == SosDraftQueuePhase.loading || phase == SosDraftQueuePhase.saving;
}
