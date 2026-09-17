import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/onboarding_item.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.item});

  final OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;

            final illustrationSize = availableHeight < 500 ? 180.0 : 220.0;

            final titleFontSize = availableHeight < 500 ? 26.0 : 30.0;

            final descriptionFontSize = availableHeight < 500 ? 16.0 : 17.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: illustrationSize,
                      height: illustrationSize,
                      decoration: BoxDecoration(
                        color: item.backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: illustrationSize * 0.5,
                        color: AppColors.primary,
                      ),
                    ),

                    SizedBox(height: availableHeight < 500 ? 28 : 40),

                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: availableHeight < 500 ? 14 : 20),

                    Text(
                      item.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: descriptionFontSize,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
