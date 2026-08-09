import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zoneer_mobile/presentation/screens/user/onboarding_screen.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/core/utils/app_prefs.dart';
import 'package:zoneer_mobile/features/user/widgets/circle_transition.dart';
import 'package:zoneer_mobile/shared/widgets/google_nav_bar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _primaryScale;
  late Animation<double> _whiteScale;

  bool startTransition = false;

  Future<void> _handleNavigation() async {
    final onboardingDone = await AppPrefs.isOnboardingDone();

    if (!onboardingDone) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GoogleNavBar()),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _primaryScale = Tween<double>(begin: 0, end: 2.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    /// WHITE CIRCLE (SECOND)
    _whiteScale = Tween<double>(begin: 0, end: 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleNavigation();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          /// LOTTIE
          Center(
            child: Lottie.asset(
              'assets/logo/Zoneer-logo.json',
              width: 300,
              repeat: false,
              onLoaded: (composition) {
                Future.delayed(composition.duration, () {
                  setState(() => startTransition = true);
                  _controller.forward();
                });
              },
            ),
          ),

          if (startTransition)
            AnimatedBuilder(
              animation: _primaryScale,
              builder: (_, __) {
                return Transform.scale(
                  scale: _primaryScale.value,
                  child: circle(size, AppColors.primary),
                );
              },
            ),

          if (startTransition)
            AnimatedBuilder(
              animation: _whiteScale,
              builder: (_, __) {
                return Transform.scale(
                  scale: _whiteScale.value,
                  child: circle(size, AppColors.white),
                );
              },
            ),
        ],
      ),
    );
  }
}
