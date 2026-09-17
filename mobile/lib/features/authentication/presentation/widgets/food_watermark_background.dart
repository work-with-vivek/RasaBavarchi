import 'package:flutter/material.dart';

class FoodWatermarkBackground extends StatelessWidget {
  final Widget child;

  const FoodWatermarkBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // =====================================================
        // FOOD WATERMARK BACKGROUND
        // =====================================================

        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.45,
              child: Image.asset(
                'assets/images/food_watermark_background.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),

        // =====================================================
        // LOGIN UI
        // =====================================================
        child,
      ],
    );
  }
}
