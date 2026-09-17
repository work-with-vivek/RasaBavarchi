import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/meal_plan_model.dart';
import '../providers/meal_plan_provider.dart';
import 'meal_plan_detail_screen.dart';
import 'create_meal_plan_screen.dart';

class MyMealPlansScreen extends ConsumerWidget {
  const MyMealPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlansState = ref.watch(mealPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Meal Plans')),
      body: mealPlansState.when(
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
                    'Could not load your meal plans.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(mealPlansProvider);
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
        data: (mealPlans) {
          if (mealPlans.isEmpty) {
            return _EmptyMealPlans(
              onCreatePressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateMealPlanScreen(),
                  ),
                );
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(mealPlansProvider);

              await ref.read(mealPlansProvider.future);
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 42,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Meal Plans',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${mealPlans.length} '
                              '${mealPlans.length == 1 ? 'plan' : 'plans'}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // MEAL PLAN CARDS
                // =================================================
                ...mealPlans.map(
                  (mealPlan) => _MealPlanCard(
                    mealPlan: mealPlan,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MealPlanDetailScreen(mealPlanId: mealPlan.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // =========================================================
      // CREATE PLAN BUTTON
      // =========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateMealPlanScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Plan'),
      ),
    );
  }
}

// =============================================================
// MEAL PLAN CARD
// =============================================================

class _MealPlanCard extends StatelessWidget {
  const _MealPlanCard({required this.mealPlan, required this.onTap});

  final MealPlanModel mealPlan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealCount = mealPlan.meals.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealPlan.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (mealPlan.description != null &&
                        mealPlan.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        mealPlan.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$mealCount '
                          '${mealCount == 1 ? 'meal' : 'meals'}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// EMPTY STATE
// =============================================================

class _EmptyMealPlans extends StatelessWidget {
  const _EmptyMealPlans({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Meal Plans Yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Create a meal plan to organize '
              'your recipes for the week.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add),
              label: const Text('Create Meal Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
