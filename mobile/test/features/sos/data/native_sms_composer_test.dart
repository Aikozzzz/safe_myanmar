import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sos/data/native_sms_composer.dart';

void main() {
  test('builds an encoded sms URI with recipients and exact body', () {
    const body = 'Help & stay safe?\nLocation: 16.840900, 96.173500';
    final uri = UrlLauncherNativeSmsComposer.buildUri(
      recipients: const ['+12025550123', '09123456789'],
      body: body,
    );

    expect(uri.scheme, 'sms');
    expect(uri.path, '+12025550123,09123456789');
    expect(uri.queryParameters['body'], body);
    expect(uri.toString(), contains('Help+%26+stay+safe%3F'));
    expect(uri.toString(), contains('%0ALocation%3A'));
  });

  test(
    'injectable launcher reports success, false, and exceptions safely',
    () async {
      Uri? launched;
      final successful = UrlLauncherNativeSmsComposer((uri) async {
        launched = uri;
        return true;
      });
      expect(
        await successful.open(recipients: const ['1234567'], body: 'Body'),
        isTrue,
      );
      expect(launched?.scheme, 'sms');

      final failed = UrlLauncherNativeSmsComposer((_) async => false);
      expect(
        await failed.open(recipients: const ['1234567'], body: 'Body'),
        isFalse,
      );

      final throwing = UrlLauncherNativeSmsComposer(
        (_) => throw StateError('private platform detail'),
      );
      expect(
        await throwing.open(recipients: const ['1234567'], body: 'Body'),
        isFalse,
      );
      expect(
        await successful.open(recipients: const [], body: 'Body'),
        isFalse,
      );
    },
  );
}
