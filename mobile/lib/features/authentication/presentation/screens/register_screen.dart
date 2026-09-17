import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error_handler.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/food_watermark_background.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // REGISTER
  // =========================================================

  Future<void> _register() async {
    if (ref.read(authNotifierProvider).isLoading) {
      return;
    }

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty) {
      _showMessage('Please enter your username.');
      return;
    }

    if (email.isEmpty) {
      _showMessage('Please enter your email.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please enter your password.');
      return;
    }

    await ref
        .read(authNotifierProvider.notifier)
        .register(email: email, username: username, password: password);

    if (!mounted) {
      return;
    }

    final authState = ref.read(authNotifierProvider);

    authState.whenOrNull(
      data: (_) {
        _showMessage(
          'Account created. Please verify your email.',
          isError: false,
        );

        context.push('/register/verify', extra: email);
      },
      error: (error, _) {
        _showMessage(ApiErrorHandler.getMessage(error));
      },
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFB04A3A)
              : const Color(0xFF00695C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
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
            horizontal: 18,
            vertical: 17,
          ),
          prefixIconColor: const Color(0xFF00695C),
          labelStyle: const TextStyle(color: Color(0xFF77736A)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE1DED5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
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
              borderRadius: BorderRadius.circular(18),
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
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      child: Column(
                        children: [
                          // =================================================
                          // BACK BUTTON
                          // =================================================

                          SizedBox(
                            height: 44,
                            width: double.infinity,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () {
                                        context.pop();
                                      },
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 29,
                                  color: Color(0xFF064E46),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // =================================================
                          // LOGO
                          // =================================================
                          _buildLogo(),

                          const SizedBox(height: 18),

                          // =================================================
                          // TITLE
                          // =================================================
                          const Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 31,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00695C),
                              letterSpacing: -0.7,
                            ),
                          ),

                          const SizedBox(height: 7),

                          // =================================================
                          // SUBTITLE
                          // =================================================
                          const Text(
                            'Cook • Eat • Live Healthy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8A837B),
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // =================================================
                          // USERNAME
                          // =================================================
                          AuthTextField(
                            controller: usernameController,
                            label: 'Username',
                            icon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                          ),

                          const SizedBox(height: 16),

                          // =================================================
                          // EMAIL
                          // =================================================
                          AuthTextField(
                            controller: emailController,
                            label: 'Email',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 16),

                          // =================================================
                          // PASSWORD
                          // =================================================
                          _buildPasswordField(),

                          const SizedBox(height: 12),

                          // =================================================
                          // PASSWORD HINT
                          // =================================================
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                'Password must be at least 8 characters',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF8A837B),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // =================================================
                          // REGISTER BUTTON
                          // =================================================
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: AuthButton(
                              text: 'Create Account',
                              isLoading: authState.isLoading,
                              onPressed: _register,
                            ),
                          ),

                          const SizedBox(height: 25),

                          // =================================================
                          // LOGIN LINK
                          // =================================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: Color(0xFF8A837B),
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () {
                                        context.pop();
                                      },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: const Color(0xFF00695C),
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
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
            child: Icon(
              Icons.restaurant_rounded,
              size: 52,
              color: Color(0xFF00695C),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // PASSWORD FIELD
  // =========================================================

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) {
        if (!ref.read(authNotifierProvider).isLoading) {
          _register();
        }
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF00695C),
          ),
        ),
        labelText: 'Password',
      ),
    );
  }
}
