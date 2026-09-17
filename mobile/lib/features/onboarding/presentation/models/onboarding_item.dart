import 'package:flutter/material.dart';

class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
}

const onboardingItems = [
  OnboardingItem(
    title: 'Discover AI Recipes',
    description:
        'Create delicious recipes instantly using the ingredients already available in your kitchen.',
    icon: Icons.restaurant_menu_rounded,
    backgroundColor: Color(0xFFE8F5E9),
  ),
  OnboardingItem(
    title: 'Plan Healthy Meals',
    description:
        'Build personalized weekly meal plans based on your health goals and lifestyle.',
    icon: Icons.calendar_month_rounded,
    backgroundColor: Color(0xFFFFF3E0),
  ),
  OnboardingItem(
    title: 'Scan Your Fridge',
    description:
        'Use AI to recognize ingredients from your fridge and automatically update your pantry.',
    icon: Icons.camera_alt_rounded,
    backgroundColor: Color(0xFFE3F2FD),
  ),
];
