import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import 'alert_dto.dart';

final class AlertRemoteUnavailable implements Exception {
  const AlertRemoteUnavailable();

  @override
  String toString() => 'AlertRemoteUnavailable: Alert service unavailable';
}

final class AlertRemoteException implements Exception {
  const AlertRemoteException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'AlertRemoteException: HTTP status $statusCode';
}

final class AlertRemoteSource {
  AlertRemoteSource({
    required this.client,
    required this.config,
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client client;
  final ApiConfig config;
  final Duration timeout;

  Future<AlertEnvelopeDto> fetchAlerts() async {
    try {
      final response = await client.get(config.alertsUri).timeout(timeout);
      if (response.statusCode == 503) {
        throw const AlertRemoteUnavailable();
      }
      if (response.statusCode != 200) {
        throw AlertRemoteException(response.statusCode);
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) throw const AlertProtocolException();
      return AlertEnvelopeDto.fromJson(decoded.cast<String, Object?>());
    } on AlertProtocolException {
      rethrow;
    } on AlertRemoteUnavailable {
      rethrow;
    } on AlertRemoteException {
      rethrow;
    } on FormatException {
      throw const AlertProtocolException();
    } on TimeoutException {
      throw const AlertRemoteUnavailable();
    } on SocketException {
      throw const AlertRemoteUnavailable();
    } on http.ClientException {
      throw const AlertRemoteUnavailable();
    }
  }
}
