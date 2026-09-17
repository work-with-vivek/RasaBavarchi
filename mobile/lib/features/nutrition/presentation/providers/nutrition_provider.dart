import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasource/nutrition_remote_data_source.dart';
import '../../data/models/meal_plan_nutrition_model.dart';
import '../../data/models/recipe_nutrition_model.dart';
import '../../data/repositories/nutrition_repository_impl.dart';
import '../../domain/repositories/nutrition_repository.dart';

// =============================================================
// REMOTE DATA SOURCE
// =============================================================

final nutritionRemoteDataSourceProvider = Provider<NutritionRemoteDataSource>((
  ref,
) {
  return NutritionRemoteDataSource(ApiClient().dio);
});

// =============================================================
// REPOSITORY
// =============================================================

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepositoryImpl(ref.read(nutritionRemoteDataSourceProvider));
});

// =============================================================
// RECIPE NUTRITION
// =============================================================

final recipeNutritionProvider =
    FutureProvider.family<RecipeNutritionModel, String>((ref, recipeId) async {
      final repository = ref.read(nutritionRepositoryProvider);

      return repository.getRecipeNutrition(recipeId);
    });

// =============================================================
// MEAL PLAN NUTRITION
// =============================================================

final mealPlanNutritionProvider =
    FutureProvider.family<MealPlanNutritionModel, String>((
      ref,
      mealPlanId,
    ) async {
      final repository = ref.read(nutritionRepositoryProvider);

      return repository.getMealPlanNutrition(mealPlanId);
    });
