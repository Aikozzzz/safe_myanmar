import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android launcher label references the localized app name resource', () {
    final manifestFile = File('android/app/src/main/AndroidManifest.xml');
    final stringsFile = File('android/app/src/main/res/values/strings.xml');

    expect(stringsFile.existsSync(), isTrue);
    final manifest = manifestFile.readAsStringSync();
    final strings = stringsFile.readAsStringSync();

    expect(manifest, contains('android:label="@string/app_name"'));
    expect(strings, contains('<string name="app_name">SafeMyanmar</string>'));
  });
}
