import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/router.dart';
import 'package:mobile/features/profile/application/providers.dart';
import 'package:mobile/features/profile/domain/local_profile.dart';
import 'package:mobile/features/profile/domain/local_profile_repository.dart';

import '../../../support/fake_local_profile_repository.dart';

void main() {
  late FakeLocalProfileRepository repository;
  var nextId = 0;

  setUp(() {
    repository = FakeLocalProfileRepository();
    nextId = 0;
  });

  Future<void> pumpRoute(
    WidgetTester tester,
    String location, {
    double textScale = 1,
  }) async {
    final router = createRouter(initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localProfileRepositoryProvider.overrideWithValue(repository),
          contactIdFactoryProvider.overrideWithValue(
            () => 'contact-${++nextId}',
          ),
        ],
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: SafeMyanmarApp(router: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('More shows a Figma-aligned local profile overview', (
    tester,
  ) async {
    await pumpRoute(tester, '/more');

    expect(find.text('Your local profile'), findsOneWidget);
    expect(find.text('Display name not set'), findsNWidgets(2));
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Manage contacts'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Private by default'), 100);
    expect(find.text('Private by default'), findsOneWidget);
    expect(
      find.textContaining('does not read your device contacts'),
      findsOneWidget,
    );
  });

  testWidgets('profile display name can be edited and remains local', (
    tester,
  ) async {
    await pumpRoute(tester, '/more');

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.text('Edit profile'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Test User');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.profile.displayName, 'Test User');
    expect(find.text('Test User'), findsWidgets);
  });

  testWidgets('contact add, selection, edit, and confirmed delete flow', (
    tester,
  ) async {
    await pumpRoute(tester, '/more/contacts');

    expect(find.text('No emergency contacts yet'), findsOneWidget);
    await tester.tap(find.text('Add contact'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Test Contact');
    await tester.enterText(fields.at(1), '+1 (202) 555-0123');
    await tester.enterText(fields.at(2), 'Family');
    await tester.fling(
      find.byType(ListView).last,
      const Offset(0, -1000),
      1000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('+12025550123'), findsOneWidget);
    expect(repository.profile.contacts.single.selectedForSos, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repository.profile.contacts.single.selectedForSos, isFalse);

    await tester.tap(find.text('Edit contact'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Updated Contact');
    await tester.fling(
      find.byType(ListView).last,
      const Offset(0, -1000),
      1000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Updated Contact'), findsOneWidget);
    expect(repository.profile.contacts.single.id, 'contact-1');

    await tester.tap(find.text('Delete contact'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Updated Contact?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.profile.contacts, hasLength(1));

    await tester.tap(find.text('Delete contact'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repository.profile.contacts, isEmpty);
    expect(find.text('No emergency contacts yet'), findsOneWidget);
  });

  testWidgets('phone errors are localized', (tester) async {
    await pumpRoute(tester, '/more/contacts/new');

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Test Contact');
    await tester.enterText(fields.at(1), '12/letters');
    await tester.enterText(fields.at(2), 'Friend');
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(
      find.text(
        'Use digits with an optional leading +. Spaces, hyphens, periods, '
        'and parentheses are allowed.',
      ),
      findsOneWidget,
    );
    expect(repository.writes, 0);
  });

  testWidgets('ten-contact limit disables add and explains the limit', (
    tester,
  ) async {
    repository.profile = LocalProfile(
      displayName: '',
      contacts: List.generate(
        maxEmergencyContacts,
        (index) => EmergencyContact(
          id: 'contact-$index',
          name: 'Test Contact $index',
          phoneNumber: '1234567',
          label: 'Friend',
          selectedForSos: false,
        ),
      ),
    );
    await pumpRoute(tester, '/more/contacts');

    expect(
      find.text('You can save up to 10 emergency contacts.'),
      findsOneWidget,
    );
    final addButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Add contact'),
    );
    expect(addButton.onPressed, isNull);
  });

  testWidgets(
    'safe read error can retry and corrupt data needs reset consent',
    (tester) async {
      repository.readError = const LocalProfileReadException(
        LocalProfileReadFailureKind.corrupt,
      );
      await pumpRoute(tester, '/more');

      expect(find.text('Stored profile cannot be opened'), findsOneWidget);
      expect(find.text('Reset local profile'), findsOneWidget);
      expect(find.textContaining('Sensitive'), findsNothing);

      await tester.tap(find.text('Reset local profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.clears, 0);

      repository.readError = null;
      await tester.tap(find.text('Reset local profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
      await tester.pumpAndSettle();
      expect(repository.clears, 1);
      expect(find.text('Display name not set'), findsNWidgets(2));
    },
  );

  testWidgets('write failure shows recoverable state and saved value', (
    tester,
  ) async {
    repository.profile = LocalProfile(displayName: 'Saved', contacts: const []);
    repository.writeError = const LocalProfileWriteException();
    await pumpRoute(tester, '/more/profile');

    await tester.enterText(find.byType(TextFormField), 'Pending');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Changes were not saved'), findsOneWidget);
    expect(repository.profile.displayName, 'Saved');
    repository.writeError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(repository.profile.displayName, 'Pending');
  });

  testWidgets('profile and contact actions remain usable at 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    repository.profile = LocalProfile(
      displayName: 'Test User',
      contacts: const [
        EmergencyContact(
          id: 'contact-1',
          name: 'Test Contact',
          phoneNumber: '1234567',
          label: 'Family',
          selectedForSos: true,
        ),
      ],
    );
    await pumpRoute(tester, '/more/contacts', textScale: 2);

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Delete contact'), 150);
    expect(tester.takeException(), isNull);
    for (final finder in [
      find.widgetWithText(FilledButton, 'Add contact'),
      find.byType(SwitchListTile),
      find.widgetWithText(OutlinedButton, 'Edit contact'),
      find.widgetWithText(OutlinedButton, 'Delete contact'),
    ]) {
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });
}
