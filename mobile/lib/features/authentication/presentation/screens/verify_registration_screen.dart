import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error_handler.dart';
import '../../data/models/otp_request.dart';
import '../providers/auth_providers.dart';

class VerifyRegistrationScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyRegistrationScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyRegistrationScreen> createState() =>
      _VerifyRegistrationScreenState();
}

class _VerifyRegistrationScreenState
    extends ConsumerState<VerifyRegistrationScreen> {
  final otpController = TextEditingController();

  bool isLoading = false;
  bool isResending = false;

  Timer? _resendTimer;
  int _resendSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit verification code.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final remoteDataSource = ref.read(authRemoteDataSourceProvider);

      await remoteDataSource.verifyRegistrationOtp(
        OtpRequest(email: widget.email, otp: otp),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified successfully.')),
      );

      context.go('/login');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiErrorHandler.getMessage(e))));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (isResending || _resendSecondsRemaining > 0) {
      return;
    }

    setState(() {
      isResending = true;
    });

    try {
      final remoteDataSource = ref.read(authRemoteDataSourceProvider);

      await remoteDataSource.resendRegistrationOtp(widget.email);

      if (!mounted) return;

      otpController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If the account is eligible, a new verification code has been sent.',
          ),
        ),
      );

      _startResendCooldown();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiErrorHandler.getMessage(e))));
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();

    setState(() {
      _resendSecondsRemaining = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSecondsRemaining <= 1) {
        timer.cancel();

        setState(() {
          _resendSecondsRemaining = 0;
        });
      } else {
        setState(() {
          _resendSecondsRemaining--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool resendDisabled =
        isResending || _resendSecondsRemaining > 0 || isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              const Icon(Icons.mark_email_read_outlined, size: 80),

              const SizedBox(height: 24),

              const Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              Text(
                'We sent a 6-digit verification code to\n${widget.email}',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _verifyOtp,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify Email'),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: resendDisabled ? null : _resendOtp,
                child: isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _resendSecondsRemaining > 0
                    ? Text('Resend code in $_resendSecondsRemaining s')
                    : const Text('Resend Code'),
              ),

              const SizedBox(height: 8),

              const Text(
                'The verification code expires after 10 minutes.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
