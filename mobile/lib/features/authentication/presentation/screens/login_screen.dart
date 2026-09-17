import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error_handler.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/food_watermark_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> _login() async {
    if (ref.read(authNotifierProvider).isLoading) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email.')));
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password.')),
      );
      return;
    }

    await ref
        .read(authNotifierProvider.notifier)
        .login(email: email, password: password);

    if (!mounted) {
      return;
    }

    final authState = ref.read(authNotifierProvider);

    authState.whenOrNull(
      data: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login Successful')));

        context.go('/home');
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorHandler.getMessage(error))),
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: const Color(0xFF00695C),
          secondary: const Color(0xFFFFC107),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.94),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          prefixIconColor: const Color(0xFF00695C),
          labelStyle: const TextStyle(color: Color(0xFF77736A)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE1DED5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF00695C), width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: const Color(0xFF173F38),
            disabledBackgroundColor: const Color(0xFFD8D3C7),
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF8ED),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: FoodWatermarkBackground(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                      child: Column(
                        children: [
                          // ===================================
                          // LOGO
                          // ===================================

                          _buildLogo(),

                          const SizedBox(height: 12),

                          // ===================================
                          // TITLE
                          // ===================================
                          const Text(
                            'Welcome Back!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF064E46),
                              letterSpacing: -0.6,
                            ),
                          ),

                          const SizedBox(height: 5),

                          // ===================================
                          // TAGLINE
                          // ===================================
                          const Text(
                            'Cook • Eat • Live Healthy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF77736A),
                              letterSpacing: 0.4,
                            ),
                          ),

                          const SizedBox(height: 27),

                          // ===================================
                          // EMAIL
                          // ===================================
                          AuthTextField(
                            controller: emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 15),

                          // ===================================
                          // PASSWORD
                          // ===================================
                          AuthTextField(
                            controller: passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: true,
                          ),

                          // ===================================
                          // FORGOT PASSWORD
                          // ===================================
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () {
                                      context.push('/forgot-password');
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF00695C),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 3),

                          // ===================================
                          // LOGIN BUTTON
                          // ===================================
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: AuthButton(
                              text: 'Login',
                              isLoading: authState.isLoading,
                              onPressed: _login,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ===================================
                          // SIGN UP
                          // ===================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  color: Color(0xFF77736A),
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () {
                                        context.push('/register');
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF00695C),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                ),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LOGO
  // =========================================================

  Widget _buildLogo() {
    return SizedBox(
      width: 145,
      height: 145,
      child: Image.asset(
        'assets/images/rasabavarchi_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.restaurant, size: 50, color: Color(0xFF00695C)),
          );
        },
      ),
    );
  }
}
