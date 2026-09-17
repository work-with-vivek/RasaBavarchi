import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/recipe_visuals/recipe_visual_mapper.dart';
import '../../../../core/widgets/food_watermark_background.dart';
import '../../../../features/recipes/data/models/recipe_model.dart';
import '../providers/weight_loss_provider.dart';
import 'weight_loss_profile_screen.dart';

class WeightLossScreen extends ConsumerWidget {
  const WeightLossScreen({super.key});

  // =============================================================
  // RASABAVARCHI COLORS
  // =============================================================

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  // =============================================================
  // OPEN PROFILE
  // =============================================================

  Future<void> _openProfile(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const WeightLossProfileScreen()),
    );

    if (result == true) {
      ref.invalidate(weightLossProfileProvider);
      ref.invalidate(weightLossCalculationProvider);
      ref.invalidate(
        weightLossRecipesProvider((vegetarian: null, vegan: null)),
      );
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(weightLossProfileProvider);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Weight Loss',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: _darkTeal,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          profileAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (profile) {
              if (profile == null) {
                return const SizedBox.shrink();
              }

              return IconButton(
                onPressed: () {
                  _openProfile(context, ref);
                },
                icon: const Icon(Icons.edit_outlined, color: _darkTeal),
                tooltip: 'Edit Profile',
              );
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _teal)),
        error: (error, stackTrace) {
          return _buildErrorState(context, ref, error);
        },
        data: (profile) {
          if (profile == null) {
            return _buildProfileRequired(context, ref);
          }

          return _buildDashboard(context, ref);
        },
      ),
    );
  }

  // =============================================================
  // DASHBOARD
  // =============================================================

  Widget _buildDashboard(BuildContext context, WidgetRef ref) {
    final calculationAsync = ref.watch(weightLossCalculationProvider);

    return calculationAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _teal)),
      error: (error, stackTrace) {
        return _buildErrorState(context, ref, error);
      },
      data: (calculation) {
        return FoodWatermarkBackground(
          child: RefreshIndicator(
            color: _teal,
            onRefresh: () async {
              ref.invalidate(weightLossCalculationProvider);

              ref.invalidate(
                weightLossRecipesProvider((vegetarian: null, vegan: null)),
              );

              await ref.read(weightLossCalculationProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                // =================================================
                // INTRO
                // =================================================

                const Text(
                  'Your Weight Loss Dashboard',
                  style: TextStyle(
                    fontSize: 25,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: _darkTeal,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Here is your estimated progress based on your '
                  'saved profile.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: _secondaryText,
                  ),
                ),

                const SizedBox(height: 13),

                Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _yellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // WEIGHT GOAL
                // =================================================
                _buildWeightProgressCard(
                  context,
                  currentWeight: calculation.currentWeightKg,
                  goalWeight: calculation.goalWeightKg,
                  weightToLose: calculation.weightToLoseKg,
                ),

                const SizedBox(height: 14),

                // =================================================
                // METRICS
                // =================================================
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'BMI',
                        value: calculation.bmi.toStringAsFixed(2),
                        icon: Icons.monitor_weight_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'BMR',
                        value: '${calculation.bmr.toStringAsFixed(0)} kcal',
                        icon: Icons.local_fire_department_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _buildMetricCard(
                  title: 'TDEE',
                  value: '${calculation.tdee.toStringAsFixed(0)} kcal/day',
                  icon: Icons.bolt_outlined,
                  fullWidth: true,
                ),

                const SizedBox(height: 12),

                // =================================================
                // CALORIE TARGET
                // =================================================
                _buildCalorieTargetCard(calculation.dailyCalorieTarget),

                const SizedBox(height: 28),

                // =================================================
                // RECOMMENDED RECIPES
                // =================================================
                _buildRecommendedRecipesSection(context, ref),

                const SizedBox(height: 22),

                // =================================================
                // UPDATE PROFILE
                // =================================================
                SizedBox(
                  height: 53,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      _openProfile(context, ref);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    label: const Text(
                      'Update Profile',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'These calculations are estimates for informational '
                  'purposes and are not medical advice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: _secondaryText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // RECOMMENDED RECIPES
  // =============================================================

  Widget _buildRecommendedRecipesSection(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(
      weightLossRecipesProvider((vegetarian: null, vegan: null)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended Recipes',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: _darkTeal,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Recipes selected using your estimated calorie target.',
          style: TextStyle(fontSize: 13, height: 1.35, color: _secondaryText),
        ),

        const SizedBox(height: 13),

        recipesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator(color: _teal)),
          ),
          error: (error, stackTrace) {
            return _buildRecipeError(context, ref);
          },
          data: (recipes) {
            if (recipes.isEmpty) {
              return _buildNoRecipesState(context);
            }

            return Column(
              children: recipes
                  .map((recipe) => _buildRecipeCard(context, recipe))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  // =============================================================
  // RECIPE CARD
  // =============================================================

  Widget _buildRecipeCard(BuildContext context, RecipeModel recipe) {
    final visualPath = RecipeVisualMapper.getVisual(
      recipeName: recipe.title,
      category: null,
      foodType: null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/recipe/${recipe.id}');
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // RECIPE VISUAL
                // =================================================

                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F0DF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    visualPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.restaurant_menu_rounded,
                          size: 34,
                          color: _teal,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 13),

                // =================================================
                // RECIPE INFORMATION
                // =================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: _darkTeal,
                        ),
                      ),

                      const SizedBox(height: 7),

                      // CALORIES
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_outlined,
                            size: 16,
                            color: _teal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.calories.toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _teal,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // MACROS
                      Text(
                        'Protein ${recipe.protein.toStringAsFixed(0)}g  •  '
                        'Carbs ${recipe.carbs.toStringAsFixed(0)}g  •  '
                        'Fat ${recipe.fat.toStringAsFixed(0)}g',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          color: _secondaryText,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // SERVINGS + ARROW
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant_outlined,
                            size: 15,
                            color: _secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.servings} servings',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _secondaryText,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                            color: _teal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // RECIPE ERROR
  // =============================================================

  Widget _buildRecipeError(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border, width: 0.8),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 38, color: _teal),

          const SizedBox(height: 9),

          const Text(
            'Unable to load recommended recipes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _darkTeal,
            ),
          ),

          const SizedBox(height: 11),

          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(
                weightLossRecipesProvider((vegetarian: null, vegan: null)),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _teal,
              side: const BorderSide(color: _teal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // NO RECIPES
  // =============================================================

  Widget _buildNoRecipesState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border, width: 0.8),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: _cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_outlined,
              size: 29,
              color: _teal,
            ),
          ),

          const SizedBox(height: 11),

          const Text(
            'No suitable recipes are available yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _darkTeal,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'More recipes will appear as nutrition data '
            'becomes available.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.35, color: _secondaryText),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // PROFILE REQUIRED
  // =============================================================

  Widget _buildProfileRequired(BuildContext context, WidgetRef ref) {
    return FoodWatermarkBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // =================================================
              // ICON
              // =================================================

              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: _teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monitor_weight_outlined,
                  size: 47,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Set up your weight loss profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: _darkTeal,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Add your age, height, weight, activity level, '
                'and goal weight to calculate your estimated '
                'daily energy needs.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: _secondaryText,
                ),
              ),

              const SizedBox(height: 15),

              Container(
                width: 34,
                height: 3,
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                height: 53,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _openProfile(context, ref);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                  label: const Text(
                    'Set Up Profile',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // ERROR STATE
  // =============================================================

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return FoodWatermarkBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 38,
                  color: _teal,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Unable to load weight loss data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _darkTeal,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: _secondaryText,
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(weightLossProfileProvider);

                    ref.invalidate(weightLossCalculationProvider);

                    ref.invalidate(
                      weightLossRecipesProvider((
                        vegetarian: null,
                        vegan: null,
                      )),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  label: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // WEIGHT PROGRESS CARD
  // =============================================================

  Widget _buildWeightProgressCard(
    BuildContext context, {
    required double currentWeight,
    required double goalWeight,
    required double weightToLose,
  }) {
    final progress = currentWeight > 0
        ? ((currentWeight - goalWeight) / currentWeight).clamp(0.0, 1.0)
        : 0.0;

    final goalReached = weightToLose <= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Weight Goal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _darkTeal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _cream,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  goalReached ? 'Goal reached' : 'In progress',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: goalReached ? _teal : _secondaryText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              Expanded(
                child: _weightValue(
                  label: 'Current',
                  value: '${currentWeight.toStringAsFixed(1)} kg',
                ),
              ),

              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _cream,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 19,
                  color: _teal,
                ),
              ),

              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _weightValue(
                    label: 'Goal',
                    value: '${goalWeight.toStringAsFixed(1)} kg',
                    alignEnd: true,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFEDE5D8),
              valueColor: const AlwaysStoppedAnimation(_teal),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            goalReached
                ? 'Goal weight reached'
                : '${weightToLose.toStringAsFixed(1)} kg remaining',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // WEIGHT VALUE
  // =============================================================

  Widget _weightValue({
    required String label,
    required String value,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: _secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _darkTeal,
          ),
        ),
      ],
    );
  }

  // =============================================================
  // METRIC CARD
  // =============================================================

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: const BoxDecoration(
              color: _cream,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _teal, size: 23),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _secondaryText,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _darkTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // CALORIE TARGET
  // =============================================================

  Widget _buildCalorieTargetCard(double calorieTarget) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 27,
              color: _yellow,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Daily Calorie Target',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${calorieTarget.toStringAsFixed(0)} kcal/day',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
