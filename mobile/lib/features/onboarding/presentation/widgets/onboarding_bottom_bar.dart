import 'package:flutter/material.dart';

class OnboardingBottomBar extends StatelessWidget {
  const OnboardingBottomBar({
    super.key,
    required this.isLastPage,
    required this.onSkip,
    required this.onNext,
    required this.onGetStarted,
  });

  final bool isLastPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    if (isLastPage) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onGetStarted,
            child: const Text('Get Started'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          TextButton(onPressed: onSkip, child: const Text('Skip')),
          const Spacer(),
          ElevatedButton(onPressed: onNext, child: const Text('Next')),
        ],
      ),
    );
  }
}
