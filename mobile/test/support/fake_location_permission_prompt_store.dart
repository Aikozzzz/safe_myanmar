import 'package:mobile/features/location/data/location_permission_prompt_store.dart';

final class FakeLocationPermissionPromptStore
    implements LocationPermissionPromptStore {
  bool shown = false;
  bool optedIn = false;
  int markCalls = 0;
  int markOptInCalls = 0;

  @override
  Future<bool> hasShownExplanation() async => shown;

  @override
  Future<void> markExplanationShown() async {
    shown = true;
    markCalls++;
  }

  @override
  Future<bool> hasOptedIn() async => optedIn;

  @override
  Future<void> markOptedIn() async {
    optedIn = true;
    markOptInCalls++;
  }
}
