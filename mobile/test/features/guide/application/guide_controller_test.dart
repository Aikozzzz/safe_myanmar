import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/guide/application/guide_state.dart';
import 'package:mobile/features/guide/application/providers.dart';

import '../../../support/fake_emergency_guide_repository.dart';

void main() {
  test('loads, filters, empties, and reports offline storage errors', () async {
    final repository = FakeEmergencyGuideRepository();
    final container = ProviderContainer(
      overrides: [
        emergencyGuideRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    container.read(guideControllerProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(guideControllerProvider).phase, GuidePhase.data);

    await container
        .read(guideControllerProvider.notifier)
        .selectCategory('first_aid');
    expect(
      container.read(guideControllerProvider).articles.single.category,
      'first_aid',
    );

    await container
        .read(guideControllerProvider.notifier)
        .search('not present');
    expect(container.read(guideControllerProvider).phase, GuidePhase.empty);

    repository.fail = true;
    await container.read(guideControllerProvider.notifier).retry();
    expect(container.read(guideControllerProvider).phase, GuidePhase.error);
  });
}
