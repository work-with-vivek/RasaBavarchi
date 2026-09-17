import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/nutrition_provider.dart';

class MealPlanNutritionScreen extends ConsumerWidget {
  const MealPlanNutritionScreen({super.key, required this.mealPlanId});

  final String mealPlanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(mealPlanNutritionProvider(mealPlanId));

    return Scaffold(
      appBar: AppBar(title: const Text('Meal Plan Nutrition')),
      body: nutritionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(mealPlanNutritionProvider(mealPlanId));
          },
        ),
        data: (nutrition) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(mealPlanNutritionProvider(mealPlanId));

              await ref.read(mealPlanNutritionProvider(mealPlanId).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Daily Nutrition',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nutrition breakdown for your meal plan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // =================================================
                // TOTAL
                // =================================================
                _TotalNutritionCard(
                  calories: nutrition.total.calories,
                  proteinG: nutrition.total.proteinG,
                  carbsG: nutrition.total.carbsG,
                  fatG: nutrition.total.fatG,
                ),

                const SizedBox(height: 24),

                Text(
                  'Meals',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // =================================================
                // BREAKFAST
                // =================================================
                _MealNutritionCard(
                  title: 'Breakfast',
                  icon: Icons.free_breakfast_outlined,
                  calories: nutrition.breakfast.calories,
                  proteinG: nutrition.breakfast.proteinG,
                  carbsG: nutrition.breakfast.carbsG,
                  fatG: nutrition.breakfast.fatG,
                ),

                const SizedBox(height: 12),

                // =================================================
                // LUNCH
                // =================================================
                _MealNutritionCard(
                  title: 'Lunch',
                  icon: Icons.lunch_dining_outlined,
                  calories: nutrition.lunch.calories,
                  proteinG: nutrition.lunch.proteinG,
                  carbsG: nutrition.lunch.carbsG,
                  fatG: nutrition.lunch.fatG,
                ),

                const SizedBox(height: 12),

                // =================================================
                // DINNER
                // =================================================
                _MealNutritionCard(
                  title: 'Dinner',
                  icon: Icons.dinner_dining_outlined,
                  calories: nutrition.dinner.calories,
                  proteinG: nutrition.dinner.proteinG,
                  carbsG: nutrition.dinner.carbsG,
                  fatG: nutrition.dinner.fatG,
                ),

                const SizedBox(height: 12),

                // =================================================
                // SNACK
                // =================================================
                _MealNutritionCard(
                  title: 'Snack',
                  icon: Icons.cookie_outlined,
                  calories: nutrition.snack.calories,
                  proteinG: nutrition.snack.proteinG,
                  carbsG: nutrition.snack.carbsG,
                  fatG: nutrition.snack.fatG,
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nutrition values are calculated from the recipes included in this meal plan.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =============================================================
// TOTAL NUTRITION CARD
// =============================================================

class _TotalNutritionCard extends StatelessWidget {
  const _TotalNutritionCard({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              _formatNumber(calories),
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Calories',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MacroValue(label: 'Protein', value: proteinG),
                ),
                Expanded(
                  child: _MacroValue(label: 'Carbs', value: carbsG),
                ),
                Expanded(
                  child: _MacroValue(label: 'Fat', value: fatG),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// MEAL NUTRITION CARD
// =============================================================

class _MealNutritionCard extends StatelessWidget {
  const _MealNutritionCard({
    required this.title,
    required this.icon,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String title;
  final IconData icon;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_formatNumber(calories)} kcal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MacroValue(label: 'Protein', value: proteinG),
                ),
                Expanded(
                  child: _MacroValue(label: 'Carbs', value: carbsG),
                ),
                Expanded(
                  child: _MacroValue(label: 'Fat', value: fatG),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// MACRO VALUE
// =============================================================

class _MacroValue extends StatelessWidget {
  const _MacroValue({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatNumber(value),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          '$label (g)',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// =============================================================
// ERROR VIEW
// =============================================================

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
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Unable to load nutrition',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// NUMBER FORMATTER
// =============================================================

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(1)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
