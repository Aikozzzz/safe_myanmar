import '../domain/local_profile.dart';

enum LocalProfilePhase { loading, ready, saving, recoverableError }

enum LocalProfileErrorKind { read, corruptOrUnsupported, write }

final class LocalProfileState {
  const LocalProfileState({
    required this.phase,
    required this.profile,
    required this.errorKind,
  });

  const LocalProfileState.loading()
    : this(phase: LocalProfilePhase.loading, profile: null, errorKind: null);

  const LocalProfileState.ready(LocalProfile value)
    : this(phase: LocalProfilePhase.ready, profile: value, errorKind: null);

  const LocalProfileState.saving(LocalProfile value)
    : this(phase: LocalProfilePhase.saving, profile: value, errorKind: null);

  const LocalProfileState.error({
    required LocalProfileErrorKind kind,
    LocalProfile? profile,
  }) : this(
         phase: LocalProfilePhase.recoverableError,
         profile: profile,
         errorKind: kind,
       );

  final LocalProfilePhase phase;
  final LocalProfile? profile;
  final LocalProfileErrorKind? errorKind;

  bool get isBusy =>
      phase == LocalProfilePhase.loading || phase == LocalProfilePhase.saving;
}
