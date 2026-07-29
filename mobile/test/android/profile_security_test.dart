import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String manifest;

  setUpAll(() {
    manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
  });

  test(
    'Android backup cannot restore encrypted profile values without keys',
    () {
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, isNot(contains('android:allowBackup="true"')));
    },
  );

  test('profile management adds no Contacts or biometric permission', () {
    for (final permission in [
      'android.permission.READ_CONTACTS',
      'android.permission.WRITE_CONTACTS',
      'android.permission.GET_ACCOUNTS',
      'android.permission.USE_BIOMETRIC',
      'android.permission.USE_FINGERPRINT',
    ]) {
      expect(manifest, isNot(contains(permission)));
    }

    final permissions = RegExp(
      r'<uses-permission\s+android:name="([^"]+)"\s*/>',
    ).allMatches(manifest).map((match) => match.group(1)).toSet();
    expect(permissions, {
      'android.permission.INTERNET',
      'android.permission.ACCESS_COARSE_LOCATION',
      'android.permission.ACCESS_FINE_LOCATION',
    });
  });
}
