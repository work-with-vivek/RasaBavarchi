import 'package:dio/dio.dart';

import '../models/meal_nutrition_model.dart';

class MealNutritionRemoteDataSource {
  MealNutritionRemoteDataSource(this._dio);

  final Dio _dio;

  Future<MealNutritionModel> getMealPlanNutrition(String mealPlanId) async {
    final response = await _dio.get('/nutrition/meal-plans/$mealPlanId');

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid meal plan nutrition response.');
    }

    return MealNutritionModel.fromJson(response.data as Map<String, dynamic>);
  }
}
