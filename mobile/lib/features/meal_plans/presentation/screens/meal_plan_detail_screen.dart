import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/meal_nutrition_model.dart';
import '../providers/meal_nutrition_provider.dart';
import '../providers/meal_plan_provider.dart';
import 'add_meal_screen.dart';
import 'edit_meal_plan_screen.dart';

class MealPlanDetailScreen extends ConsumerWidget {
  const MealPlanDetailScreen({super.key, required this.mealPlanId});

  final String mealPlanId;

  // ===========================================================
  // DATE FORMAT
  // ===========================================================

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ===========================================================
  // MEAL ICON
  // ===========================================================

  IconData _mealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast_outlined;

      case 'lunch':
        return Icons.lunch_dining_outlined;

      case 'dinner':
        return Icons.dinner_dining_outlined;

      case 'snack':
        return Icons.cookie_outlined;

      default:
        return Icons.restaurant_outlined;
    }
  }

  // ===========================================================
  // DELETE MEAL PLAN
  // ===========================================================

  Future<void> _confirmDeleteMealPlan(
    BuildContext context,
    WidgetRef ref,
    String mealPlanName,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Meal Plan?'),
          content: Text(
            'Are you sure you want to delete '
            '"$mealPlanName"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      final deleteMealPlan = ref.read(deleteMealPlanProvider);

      await deleteMealPlan(mealPlanId);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal plan deleted successfully.')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete meal plan: $error')),
      );
    }
  }

  // ===========================================================
  // DELETE MEAL
  // ===========================================================

  Future<void> _confirmDeleteMeal(
    BuildContext context,
    WidgetRef ref,
    String mealPlanId,
    String mealId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Meal?'),
          content: const Text(
            'Are you sure you want to remove '
            'this meal from the meal plan?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      final deleteMeal = ref.read(deleteMealProvider);

      await deleteMeal(mealPlanId, mealId);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal deleted successfully.')),
      );

      ref.invalidate(mealPlanDetailProvider(mealPlanId));

      ref.invalidate(mealPlanNutritionProvider(mealPlanId));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete meal: $error')));
    }
  }

  // ===========================================================
  // NUTRITION SECTION
  // ===========================================================

  Widget _nutritionSection(
    BuildContext context,
    AsyncValue<MealNutritionModel> nutritionState,
  ) {
    return nutritionState.when(
      loading: () {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nutrition',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Unable to load nutrition information.'),
                ),
              ],
            ),
          ),
        );
      },
      data: (nutrition) {
        return _buildNutritionCard(context, nutrition);
      },
    );
  }

  // ===========================================================
  // NUTRITION CARD
  // ===========================================================

  Widget _buildNutritionCard(
    BuildContext context,
    MealNutritionModel nutrition,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.monitor_heart_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutrition',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Nutrition by meal type',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _mealNutritionCard(
              context,
              'Breakfast',
              Icons.free_breakfast_outlined,
              nutrition.breakfast,
            ),

            const SizedBox(height: 12),

            _mealNutritionCard(
              context,
              'Lunch',
              Icons.lunch_dining_outlined,
              nutrition.lunch,
            ),

            const SizedBox(height: 12),

            _mealNutritionCard(
              context,
              'Dinner',
              Icons.dinner_dining_outlined,
              nutrition.dinner,
            ),

            const SizedBox(height: 12),

            _mealNutritionCard(
              context,
              'Snack',
              Icons.cookie_outlined,
              nutrition.snack,
            ),

            const SizedBox(height: 16),

            _mealNutritionCard(
              context,
              'Total',
              Icons.calculate_outlined,
              nutrition.total,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // MEAL NUTRITION CARD
  // ===========================================================

  Widget _mealNutritionCard(
    BuildContext context,
    String title,
    IconData icon,
    NutritionSummaryModel nutrition, {
    bool isTotal = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTotal
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _nutritionValue(
                  'Calories',
                  '${nutrition.calories.toStringAsFixed(0)} kcal',
                ),
              ),
              Expanded(
                child: _nutritionValue(
                  'Protein',
                  '${nutrition.protein.toStringAsFixed(1)} g',
                ),
              ),
              Expanded(
                child: _nutritionValue(
                  'Carbs',
                  '${nutrition.carbs.toStringAsFixed(1)} g',
                ),
              ),
              Expanded(
                child: _nutritionValue(
                  'Fat',
                  '${nutrition.fat.toStringAsFixed(1)} g',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // NUTRITION VALUE
  // ===========================================================

  Widget _nutritionValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlanState = ref.watch(mealPlanDetailProvider(mealPlanId));

    return Scaffold(
      appBar: AppBar(title: const Text('Meal Plan')),
      body: mealPlanState.when(
        // =====================================================
        // LOADING
        // =====================================================

        loading: () {
          return const Center(child: CircularProgressIndicator());
        },

        // =====================================================
        // ERROR
        // =====================================================
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load this meal plan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(mealPlanDetailProvider(mealPlanId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },

        // =====================================================
        // DATA
        // =====================================================
        data: (mealPlan) {
          if (mealPlan == null) {
            return const Center(child: Text('Meal plan not found.'));
          }

          final sortedMeals = [...mealPlan.meals]
            ..sort((a, b) => a.mealDate.compareTo(b.mealDate));

          final nutritionState = ref.watch(
            mealPlanNutritionProvider(mealPlan.id),
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(mealPlanDetailProvider(mealPlanId));

              ref.invalidate(mealPlanNutritionProvider(mealPlan.id));

              await ref.read(mealPlanDetailProvider(mealPlanId).future);

              await ref.read(mealPlanNutritionProvider(mealPlan.id).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // =================================================
                // HEADER
                // =================================================

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              mealPlan.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (mealPlan.description != null &&
                          mealPlan.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          mealPlan.description!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.45,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Icon(Icons.restaurant_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${sortedMeals.length} '
                            '${sortedMeals.length == 1 ? 'meal' : 'meals'}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // NUTRITION
                // =================================================
                _nutritionSection(context, nutritionState),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/meal-plans/${mealPlan.id}/nutrition');
                    },
                    icon: const Icon(Icons.monitor_heart_outlined),
                    label: const Text(
                      'View Full Nutrition',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // EDIT MEAL PLAN
                // =================================================

                // =================================================
                // EDIT MEAL PLAN
                // =================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              EditMealPlanScreen(mealPlan: mealPlan),
                        ),
                      );

                      if (updated == true) {
                        ref.invalidate(mealPlanDetailProvider(mealPlanId));

                        ref.invalidate(mealPlanNutritionProvider(mealPlan.id));
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text(
                      'EDIT MEAL PLAN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // =================================================
                // DELETE MEAL PLAN
                // =================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _confirmDeleteMealPlan(context, ref, mealPlan.name);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      'DELETE MEAL PLAN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // ADD MEAL
                // =================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final added = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              AddMealScreen(mealPlanId: mealPlan.id),
                        ),
                      );

                      if (added == true) {
                        ref.invalidate(mealPlanDetailProvider(mealPlanId));

                        ref.invalidate(mealPlanNutritionProvider(mealPlan.id));
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'ADD MEAL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // =================================================
                // MEALS
                // =================================================
                const Text(
                  'Meals',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                if (sortedMeals.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant_outlined,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No meals added yet.',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add recipes to this meal plan '
                          'to start organizing your meals.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                else
                  ...sortedMeals.map(
                    (meal) => Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _mealIcon(meal.mealType),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal.mealType,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _formatDate(meal.mealDate),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Recipe ID: ${meal.recipeId}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (meal.notes != null &&
                                      meal.notes!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      meal.notes!,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            IconButton(
                              tooltip: 'Delete meal',
                              onPressed: () {
                                _confirmDeleteMeal(
                                  context,
                                  ref,
                                  mealPlan.id,
                                  meal.id,
                                );
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
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
