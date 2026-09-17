import 'package:flutter/material.dart';

class FoodWatermarkBackground extends StatelessWidget {
  final Widget child;

  const FoodWatermarkBackground({super.key, required this.child});

  static const String _assetPath =
      'assets/images/food_watermark_background.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFFDF8ED)),

        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.055,
              child: Image.asset(
                _assetPath,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return const SizedBox.shrink();
                    },
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}
