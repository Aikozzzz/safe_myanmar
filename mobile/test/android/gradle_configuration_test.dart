import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kotlin compilation is stable for Windows cross-drive builds', () {
    final lines = File('android/gradle.properties').readAsLinesSync();

    expect(lines.where((line) => line.startsWith('kotlin.incremental=')), [
      'kotlin.incremental=false',
    ]);
    expect(
      lines.where(
        (line) => line.startsWith('kotlin.compiler.execution.strategy='),
      ),
      ['kotlin.compiler.execution.strategy=in-process'],
    );
    expect(
      lines,
      contains(
        '# Keep Kotlin caches reliable when Windows dependencies and the '
        'project are on different drives.',
      ),
    );
  });
}
