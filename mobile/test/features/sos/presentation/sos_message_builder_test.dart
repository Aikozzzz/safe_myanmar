import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/sos/domain/sos_draft.dart';
import 'package:mobile/features/sos/presentation/sos_message_builder.dart';
import 'package:mobile/l10n/app_localizations_en.dart';

void main() {
  final strings = AppLocalizationsEn();

  test('builds deterministic current-location body with optional fields', () {
    final body = buildSosMessage(
      strings: strings,
      profileName: ' Test User ',
      location: SosLocationSnapshot(
        latitude: 16.8409,
        longitude: 96.1735,
        timestamp: DateTime.utc(2026, 7, 23, 1, 2, 3),
        precision: LocationPrecision.precise,
        isLastKnown: false,
      ),
      userMessage: ' I need help leaving this area. ',
    );

    expect(
      body,
      'User-prepared SafeMyanmar emergency message.\n'
      'Profile name: Test User\n'
      'Current precise location: 16.840900, 96.173500 at '
      '2026-07-23T01:02:03.000Z. Map: '
      'https://maps.google.com/?q=16.840900,96.173500\n'
      'Message: I need help leaving this area.\n'
      'Please contact authorized emergency or medical help when possible.',
    );
  });

  test('clearly labels last-known location', () {
    final body = buildSosMessage(
      strings: strings,
      profileName: '',
      location: SosLocationSnapshot(
        latitude: 21.9588,
        longitude: 96.0891,
        timestamp: DateTime.utc(2026, 7, 22, 4, 5, 6),
        precision: LocationPrecision.approximate,
        isLastKnown: true,
      ),
      userMessage: null,
    );

    expect(body, contains('Last-known approximate location'));
    expect(body, contains('2026-07-22T04:05:06.000Z'));
    expect(body, isNot(contains('Profile name:')));
  });

  test('states when location is unavailable without inventing coordinates', () {
    final body = buildSosMessage(
      strings: strings,
      profileName: '',
      location: null,
      userMessage: '',
    );

    expect(body, contains('Location unavailable; no coordinates included.'));
    expect(body, isNot(contains('Map:')));
    expect(body, isNot(contains('Message:')));
    expect(body, isNot(contains(RegExp(r'\b(Sent|Delivered)\b'))));
  });
}
