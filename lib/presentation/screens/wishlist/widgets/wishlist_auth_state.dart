import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/presentation/screens/user/auth/auth_screen.dart';

/// Shown in the Wishlist tab when the user is not logged in.
/// Visually distinct from the profile auth state — uses bookmark/save theme.
class WishlistAuthState extends StatefulWidget {
  const WishlistAuthState({super.key});

  @override
  State<WishlistAuthState> createState() => _WishlistAuthStateState();
}

class _WishlistAuthStateState extends State<WishlistAuthState>
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
                          'assets/icons/system-solid-20-bookmark-hover-bookmark-1.json',
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
                  'Save Your Favorites',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                Text(
                  'Sign in to bookmark properties and access them anywhere.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Feature hints row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FeatureHint(
                      icon: Icons.bookmark_added_outlined,
                      label: 'Save listings',
                    ),
                    const SizedBox(width: 20),
                    _FeatureHint(
                      icon: Icons.notifications_none_rounded,
                      label: 'Get alerts',
                    ),
                    const SizedBox(width: 20),
                    _FeatureHint(
                      icon: Icons.history_rounded,
                      label: 'View history',
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Buttons
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
                    child: Text(
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

class _FeatureHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
