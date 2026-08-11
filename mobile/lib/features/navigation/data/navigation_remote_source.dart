import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../domain/navigation_models.dart';
import 'navigation_dto.dart';

final class NavigationRemoteUnavailable implements Exception {
  const NavigationRemoteUnavailable();
}

final class NavigationRemoteException implements Exception {
  const NavigationRemoteException(this.statusCode);

  final int statusCode;
}

final class NavigationRemoteSource {
  const NavigationRemoteSource({
    required this.client,
    required this.config,
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client client;
  final ApiConfig config;
  final Duration timeout;

  Future<ShelterCollectionDto> fetchShelters() async =>
      ShelterCollectionDto.fromJson(await _get(config.sheltersUri));

  Future<HazardCollectionDto> fetchHazards() async =>
      HazardCollectionDto.fromJson(await _get(config.hazardsUri));

  Future<ContextAreaCollectionDto> findContextAreas(
    ContextAreaRequest request,
  ) async {
    final body = jsonEncode({
      'origin': {
        'latitude': request.origin.latitude,
        'longitude': request.origin.longitude,
      },
      'disaster_type': request.disasterType.wireValue,
      'scenario': request.scenario.wireValue,
      'search_radius_m': request.searchRadiusM,
    });
    return ContextAreaCollectionDto.fromJson(
      await _request(
        () => client.post(
          config.contextAreasUri,
          headers: const {'content-type': 'application/json'},
          body: body,
        ),
      ),
    );
  }

  Future<RouteSuggestionsDto> fetchRouteSuggestions(
    RouteSuggestionRequest request,
  ) async {
    final body = jsonEncode({
      'origin': {
        'latitude': request.origin.latitude,
        'longitude': request.origin.longitude,
      },
      'shelter_id': request.shelterId,
      'context_area_id': request.contextAreaId,
      'disaster_type': request.disasterType.wireValue,
      'scenario': request.scenario.wireValue,
      'search_radius_m': request.searchRadiusM,
      'profile': request.profile.name,
    });
    final json = await _request(
      () => client.post(
        config.routeSuggestionsUri,
        headers: const {'content-type': 'application/json'},
        body: body,
      ),
    );
    final response = RouteSuggestionsDto.fromJson(json);
    if (response.profile != request.profile) {
      throw const NavigationProtocolException();
    }
    return response;
  }

  Future<Map<String, Object?>> _get(Uri uri) => _request(() => client.get(uri));

  Future<Map<String, Object?>> _request(
    Future<http.Response> Function() send,
  ) async {
    try {
      final response = await send().timeout(timeout);
      if (response.statusCode == 503) {
        throw const NavigationRemoteUnavailable();
      }
      if (response.statusCode != 200) {
        throw NavigationRemoteException(response.statusCode);
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) throw const NavigationProtocolException();
      return decoded.cast<String, Object?>();
    } on NavigationProtocolException {
      rethrow;
    } on NavigationRemoteUnavailable {
      rethrow;
    } on NavigationRemoteException {
      rethrow;
    } on FormatException {
      throw const NavigationProtocolException();
    } on TimeoutException {
      throw const NavigationRemoteUnavailable();
    } on IOException {
      throw const NavigationRemoteUnavailable();
    } on http.ClientException {
      throw const NavigationRemoteUnavailable();
    }
  }
}
