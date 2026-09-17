import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error_handler.dart';
import '../../data/models/otp_request.dart';
import '../providers/auth_providers.dart';
import '../widgets/food_watermark_background.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _otpFocusNode = FocusNode();

  int _step = 0;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _otpFocusNode.dispose();
    _resendTimer?.cancel();

    super.dispose();
  }

  // =========================================================
  // SEND VERIFICATION CODE
  // =========================================================

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }

    if (!email.contains('@')) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dataSource = ref.read(authRemoteDataSourceProvider);

      await dataSource.forgotPassword(email);

      if (!mounted) {
        return;
      }

      setState(() {
        _step = 1;
        _isLoading = false;
      });

      _startResendTimer();

      _showMessage('Verification code sent to your email.', isError: false);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(ApiErrorHandler.getMessage(error));
    }
  }

  // =========================================================
  // CONTINUE WITH OTP
  // =========================================================

  void _continueWithOtp() {
    final otp = _otpController.text.trim();

    if (otp.length != 6 || int.tryParse(otp) == null) {
      _showMessage('Please enter the 6-digit verification code.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _step = 2;
    });
  }

  // =========================================================
  // RESET PASSWORD
  // =========================================================

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final otp = _otpController.text.trim();
    final email = _emailController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Please enter and confirm your new password.');
      return;
    }

    if (password.length < 8) {
      _showMessage('Password must be at least 8 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    if (otp.length != 6) {
      _showMessage('Please enter the verification code.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final dataSource = ref.read(authRemoteDataSourceProvider);

      await dataSource.resetPassword(
        OtpRequest(email: email, otp: otp),
        password,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _step = 3;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(ApiErrorHandler.getMessage(error));
    }
  }

  // =========================================================
  // RESEND TIMER
  // =========================================================

  void _startResendTimer() {
    _resendTimer?.cancel();

    setState(() {
      _resendSeconds = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSeconds <= 1) {
        timer.cancel();

        setState(() {
          _resendSeconds = 0;
        });
      } else {
        setState(() {
          _resendSeconds--;
        });
      }
    });
  }

  // =========================================================
  // RESEND CODE
  // =========================================================

  Future<void> _resendCode() async {
    if (_resendSeconds > 0 || _isLoading) {
      return;
    }

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dataSource = ref.read(authRemoteDataSourceProvider);

      await dataSource.forgotPassword(email);

      if (!mounted) {
        return;
      }

      _startResendTimer();

      setState(() {
        _isLoading = false;
      });

      _showMessage('A new verification code has been sent.', isError: false);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(ApiErrorHandler.getMessage(error));
    }
  }

  // =========================================================
  // BACK
  // =========================================================

  void _goBack() {
    if (_step == 0 || _step == 3) {
      context.pop();
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _step--;
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8ED),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FoodWatermarkBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Column(
                        key: ValueKey(_step),
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
                                onPressed: _isLoading ? null : _goBack,
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 29,
                                  color: Color(0xFF242424),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          _buildCurrentStep(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CURRENT STEP
  // =========================================================

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildOtpStep();

      case 2:
        return _buildNewPasswordStep();

      case 3:
        return _buildSuccessStep();

      default:
        return _buildEmailStep();
    }
  }

  // =========================================================
  // STEP 1 — EMAIL
  // =========================================================

  Widget _buildEmailStep() {
    return Column(
      children: [
        const SizedBox(height: 4),

        // Logo
        _buildLogo(),

        const SizedBox(height: 18),

        // Title
        const Text(
          'Reset Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF00695C),
            fontSize: 31,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),

        const SizedBox(height: 8),

        // Description
        const Text(
          "Enter your email address and we'll send\nyou a verification code.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8A837B),
            fontSize: 15.5,
            height: 1.45,
          ),
        ),

        const SizedBox(height: 30),

        // Email
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: 24),

        // Button
        _buildPrimaryButton(
          text: 'Send Verification Code',
          onPressed: _sendVerificationCode,
          isLoading: _isLoading,
        ),

        const SizedBox(height: 25),

        // Back
        _buildBackToLogin(),

        const SizedBox(height: 20),
      ],
    );
  }

  // =========================================================
  // STEP 2 — OTP
  // =========================================================

  Widget _buildOtpStep() {
    return Column(
      children: [
        const SizedBox(height: 4),

        _buildLogo(),

        const SizedBox(height: 18),

        const Text(
          'Verify Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF00695C),
            fontSize: 31,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'We sent a 6-digit verification code to\n'
          '${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8A837B),
            fontSize: 15.5,
            height: 1.45,
          ),
        ),

        const SizedBox(height: 30),

        // OTP boxes
        _buildOtpInput(),

        const SizedBox(height: 24),

        _buildPrimaryButton(text: 'Continue', onPressed: _continueWithOtp),

        const SizedBox(height: 18),

        if (_resendSeconds > 0)
          Text(
            'Resend code in $_resendSeconds s',
            style: const TextStyle(color: Color(0xFF8A837B), fontSize: 14),
          )
        else
          TextButton(
            onPressed: _isLoading ? null : _resendCode,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00695C),
            ),
            child: const Text(
              'Resend Verification Code',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
          ),

        const SizedBox(height: 4),

        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  _otpController.clear();

                  setState(() {
                    _step = 0;
                  });
                },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF00695C)),
          child: const Text(
            'Change Email',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // =========================================================
  // OTP INPUT
  // =========================================================

  Widget _buildOtpInput() {
    final otp = _otpController.text;

    return GestureDetector(
      onTap: () {
        _otpFocusNode.requestFocus();
      },
      child: Stack(
        children: [
          Row(
            children: List.generate(6, (index) {
              final hasValue = index < otp.length;
              final isActive = index == otp.length && _otpFocusNode.hasFocus;

              return Expanded(
                child: Container(
                  height: 58,
                  margin: EdgeInsets.only(right: index == 5 ? 0 : 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF00695C)
                          : hasValue
                          ? const Color(0xFF00695C)
                          : const Color(0xFFE1DED5),
                      width: isActive || hasValue ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    hasValue ? otp[index] : '',
                    style: const TextStyle(
                      color: Color(0xFF242424),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),

          // Invisible keyboard input
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STEP 3 — NEW PASSWORD
  // =========================================================

  Widget _buildNewPasswordStep() {
    return Column(
      children: [
        const SizedBox(height: 4),

        _buildLogo(),

        const SizedBox(height: 18),

        const Text(
          'Create New Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF00695C),
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Create a new password for your\n'
          'RasaBavarchi account.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8A837B),
            fontSize: 15.5,
            height: 1.45,
          ),
        ),

        const SizedBox(height: 30),

        _buildPasswordField(
          controller: _passwordController,
          label: 'New Password',
          obscureText: _obscurePassword,
          onToggle: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),

        const SizedBox(height: 16),

        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          obscureText: _obscureConfirmPassword,
          onToggle: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),

        const SizedBox(height: 11),

        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Password must be at least 8 characters',
              style: TextStyle(color: Color(0xFF8A837B), fontSize: 12.5),
            ),
          ),
        ),

        const SizedBox(height: 24),

        _buildPrimaryButton(
          text: 'Reset Password',
          onPressed: _resetPassword,
          isLoading: _isLoading,
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // =========================================================
  // STEP 4 — SUCCESS
  // =========================================================

  Widget _buildSuccessStep() {
    return Column(
      children: [
        const SizedBox(height: 4),

        _buildLogo(),

        const SizedBox(height: 22),

        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F3EE),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00695C), width: 2),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF00695C),
            size: 48,
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Password Reset!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF00695C),
            fontSize: 31,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Your password has been changed successfully.\n'
          'You can now log in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8A837B),
            fontSize: 15.5,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 34),

        _buildPrimaryButton(
          text: 'Back to Login',
          onPressed: () {
            context.pop();
          },
        ),

        const SizedBox(height: 20),
      ],
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
  // TEXT FIELD
  // =========================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00695C)),
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.94),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE1DED5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF00695C), width: 2),
        ),
      ),
    );
  }

  // =========================================================
  // PASSWORD FIELD
  // =========================================================

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF00695C),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF00695C),
          ),
        ),
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.94),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE1DED5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF00695C), width: 2),
        ),
      ),
    );
  }

  // =========================================================
  // PRIMARY BUTTON
  // =========================================================

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: const Color(0xFF173F38),
          disabledBackgroundColor: const Color(0xFFE4D9B7),
          disabledForegroundColor: const Color(0xFF77716D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF173F38),
                ),
              )
            : Text(text),
      ),
    );
  }

  // =========================================================
  // BACK TO LOGIN
  // =========================================================

  Widget _buildBackToLogin() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () {
              context.pop();
            },
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF00695C)),
      child: const Text(
        'Back to Login',
        style: TextStyle(
          color: Color(0xFF00695C),
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
