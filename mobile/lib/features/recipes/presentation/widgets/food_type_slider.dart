import 'package:flutter/material.dart';

class FoodTypeSlider extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const FoodTypeSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Food Type',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: _darkTeal,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 11),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildOption(
                value: null,
                label: 'All',
                icon: Icons.restaurant_menu_rounded,
              ),
              const SizedBox(width: 9),
              _buildOption(
                value: 'VEGETARIAN',
                label: 'Vegetarian',
                icon: Icons.eco_rounded,
              ),
              const SizedBox(width: 9),
              _buildOption(
                value: 'VEGAN',
                label: 'Vegan',
                icon: Icons.spa_rounded,
              ),
              const SizedBox(width: 9),
              _buildOption(
                value: 'NON_VEGETARIAN',
                label: 'Non-Veg',
                icon: Icons.restaurant_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required String? value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = this.value == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          onChanged(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _teal : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isSelected ? _teal : _border, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _teal.withValues(alpha: 0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 19,
                color: isSelected ? Colors.white : _darkTeal,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _secondaryText,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_rounded, size: 16, color: _yellow),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
