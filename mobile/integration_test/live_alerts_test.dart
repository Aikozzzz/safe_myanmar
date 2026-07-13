import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:mobile/main.dart' as app;

const _phase = String.fromEnvironment(
  'INTEGRATION_PHASE',
  defaultValue: 'online',
);
const _fixtureId = 'integration-fixture-001';
const _fixturePlace = 'Location: integration-fixture-001 near Mandalay';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real API and Drift preserve controlled earthquake information',
    (tester) async {
      if (_phase != 'online' && _phase != 'offline') {
        fail('INTEGRATION_PHASE must be online or offline.');
      }

      if (_phase == 'online') {
        await _deleteDatabaseFiles();
      }

      app.main();

      await _pumpUntil(tester, find.text(_fixturePlace));
      expect(find.textContaining(_fixtureId), findsOneWidget);
      expect(find.text('Source: USGS'), findsWidgets);

      if (_phase == 'online') {
        expect(find.text('Live information'), findsWidgets);
        expect(find.textContaining('Last successful update:'), findsOneWidget);

        await tester.tap(find.text(_fixturePlace));
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );

        expect(find.text('Magnitude 4.6'), findsOneWidget);
        expect(find.text('Depth: 10.5 km'), findsOneWidget);
        expect(find.textContaining('Event time:'), findsOneWidget);
        expect(find.textContaining('Provider update:'), findsOneWidget);
        expect(find.textContaining('Retrieved:'), findsOneWidget);
        expect(find.text('Review status: reviewed'), findsOneWidget);
        expect(find.text('Source: USGS'), findsOneWidget);
        expect(
          find.text('Preliminary earthquake values may change.'),
          findsOneWidget,
        );
        return;
      }

      await _pumpUntil(
        tester,
        find.text('Could not update live information.'),
        timeout: const Duration(seconds: 20),
      );
      expect(find.text('Stale information'), findsWidgets);
      expect(
        find.text('Previously saved information remains available below.'),
        findsOneWidget,
      );
      expect(find.text(_fixturePlace), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await _deleteDatabaseFiles();
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for the expected integration UI state.');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _deleteDatabaseFiles() async {
  final directory = await getApplicationSupportDirectory();
  final databasePath = path.join(directory.path, 'safe_myanmar.sqlite');
  for (final suffix in const ['', '-wal', '-shm']) {
    final file = File('$databasePath$suffix');
    if (await file.exists()) await file.delete();
  }
}
