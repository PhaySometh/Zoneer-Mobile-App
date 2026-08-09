import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/presentation/screens/user/auth/auth_screen.dart';

/// Shown in the Profile tab when the user is not logged in.
class ProfileAuthState extends StatefulWidget {
  const ProfileAuthState({super.key});

  @override
  State<ProfileAuthState> createState() => _ProfileAuthStateState();
}

class _ProfileAuthStateState extends State<ProfileAuthState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.primary.withValues(alpha: 0.04),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Lottie.asset(
                          'assets/icons/system-solid-8-account-hover-pinch.json',
                          controller: _controller,
                          fit: BoxFit.contain,
                          onLoaded: (composition) {
                            _controller.duration = composition.duration * 2;
                            _controller.repeat();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'Your Account Awaits',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                Text(
                  'Sign in to manage your profile, applications, and messages.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Feature cards — all use brand color with varying opacity
                Row(
                  children: [
                    Expanded(
                      child: _ProfileFeatureCard(
                        icon: Icons.home_outlined,
                        label: 'Properties',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileFeatureCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Messages',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileFeatureCard(
                        icon: Icons.calendar_today_outlined,
                        label: 'Schedules',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(toRegister: false),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(toRegister: true),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileFeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileFeatureCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
