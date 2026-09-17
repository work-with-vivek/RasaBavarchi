import 'package:flutter/material.dart';
import 'package:mobile/features/pantry/presentation/screens/pantry_comparison_screen.dart';
import 'package:mobile/features/recipes/data/models/recipe_model.dart';

import '../../../../core/widgets/food_watermark_background.dart';

class ScaledIngredientsScreen extends StatelessWidget {
  const ScaledIngredientsScreen({
    super.key,
    required this.recipe,
    required this.selectedServings,
  });

  final RecipeModel recipe;
  final int selectedServings;

  // ============================================================
  // RASABAVARCHI THEME
  // ============================================================

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _brown = Color(0xFF9C513A);
  static const Color _lightTeal = Color(0xFFE8F3F1);
  static const Color _lightBrown = Color(0xFFFFD8CC);
  static const Color _text = Color(0xFF252525);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  // ============================================================
  // SCALE QUANTITY
  // ============================================================

  double _scaledQuantity(double originalQuantity) {
    if (recipe.servings <= 0) {
      return originalQuantity;
    }

    final scaleFactor = selectedServings / recipe.servings;

    return originalQuantity * scaleFactor;
  }

  // ============================================================
  // FORMAT QUANTITY
  // ============================================================

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    final oneDecimal = quantity.toStringAsFixed(1);

    if (oneDecimal.endsWith('.0')) {
      return quantity.toInt().toString();
    }

    return oneDecimal;
  }

  // ============================================================
  // SERVING LABEL
  // ============================================================

  String get _servingLabel {
    return selectedServings == 1 ? 'person' : 'people';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back, size: 28, color: _teal),
        ),

        title: const Text(
          'Recipe Ingredients',
          style: TextStyle(
            color: _text,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: FoodWatermarkBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              // ==================================================
              // RECIPE TITLE
              // ==================================================

              Text(
                recipe.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _darkTeal,
                  fontSize: 27,
                  height: 1.12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 7),

              // ==================================================
              // ADJUSTED TEXT
              // ==================================================
              Text(
                'Adjusted for $selectedServings $_servingLabel',
                style: const TextStyle(
                  color: _secondaryText,
                  fontSize: 17,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 23),

              // ==================================================
              // COOKING FOR CARD
              // ==================================================
              _CookingForCard(
                selectedServings: selectedServings,
                servingLabel: _servingLabel,
              ),

              const SizedBox(height: 30),

              // ==================================================
              // INGREDIENT TITLE
              // ==================================================
              const Text(
                'Required Ingredients',
                style: TextStyle(
                  color: _darkTeal,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 13),

              // ==================================================
              // INGREDIENT LIST
              // ==================================================
              if (recipe.ingredients.isEmpty)
                const _EmptyIngredientsCard()
              else
                ...recipe.ingredients.map((ingredient) {
                  final scaledQuantity = _scaledQuantity(ingredient.quantity);

                  return _IngredientCard(
                    name: ingredient.name,
                    quantity: scaledQuantity,
                    unit: ingredient.unit,
                    isOptional: ingredient.isOptional,
                    formatQuantity: _formatQuantity,
                  );
                }),

              const SizedBox(height: 19),

              // ==================================================
              // INFORMATION CARD
              // ==================================================
              _InformationCard(
                selectedServings: selectedServings,
                servingLabel: _servingLabel,
              ),

              const SizedBox(height: 27),

              // ==================================================
              // CHECK PANTRY BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: recipe.ingredients.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PantryComparisonScreen(
                                recipe: recipe,
                                selectedServings: selectedServings,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.inventory_2_outlined, size: 22),
                  label: const Text(
                    'Check My Pantry',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// COOKING FOR CARD
// ============================================================================

class _CookingForCard extends StatelessWidget {
  const _CookingForCard({
    required this.selectedServings,
    required this.servingLabel,
  });

  final int selectedServings;
  final String servingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: ScaledIngredientsScreen._lightBrown,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFFFCFC2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_alt_outlined,
              color: ScaledIngredientsScreen._brown,
              size: 27,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cooking for',
                  style: TextStyle(
                    color: ScaledIngredientsScreen._brown,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '$selectedServings $servingLabel',
                  style: const TextStyle(
                    color: ScaledIngredientsScreen._text,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INGREDIENT CARD
// ============================================================================

class _IngredientCard extends StatelessWidget {
  const _IngredientCard({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isOptional,
    required this.formatQuantity,
  });

  final String name;
  final double quantity;
  final String unit;
  final bool isOptional;
  final String Function(double) formatQuantity;

  @override
  Widget build(BuildContext context) {
    final hasUnit = unit.trim().isNotEmpty;
    final hasQuantity = quantity > 0;

    final quantityText = hasUnit && hasQuantity
        ? '${formatQuantity(quantity)} $unit'
        : 'Quantity not specified';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ScaledIngredientsScreen._border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ========================================================
          // INGREDIENT ICON
          // ========================================================

          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: ScaledIngredientsScreen._lightTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: ScaledIngredientsScreen._teal,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          // ========================================================
          // INGREDIENT NAME
          // ========================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ScaledIngredientsScreen._darkTeal,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (isOptional) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Optional',
                    style: TextStyle(
                      color: ScaledIngredientsScreen._secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ========================================================
          // QUANTITY
          // ========================================================
          SizedBox(
            width: 120,
            child: Text(
              quantityText,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnit && hasQuantity
                    ? ScaledIngredientsScreen._text
                    : ScaledIngredientsScreen._secondaryText,
                fontSize: 15,
                height: 1.25,
                fontWeight: hasUnit && hasQuantity
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY INGREDIENTS CARD
// ============================================================================

class _EmptyIngredientsCard extends StatelessWidget {
  const _EmptyIngredientsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ScaledIngredientsScreen._border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 38,
            color: ScaledIngredientsScreen._secondaryText,
          ),
          SizedBox(height: 10),
          Text(
            'No ingredients available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ScaledIngredientsScreen._secondaryText,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INFORMATION CARD
// ============================================================================

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.selectedServings,
    required this.servingLabel,
  });

  final int selectedServings;
  final String servingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ScaledIngredientsScreen._border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: ScaledIngredientsScreen._secondaryText,
            size: 25,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Ingredient quantities have been adjusted from the '
              'original recipe for $selectedServings $servingLabel. '
              'Some ingredients may not have a specified measurement '
              'in the original recipe.',
              style: const TextStyle(
                color: ScaledIngredientsScreen._secondaryText,
                fontSize: 15,
                height: 1.38,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
