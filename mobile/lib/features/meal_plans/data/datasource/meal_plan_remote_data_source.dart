import 'package:dio/dio.dart';

import '../models/meal_create_request.dart';
import '../models/meal_plan_model.dart';
import '../models/meal_plan_request.dart';
import '../models/meal_plan_update_request.dart';

class MealPlanRemoteDataSource {
  MealPlanRemoteDataSource(this._dio);

  final Dio _dio;

  // =========================================================
  // GET ALL MEAL PLANS
  // =========================================================

  Future<List<MealPlanModel>> getMealPlans() async {
    final response = await _dio.get('/meal-plans');

    if (response.data is! List) {
      throw Exception('Invalid meal plans response.');
    }

    return (response.data as List)
        .whereType<Map<String, dynamic>>()
        .map(MealPlanModel.fromJson)
        .toList();
  }

  // =========================================================
  // GET SINGLE MEAL PLAN
  // =========================================================

  Future<MealPlanModel?> getMealPlan(String mealPlanId) async {
    final response = await _dio.get('/meal-plans/$mealPlanId');

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid meal plan response.');
    }

    return MealPlanModel.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // CREATE MEAL PLAN
  // =========================================================

  Future<MealPlanModel> createMealPlan(MealPlanRequest request) async {
    final response = await _dio.post('/meal-plans', data: request.toJson());

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid created meal plan response.');
    }

    return MealPlanModel.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // UPDATE MEAL PLAN
  // =========================================================

  Future<MealPlanModel> updateMealPlan(
    String mealPlanId,
    MealPlanUpdateRequest request,
  ) async {
    final response = await _dio.put(
      '/meal-plans/$mealPlanId',
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid updated meal plan response.');
    }

    return MealPlanModel.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // DELETE MEAL PLAN
  // =========================================================

  Future<void> deleteMealPlan(String mealPlanId) async {
    await _dio.delete('/meal-plans/$mealPlanId');
  }

  // =========================================================
  // ADD MEAL
  // =========================================================

  Future<void> addMeal(String mealPlanId, MealCreateRequest request) async {
    await _dio.post('/meal-plans/$mealPlanId/meals', data: request.toJson());
  }

  // =========================================================
  // DELETE MEAL
  // =========================================================

  Future<void> deleteMeal(String mealId) async {
    await _dio.delete('/meal-plans/meals/$mealId');
  }
}
