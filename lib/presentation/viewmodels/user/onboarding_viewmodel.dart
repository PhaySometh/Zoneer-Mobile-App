import 'package:flutter_riverpod/legacy.dart';
import 'package:zoneer_mobile/core/utils/app_prefs.dart';

class OnboardingViewModel extends StateNotifier<int> {
  OnboardingViewModel() : super(0);

  void onPageChanged(int index) {
    state = index;
  }

  bool get isLastPage => state == 2;

  void completeOnboarding() {
    AppPrefs.setOnboardingDone();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingViewModel, int>(
  (ref) => OnboardingViewModel(),
);
