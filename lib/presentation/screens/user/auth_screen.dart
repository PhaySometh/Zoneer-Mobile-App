import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoneer_mobile/core/services/auth_service.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/user/user_model.dart';
import 'package:zoneer_mobile/presentation/viewmodels/user/user_mutation_viewmodel.dart';
import 'package:zoneer_mobile/presentation/viewmodels/user/user_provider.dart';
import 'package:zoneer_mobile/shared/models/enums/verify_status.dart';
import 'package:zoneer_mobile/shared/widgets/google_nav_bar.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool toRegister;

  const AuthScreen({super.key, required this.toRegister});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool isRegister;

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  bool get _anyLoading => _isLoading || _isGoogleLoading;

  @override
  void initState() {
    super.initState();
    isRegister = widget.toRegister;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 4,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        elevation: 4,
      ),
    );
  }

  void _goHome() {
    ref.invalidate(userByIdProvider);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GoogleNavBar()),
    );
  }
Future<void> _googleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();

      // Android: signInWithOAuth opens browser and returns immediately.
      // Navigation is handled by the authStateProvider listener in build().
      // iOS/Web: auth completes synchronously — navigate now.
      if (!mounted) return;
      if (kIsWeb || !Platform.isAndroid) {
        ref.invalidate(userByIdProvider);
        _showSuccessSnackbar('Signed in with Google successfully!');
        _goHome();
      }
      // Android: keep loading overlay visible until browser returns
    } catch (e) {
      if (mounted) {
        final msg = kDebugMode
            ? 'Google sign-in failed: $e'
            : 'Google sign-in failed. Please try again.';
        _showErrorSnackbar(msg);
        setState(() => _isGoogleLoading = false);
      }
    } finally {
      // Android: don't reset loading here — authStateProvider listener does it
      if (mounted && (kIsWeb || !Platform.isAndroid)) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      if (isRegister) {
        final response = await authService.register(
          email: _emailController.text,
          password: _passwordController.text,
          fullname: _fullNameController.text,
        );

        if (response.user != null) {
          try {
            await ref
                .read(userMutationViewModelProvider.notifier)
                .create(
                  UserModel(
                    id: response.user!.id,
                    fullname: _fullNameController.text.trim(),
                    email: _emailController.text.trim(),
                    role: 'tenant',
                    verifyStatus: VerifyStatus.defaultStatus,
                  ),
                );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$e')));
            }
          }

          if (mounted) {
            _showSuccessSnackbar('Account created! Check your email to verify.');
            _goHome();
          }
        }
      } else {
        final response = await authService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (response.user != null) {
          if (mounted) {
            _showSuccessSnackbar('Welcome back! You\'re now signed in.');
            _goHome();
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showErrorSnackbar(e.message);
    } catch (e) {
      if (mounted) _showErrorSnackbar('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLoadingOverlay(String message) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.grey),
      filled: true,
      fillColor: AppColors.greyLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      floatingLabelStyle: const TextStyle(color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Android: when browser OAuth completes and app returns, navigate home
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      next.whenData((state) {
        if (state.event == AuthChangeEvent.signedIn && _isGoogleLoading) {
          if (mounted) {
            setState(() => _isGoogleLoading = false);
            ref.invalidate(userByIdProvider);
            _showSuccessSnackbar('Signed in with Google successfully!');
            _goHome();
          }
        }
      });
    });

    return Stack(
      children: [
        Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.secondary,
          ),
          tooltip: 'Back to Home',
          onPressed: _goHome,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Logo
              Center(
                child: Image.asset(
                  'assets/logo/Zonner Logo.png',
                  height: 50,
                  width: 50,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                isRegister ? 'Create Account' : 'Welcome Back',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                isRegister
                    ? 'Sign up to start finding your perfect space'
                    : 'Sign in to continue to Zoneer',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (isRegister) ...[
                      TextFormField(
                        controller: _fullNameController,
                        decoration: _inputDecoration(
                          'Full Name',
                          Icons.person_outline_rounded,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.isEmpty
                                ? 'Enter your full name'
                                : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration(
                        'Email',
                        Icons.email_outlined,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Enter your email'
                              : null,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration(
                        'Password',
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) => value == null || value.length < 8
                          ? 'Password must be at least 8 characters'
                          : null,
                    ),

                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _anyLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                                isRegister ? 'Create Account' : 'Sign In',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Back to home button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _anyLoading ? null : _goHome,
                        icon: const Icon(Icons.home_outlined, size: 18),
                        label: const Text('Continue Browsing'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(
                            color: AppColors.secondary,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text("OR"),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _anyLoading ? null : _googleLogin,
                        icon: Image.asset('assets/logo/google.png', height: 20),
                        label: const Text("Continue with Google"),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Toggle login / register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isRegister
                              ? 'Already have an account?'
                              : "Don't have an account?",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: _anyLoading
                              ? null
                              : () {
                                  setState(() {
                                    isRegister = !isRegister;
                                    _formKey.currentState?.reset();
                                  });
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: Text(
                            isRegister ? 'Sign In' : 'Register',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        ),
        if (_isLoading)
          _buildLoadingOverlay(
            isRegister ? 'Creating your account...' : 'Signing in...',
          ),
        if (_isGoogleLoading)
          _buildLoadingOverlay('Connecting to Google...'),
      ],
    );
  }
}