import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String manifest;

  setUpAll(() {
    manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync().replaceAll('\r\n', '\n');
  });

  test(
    'SOS requests send-SMS permission but no SMS or contacts read access',
    () {
      expect(manifest, contains('android.permission.SEND_SMS'));
      expect(manifest, contains('android.permission.READ_PHONE_STATE'));
      for (final permission in [
        'android.permission.READ_SMS',
        'android.permission.RECEIVE_SMS',
        'android.permission.READ_CONTACTS',
        'android.permission.WRITE_CONTACTS',
      ]) {
        expect(manifest, isNot(contains(permission)));
      }
    },
  );

  test('adds only the sms VIEW package-visibility query', () {
    expect(
      manifest,
      contains(
        '<action android:name="android.intent.action.VIEW"/>\n'
        '            <data android:scheme="sms"/>',
      ),
    );
    expect(RegExp(r'android:scheme="sms"').allMatches(manifest), hasLength(1));
    expect(manifest, isNot(contains('android:scheme="smsto"')));
  });
}
