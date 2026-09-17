import 'package:dio/dio.dart';

import '../models/meal_plan_nutrition_model.dart';
import '../models/recipe_nutrition_model.dart';

class NutritionRemoteDataSource {
  NutritionRemoteDataSource(this._dio);

  final Dio _dio;

  // =========================================================
  // GET RECIPE NUTRITION
  // =========================================================

  Future<RecipeNutritionModel> getRecipeNutrition(String recipeId) async {
    final response = await _dio.get('/nutrition/recipes/$recipeId');

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid recipe nutrition response.');
    }

    return RecipeNutritionModel.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // GET MEAL PLAN NUTRITION
  // =========================================================

  Future<MealPlanNutritionModel> getMealPlanNutrition(String mealPlanId) async {
    final response = await _dio.get('/nutrition/meal-plans/$mealPlanId');

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid meal plan nutrition response.');
    }

    return MealPlanNutritionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
