import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release networking requires Internet without allowing cleartext', () {
    final mainManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final releaseManifest = File('android/app/src/release/AndroidManifest.xml');

    expect(
      mainManifest,
      contains('android.permission.INTERNET'),
      reason: 'The release app must be able to reach its HTTPS API.',
    );
    expect(mainManifest, isNot(contains('usesCleartextTraffic="true"')));
    expect(mainManifest, isNot(contains('networkSecurityConfig')));
    if (releaseManifest.existsSync()) {
      final release = releaseManifest.readAsStringSync();
      expect(release, isNot(contains('usesCleartextTraffic="true"')));
      expect(release, isNot(contains('networkSecurityConfig')));
    }
  });

  test('debug cleartext exception is scoped to Android emulator host', () {
    final debugManifest = File(
      'android/app/src/debug/AndroidManifest.xml',
    ).readAsStringSync();
    final debugPolicyFile = File(
      'android/app/src/debug/res/xml/network_security_config.xml',
    );

    expect(
      debugManifest,
      contains('android:networkSecurityConfig="@xml/network_security_config"'),
    );
    expect(debugManifest, isNot(contains('usesCleartextTraffic="true"')));
    expect(debugPolicyFile.existsSync(), isTrue);

    final debugPolicy = debugPolicyFile.readAsStringSync();
    expect(debugPolicy, contains('cleartextTrafficPermitted="true"'));
    expect(debugPolicy, contains('<domain>10.0.2.2</domain>'));
    expect(debugPolicy, isNot(contains('includeSubdomains="true"')));
    expect(debugPolicy, isNot(contains('<base-config')));
  });

  test('main manifest requests no sensitive or out-of-scope permissions', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final permissions = RegExp(
      r'<uses-permission\s+android:name="([^"]+)"\s*/>',
    ).allMatches(manifest).map((match) => match.group(1)).toSet();

    expect(permissions, {'android.permission.INTERNET'});
  });
}
