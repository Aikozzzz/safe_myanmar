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

  test('debug cleartext exception is scoped to required local hosts', () {
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
    final domains = RegExp(
      r'<domain>([^<]+)</domain>',
    ).allMatches(debugPolicy).map((match) => match.group(1)).toSet();
    expect(domains, {'localhost', '127.0.0.1', '10.0.2.2'});
    expect(debugPolicy, isNot(contains('includeSubdomains="true"')));
    expect(debugPolicy, isNot(contains('<base-config')));
  });

  test('main manifest requests only Internet and foreground location', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final permissions = RegExp(
      r'<uses-permission\s+android:name="([^"]+)"\s*/>',
    ).allMatches(manifest).map((match) => match.group(1)).toSet();

    expect(permissions, {
      'android.permission.INTERNET',
      'android.permission.ACCESS_COARSE_LOCATION',
      'android.permission.ACCESS_FINE_LOCATION',
    });
    for (final prohibited in [
      'android.permission.ACCESS_BACKGROUND_LOCATION',
      'android.permission.FOREGROUND_SERVICE',
      'android.permission.FOREGROUND_SERVICE_LOCATION',
    ]) {
      expect(manifest, isNot(contains(prohibited)));
    }
  });

  test('debug APK verifies merged transitive permissions fail closed', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('verifyDebugMergedManifest'));
    expect(gradle, contains('dependsOn("processDebugMainManifest")'));
    for (final permission in [
      'android.permission.ACCESS_NETWORK_STATE',
      'android.permission.ACCESS_WIFI_STATE',
    ]) {
      expect(gradle, contains('"$permission"'));
    }
    for (final prohibited in [
      'android.permission.ACCESS_BACKGROUND_LOCATION',
      'android.permission.SEND_SMS',
      'android.permission.READ_SMS',
      'android.permission.RECEIVE_SMS',
    ]) {
      expect(gradle, contains('"$prohibited"'));
    }
    expect(
      gradle,
      contains('check(permission !in manifest)'),
      reason: 'the merged APK manifest must reject prohibited permissions',
    );
    expect(
      gradle,
      contains('dependsOn(verifyDebugMergedManifest)'),
      reason: 'every debug APK must run the merged-manifest verification',
    );
  });

  test('mobile documentation discloses merged permissions and GLES limit', () {
    final readme = File('README.md').readAsStringSync();

    expect(readme, contains('`ACCESS_NETWORK_STATE`'));
    expect(readme, contains('`ACCESS_WIFI_STATE`'));
    expect(readme, contains('No background location permission'));
    expect(readme, contains('does not request Android SMS'));
    expect(readme, contains('GLES 3'));
    expect(readme, contains('future no-map product flavor'));
  });
}
