import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/presentation/screens/user/util/enum_onboarding.dart';
import 'package:zoneer_mobile/presentation/screens/user/widgets/on_boarding.dart';
import 'package:zoneer_mobile/shared/widgets/google_nav_bar.dart';
import '../../../core/utils/app_colors.dart';
import '../viewmodels/onboarding_viewmodel.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingProvider);
    final vm = ref.read(onboardingProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: TextButton(
              onPressed: () {
                vm.completeOnboarding();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const GoogleNavBar()),
                );
              },
              child: Text('Skip', style: TextStyle(color: AppColors.primary)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Spacer(flex: 1),

              Expanded(
                flex: 10,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: vm.onPageChanged,
                  children: [Onboarding(title: OnbordingData.onboarding1.title, subtitle: OnbordingData.onboarding1.subtitle, lottieAsset: OnbordingData.onboarding1.lottieAsset),
                  Onboarding(title: OnbordingData.onboarding2.title, subtitle: OnbordingData.onboarding2.subtitle, lottieAsset: OnbordingData.onboarding2.lottieAsset),
                  Onboarding(title: OnbordingData.onboarding3.title, subtitle: OnbordingData.onboarding3.subtitle, lottieAsset: OnbordingData.onboarding3.lottieAsset)],
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  bool isActive = currentPage == index;
                  return Container(
                    margin: EdgeInsets.all(2),
                    width: isActive ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              Spacer(flex: 2),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    if (vm.isLastPage) {
                      vm.completeOnboarding();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const GoogleNavBar()),
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    }
                  },
                  child: Text(
                    vm.isLastPage ? "Get Started" : "Next",
                    style: const TextStyle(color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
