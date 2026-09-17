import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/pantry/data/models/pantry_comparison_model.dart';
import 'package:mobile/features/pantry/data/models/pantry_item_model.dart';
import 'package:mobile/features/pantry/presentation/providers/pantry_provider.dart';
import 'package:mobile/features/recipes/data/models/recipe_model.dart';
import 'package:mobile/features/shopping/presentation/screens/product_matching_screen.dart';

import '../../../../core/widgets/food_watermark_background.dart';

class PantryComparisonScreen extends ConsumerWidget {
  const PantryComparisonScreen({
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
  static const Color _lightBrown = Color(0xFFFFE7DE);
  static const Color _text = Color(0xFF252525);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  // ============================================================
  // SCALE QUANTITY
  // ============================================================

  double _scaledQuantity(double quantity) {
    if (recipe.servings <= 0) {
      return quantity;
    }

    return quantity * (selectedServings / recipe.servings);
  }

  // ============================================================
  // NORMALIZE NAME
  // ============================================================

  String _normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ============================================================
  // FORMAT QUANTITY
  // ============================================================

  String _formatQuantity(double quantity) {
    if (quantity <= 0) {
      return '0';
    }

    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    final value = quantity.toStringAsFixed(2);

    if (value.endsWith('0')) {
      return value.substring(0, value.length - 1);
    }

    return value;
  }

  // ============================================================
  // COMPARE PANTRY WITH RECIPE
  // ============================================================

  List<PantryComparisonItem> _compare(List<PantryItemModel> pantryItems) {
    final results = <PantryComparisonItem>[];

    for (final ingredient in recipe.ingredients) {
      final double requiredQuantity = _scaledQuantity(ingredient.quantity);

      final String recipeName = _normalizeName(ingredient.name);

      PantryItemModel? matchingItem;

      for (final pantryItem in pantryItems) {
        final String pantryName = _normalizeName(pantryItem.ingredient.name);

        if (pantryName == recipeName) {
          matchingItem = pantryItem;
          break;
        }
      }

      final double pantryQuantity = matchingItem?.quantity ?? 0.0;

      final String unit = ingredient.unit;

      final String recipeUnit = ingredient.unit.trim().toLowerCase();

      final String pantryUnit =
          matchingItem?.unit.symbol.trim().toLowerCase() ?? recipeUnit;

      final bool sameUnit = matchingItem == null || pantryUnit == recipeUnit;

      final double usablePantryQuantity = sameUnit ? pantryQuantity : 0.0;

      final double missingQuantity = requiredQuantity > usablePantryQuantity
          ? requiredQuantity - usablePantryQuantity
          : 0.0;

      results.add(
        PantryComparisonItem(
          recipeIngredient: ingredient,
          requiredQuantity: requiredQuantity,
          pantryQuantity: usablePantryQuantity,
          missingQuantity: missingQuantity,
          unit: unit,
          isAvailable: missingQuantity <= 0.0,
        ),
      );
    }

    return results;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantryState = ref.watch(pantryItemsProvider);

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
          'Check My Pantry',
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
        child: pantryState.when(
          // ------------------------------------------------------
          // LOADING
          // ------------------------------------------------------

          loading: () {
            return const Center(child: CircularProgressIndicator(color: _teal));
          },

          // ------------------------------------------------------
          // ERROR
          // ------------------------------------------------------
          error: (error, stackTrace) {
            return _ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(pantryItemsProvider);
              },
            );
          },

          // ------------------------------------------------------
          // DATA
          // ------------------------------------------------------
          data: (pantryItems) {
            final comparisons = _compare(pantryItems);

            final available = comparisons
                .where((item) => item.isAvailable)
                .toList();

            final missing = comparisons
                .where((item) => !item.isAvailable)
                .toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),

              children: [
                // ==================================================
                // RECIPE HEADER
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

                Text(
                  'Ingredients for $selectedServings '
                  '${selectedServings == 1 ? 'person' : 'people'}',
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 23),

                // ==================================================
                // SUMMARY CARDS
                // ==================================================
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.check_circle_outline,
                        title: 'Already Have',
                        count: available.length,
                        iconColor: _teal,
                        backgroundColor: _lightTeal,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Need to Buy',
                        count: missing.length,
                        iconColor: _brown,
                        backgroundColor: _lightBrown,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ==================================================
                // ALREADY HAVE
                // ==================================================
                if (available.isNotEmpty) ...[
                  const Text(
                    'Already Have',
                    style: TextStyle(
                      color: _darkTeal,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 13),

                  ...available.map(
                    (item) => _IngredientCard(
                      item: item,
                      formatQuantity: _formatQuantity,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                // ==================================================
                // NEED TO BUY
                // ==================================================
                if (missing.isNotEmpty) ...[
                  const Text(
                    'Need to Buy',
                    style: TextStyle(
                      color: _darkTeal,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 13),

                  ...missing.map(
                    (item) => _IngredientCard(
                      item: item,
                      formatQuantity: _formatQuantity,
                    ),
                  ),

                  const SizedBox(height: 18),
                ],

                // ==================================================
                // EVERYTHING AVAILABLE
                // ==================================================
                if (missing.isEmpty) const _EverythingAvailableCard(),

                // ==================================================
                // GET MISSING INGREDIENTS
                // ==================================================
                if (missing.isNotEmpty)
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
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductMatchingScreen(
                              missingItems: missing,
                              selectedServings: selectedServings,
                              recipeTitle: recipe.title,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_outlined, size: 22),
                      label: const Text(
                        'Get Missing Ingredients',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // ==================================================
                // REFRESH PANTRY
                // ==================================================
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ref.invalidate(pantryItemsProvider);
                    },
                    icon: const Icon(Icons.refresh, color: _brown, size: 20),
                    label: const Text(
                      'Refresh Pantry',
                      style: TextStyle(
                        color: _brown,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// SUMMARY CARD
// ============================================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: PantryComparisonScreen._border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 25),
          ),

          const SizedBox(height: 8),

          Text(
            count.toString(),
            style: const TextStyle(
              color: PantryComparisonScreen._text,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PantryComparisonScreen._secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w400,
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
  const _IngredientCard({required this.item, required this.formatQuantity});

  final PantryComparisonItem item;
  final String Function(double) formatQuantity;

  @override
  Widget build(BuildContext context) {
    final isAvailable = item.isAvailable;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: PantryComparisonScreen._border),
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
          // STATUS ICON
          // ========================================================

          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isAvailable
                  ? PantryComparisonScreen._lightTeal
                  : PantryComparisonScreen._lightBrown,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAvailable ? Icons.check : Icons.shopping_cart_outlined,
              color: isAvailable
                  ? PantryComparisonScreen._teal
                  : PantryComparisonScreen._brown,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          // ========================================================
          // NAME + QUANTITIES
          // ========================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.recipeIngredient.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PantryComparisonScreen._darkTeal,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Required: '
                  '${formatQuantity(item.requiredQuantity)} '
                  '${item.unit}',
                  style: const TextStyle(
                    color: PantryComparisonScreen._secondaryText,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),

                if (item.pantryQuantity > 0)
                  Text(
                    'In pantry: '
                    '${formatQuantity(item.pantryQuantity)} '
                    '${item.unit}',
                    style: const TextStyle(
                      color: PantryComparisonScreen._secondaryText,
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),

                if (!isAvailable)
                  Text(
                    'Missing: '
                    '${formatQuantity(item.missingQuantity)} '
                    '${item.unit}',
                    style: const TextStyle(
                      color: PantryComparisonScreen._brown,
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ========================================================
          // STATUS
          // ========================================================
          Icon(
            isAvailable ? Icons.check_circle : Icons.shopping_cart,
            color: isAvailable
                ? PantryComparisonScreen._teal
                : PantryComparisonScreen._brown,
            size: 24,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EVERYTHING AVAILABLE
// ============================================================================

class _EverythingAvailableCard extends StatelessWidget {
  const _EverythingAvailableCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: PantryComparisonScreen._border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 52,
            color: PantryComparisonScreen._teal,
          ),

          SizedBox(height: 11),

          Text(
            'You have everything!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PantryComparisonScreen._darkTeal,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'All required ingredients are available '
            'in your pantry.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PantryComparisonScreen._secondaryText,
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ERROR VIEW
// ============================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: PantryComparisonScreen._brown,
            ),

            const SizedBox(height: 18),

            const Text(
              'Could not load your pantry',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PantryComparisonScreen._darkTeal,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PantryComparisonScreen._secondaryText,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: PantryComparisonScreen._teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
