import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/navigation_models.dart';
import 'navigation_dto.dart';

final class CachedNavigationResponse<T> {
  const CachedNavigationResponse({required this.value, required this.cachedAt});

  final T value;
  final DateTime cachedAt;
}

abstract interface class NavigationLocalSource {
  Future<CachedNavigationResponse<ShelterCollectionDto>?> readShelters();
  Future<CachedNavigationResponse<HazardCollectionDto>?> readHazards();
  Future<CachedNavigationResponse<RouteSuggestionsDto>?> readRoutes(
    RouteSuggestionRequest request,
  );
  Future<void> replaceShelters(ShelterCollectionDto value, DateTime cachedAt);
  Future<void> replaceHazards(HazardCollectionDto value, DateTime cachedAt);
  Future<void> replaceRoutes(
    RouteSuggestionsDto value,
    RouteSuggestionRequest request,
    DateTime cachedAt,
  );
}

final class DriftNavigationLocalSource implements NavigationLocalSource {
  const DriftNavigationLocalSource(this._database);

  final AppDatabase _database;

  @override
  Future<CachedNavigationResponse<ShelterCollectionDto>?> readShelters() async {
    final row = await _database
        .select(_database.cachedShelterResponses)
        .getSingleOrNull();
    if (row == null) return null;
    return CachedNavigationResponse(
      value: ShelterCollectionDto.fromJson(_decode(row.payload)),
      cachedAt: _utc(row.cachedAt),
    );
  }

  @override
  Future<CachedNavigationResponse<HazardCollectionDto>?> readHazards() async {
    final row = await _database
        .select(_database.cachedHazardResponses)
        .getSingleOrNull();
    if (row == null) return null;
    return CachedNavigationResponse(
      value: HazardCollectionDto.fromJson(_decode(row.payload)),
      cachedAt: _utc(row.cachedAt),
    );
  }

  @override
  Future<CachedNavigationResponse<RouteSuggestionsDto>?> readRoutes(
    RouteSuggestionRequest request,
  ) async {
    final row = await _database
        .select(_database.cachedRouteResponses)
        .getSingleOrNull();
    if (row == null) return null;
    if (row.originLatitudeE5 == null ||
        row.originLongitudeE5 == null ||
        row.shelterId == null ||
        row.disasterType == null ||
        row.routeProfile == null) {
      await (_database.delete(
        _database.cachedRouteResponses,
      )..where((table) => table.id.equals(row.id))).go();
      return null;
    }
    if (row.originLatitudeE5 != request.originLatitudeE5 ||
        row.originLongitudeE5 != request.originLongitudeE5 ||
        row.shelterId != request.shelterId ||
        row.disasterType != request.disasterType.wireValue ||
        row.routeProfile != request.profile.name) {
      return null;
    }
    return CachedNavigationResponse(
      value: RouteSuggestionsDto.fromJson(_decode(row.payload)),
      cachedAt: _utc(row.cachedAt),
    );
  }

  @override
  Future<void> replaceShelters(
    ShelterCollectionDto value,
    DateTime cachedAt,
  ) async {
    _requireUtc(cachedAt);
    await _database
        .into(_database.cachedShelterResponses)
        .insertOnConflictUpdate(
          CachedShelterResponsesCompanion.insert(
            id: const Value(1),
            payload: jsonEncode(value.toJson()),
            dataAt: value.dataAt.microsecondsSinceEpoch,
            cachedAt: cachedAt.microsecondsSinceEpoch,
          ),
        );
  }

  @override
  Future<void> replaceHazards(
    HazardCollectionDto value,
    DateTime cachedAt,
  ) async {
    _requireUtc(cachedAt);
    await _database
        .into(_database.cachedHazardResponses)
        .insertOnConflictUpdate(
          CachedHazardResponsesCompanion.insert(
            id: const Value(1),
            payload: jsonEncode(value.toJson()),
            dataAt: value.dataAt.microsecondsSinceEpoch,
            cachedAt: cachedAt.microsecondsSinceEpoch,
          ),
        );
  }

  @override
  Future<void> replaceRoutes(
    RouteSuggestionsDto value,
    RouteSuggestionRequest request,
    DateTime cachedAt,
  ) async {
    _requireUtc(cachedAt);
    await _database
        .into(_database.cachedRouteResponses)
        .insertOnConflictUpdate(
          CachedRouteResponsesCompanion.insert(
            id: const Value(1),
            payload: jsonEncode(value.toJson()),
            generatedAt: value.generatedAt.microsecondsSinceEpoch,
            cachedAt: cachedAt.microsecondsSinceEpoch,
            originLatitudeE5: Value(request.originLatitudeE5),
            originLongitudeE5: Value(request.originLongitudeE5),
            shelterId: Value(request.shelterId),
            disasterType: Value(request.disasterType.wireValue),
            routeProfile: Value(request.profile.name),
          ),
        );
  }

  Map<String, Object?> _decode(String payload) {
    try {
      final value = jsonDecode(payload);
      if (value is! Map) throw const NavigationProtocolException();
      return value.cast<String, Object?>();
    } catch (_) {
      throw const NavigationProtocolException();
    }
  }

  DateTime _utc(int value) =>
      DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true);

  void _requireUtc(DateTime value) {
    if (!value.isUtc) {
      throw ArgumentError.value(value, 'cachedAt', 'Must be UTC');
    }
  }
}
