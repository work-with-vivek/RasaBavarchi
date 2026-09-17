import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/food_watermark_background.dart';
import '../providers/nutrition_provider.dart';

class RecipeNutritionScreen extends ConsumerWidget {
  const RecipeNutritionScreen({super.key, required this.recipeId});

  final String recipeId;

  // ============================================================
  // RASABAVARCHI COLORS
  // ============================================================

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _brown = Color(0xFF9C513A);
  static const Color _text = Color(0xFF252525);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);
  static const Color _white = Colors.white;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(recipeNutritionProvider(recipeId));

    return Scaffold(
      backgroundColor: _cream,

      // ============================================================
      // APP BAR
      // ============================================================
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
          'Nutrition',
          style: TextStyle(
            color: _teal,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: FoodWatermarkBackground(
        child: nutritionAsync.when(
          // --------------------------------------------------------
          // LOADING
          // --------------------------------------------------------

          loading: () {
            return const Center(child: CircularProgressIndicator(color: _teal));
          },

          // --------------------------------------------------------
          // ERROR
          // --------------------------------------------------------
          error: (error, stackTrace) {
            return _ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(recipeNutritionProvider(recipeId));
              },
            );
          },

          // --------------------------------------------------------
          // DATA
          // --------------------------------------------------------
          data: (nutrition) {
            return RefreshIndicator(
              color: _teal,

              onRefresh: () async {
                ref.invalidate(recipeNutritionProvider(recipeId));

                await ref.read(recipeNutritionProvider(recipeId).future);
              },

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),

                children: [
                  // ==================================================
                  // RECIPE NAME
                  // ==================================================

                  Text(
                    nutrition.recipeName,
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

                  const Text(
                    'Nutrition information',
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // CALORIES
                  // ==================================================
                  _CaloriesCard(calories: nutrition.calories),

                  const SizedBox(height: 25),

                  // ==================================================
                  // MACRONUTRIENTS TITLE
                  // ==================================================
                  const Text(
                    'Macronutrients',
                    style: TextStyle(
                      color: _darkTeal,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 13),

                  // ==================================================
                  // PROTEIN + CARBS
                  // ==================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _NutritionCard(
                          title: 'Protein',
                          value: nutrition.proteinG,
                          unit: 'g',
                          icon: Icons.fitness_center,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: _NutritionCard(
                          title: 'Carbs',
                          value: nutrition.carbsG,
                          unit: 'g',
                          icon: Icons.grain,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // FAT
                  // ==================================================
                  _NutritionCard(
                    title: 'Fat',
                    value: nutrition.fatG,
                    unit: 'g',
                    icon: Icons.opacity,
                    fullWidth: true,
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // INFORMATION CARD
                  // ==================================================
                  const _InformationCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// CALORIES CARD
// ============================================================================

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({required this.calories});

  final double calories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 174,

      decoration: BoxDecoration(
        color: RecipeNutritionScreen._white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: RecipeNutritionScreen._border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_fire_department_outlined,
            size: 42,
            color: RecipeNutritionScreen._brown,
          ),

          const SizedBox(height: 7),

          Text(
            _formatNumber(calories),
            style: const TextStyle(
              color: RecipeNutritionScreen._text,
              fontSize: 40,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Calories',
            style: TextStyle(
              color: RecipeNutritionScreen._text,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NUTRITION CARD
// ============================================================================

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.fullWidth = false,
  });

  final String title;
  final double value;
  final String unit;
  final IconData icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: fullWidth ? 137 : 132,

      decoration: BoxDecoration(
        color: RecipeNutritionScreen._white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: RecipeNutritionScreen._border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),

      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 27, color: RecipeNutritionScreen._brown),

          const Spacer(),

          Text(
            title,
            style: const TextStyle(
              color: RecipeNutritionScreen._darkTeal,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '${_formatNumber(value)} $unit',
            style: const TextStyle(
              color: RecipeNutritionScreen._text,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w600,
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
  const _InformationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: RecipeNutritionScreen._white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: RecipeNutritionScreen._border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 25,
            color: RecipeNutritionScreen._brown,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Nutrition values are based on the recipe information available in RasaBavarchi.',
              style: TextStyle(
                color: RecipeNutritionScreen._text,
                fontSize: 15.5,
                height: 1.32,
                fontWeight: FontWeight.w400,
              ),
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
              color: RecipeNutritionScreen._brown,
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load nutrition',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RecipeNutritionScreen._darkTeal,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RecipeNutritionScreen._secondaryText,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 22),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: RecipeNutritionScreen._teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NUMBER FORMATTER
// ============================================================================

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(1)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
