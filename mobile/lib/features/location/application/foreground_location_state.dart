import '../domain/foreground_location.dart';

enum ForegroundLocationPhase {
  notRequested,
  requesting,
  preciseAvailable,
  approximateAvailable,
  denied,
  permanentlyDenied,
  serviceDisabled,
  liveUnavailableWithLastKnown,
  recoverableError,
}

final class ForegroundLocationState {
  const ForegroundLocationState._(this.phase, this.location);

  const ForegroundLocationState.notRequested()
    : this._(ForegroundLocationPhase.notRequested, null);

  const ForegroundLocationState.requesting()
    : this._(ForegroundLocationPhase.requesting, null);

  const ForegroundLocationState.denied()
    : this._(ForegroundLocationPhase.denied, null);

  const ForegroundLocationState.permanentlyDenied()
    : this._(ForegroundLocationPhase.permanentlyDenied, null);

  const ForegroundLocationState.serviceDisabled()
    : this._(ForegroundLocationPhase.serviceDisabled, null);

  const ForegroundLocationState.recoverableError()
    : this._(ForegroundLocationPhase.recoverableError, null);

  ForegroundLocationState.available(ForegroundLocation location)
    : this._(
        location.precision == LocationPrecision.precise
            ? ForegroundLocationPhase.preciseAvailable
            : ForegroundLocationPhase.approximateAvailable,
        location,
      );

  ForegroundLocationState.lastKnown(ForegroundLocation location)
    : this._(ForegroundLocationPhase.liveUnavailableWithLastKnown, location);

  final ForegroundLocationPhase phase;
  final ForegroundLocation? location;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForegroundLocationState &&
          phase == other.phase &&
          location == other.location;

  @override
  int get hashCode => Object.hash(phase, location);
}
