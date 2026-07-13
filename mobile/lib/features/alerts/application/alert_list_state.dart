import '../domain/earthquake.dart';

enum AlertListPhase { loading, data, empty, unavailable }

enum AlertPresentationStatus { live, cached, stale }

enum AlertListErrorKind { remoteUnavailable, invalidData, storage }

final class AlertListState {
  AlertListState({
    required this.phase,
    required List<Earthquake> items,
    required this.presentationStatus,
    required this.lastSuccessfulRefreshAt,
    required this.isRefreshing,
    required this.errorKind,
  }) : items = List.unmodifiable(items);

  final AlertListPhase phase;
  final List<Earthquake> items;
  final AlertPresentationStatus? presentationStatus;
  final DateTime? lastSuccessfulRefreshAt;
  final bool isRefreshing;
  final AlertListErrorKind? errorKind;

  AlertListState copyWith({
    AlertListPhase? phase,
    List<Earthquake>? items,
    AlertPresentationStatus? presentationStatus,
    DateTime? lastSuccessfulRefreshAt,
    bool? isRefreshing,
    AlertListErrorKind? errorKind,
    bool clearPresentationStatus = false,
    bool clearLastSuccessfulRefreshAt = false,
    bool clearErrorKind = false,
  }) => AlertListState(
    phase: phase ?? this.phase,
    items: items ?? this.items,
    presentationStatus: clearPresentationStatus
        ? null
        : presentationStatus ?? this.presentationStatus,
    lastSuccessfulRefreshAt: clearLastSuccessfulRefreshAt
        ? null
        : lastSuccessfulRefreshAt ?? this.lastSuccessfulRefreshAt,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    errorKind: clearErrorKind ? null : errorKind ?? this.errorKind,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AlertListState &&
            phase == other.phase &&
            _listEquals(items, other.items) &&
            presentationStatus == other.presentationStatus &&
            lastSuccessfulRefreshAt == other.lastSuccessfulRefreshAt &&
            isRefreshing == other.isRefreshing &&
            errorKind == other.errorKind;
  }

  @override
  int get hashCode => Object.hash(
    phase,
    Object.hashAll(items),
    presentationStatus,
    lastSuccessfulRefreshAt,
    isRefreshing,
    errorKind,
  );

  @override
  String toString() =>
      'AlertListState(phase: $phase, items: ${items.length}, '
      'presentationStatus: $presentationStatus, '
      'lastSuccessfulRefreshAt: $lastSuccessfulRefreshAt, '
      'isRefreshing: $isRefreshing, errorKind: $errorKind)';
}

bool _listEquals(List<Object?> left, List<Object?> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
