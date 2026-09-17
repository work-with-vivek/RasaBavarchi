import 'package:dio/dio.dart';

import '../../../recipes/data/models/recipe_model.dart';
import '../models/weight_loss_calculation_model.dart';
import '../models/weight_loss_profile_model.dart';

class WeightLossRemoteDataSource {
  WeightLossRemoteDataSource(this._dio);

  final Dio _dio;

  // =========================================================
  // GET WEIGHT LOSS PROFILE
  // =========================================================

  Future<WeightLossProfileModel?> getProfile() async {
    final response = await _dio.get('/weight-loss/profile');

    if (response.data == null) {
      return null;
    }

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid weight loss profile response.');
    }

    return WeightLossProfileModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // =========================================================
  // CREATE / UPDATE WEIGHT LOSS PROFILE
  // =========================================================

  Future<WeightLossProfileModel> saveProfile({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required double goalWeightKg,
  }) async {
    final response = await _dio.post(
      '/weight-loss/profile',
      data: {
        'age': age,
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'activity_level': activityLevel,
        'goal_weight_kg': goalWeightKg,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid weight loss profile response.');
    }

    return WeightLossProfileModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // =========================================================
  // GET WEIGHT LOSS CALCULATION
  // =========================================================

  Future<WeightLossCalculationModel> getCalculation() async {
    final response = await _dio.get('/weight-loss/calculate');

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid weight loss calculation response.');
    }

    return WeightLossCalculationModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // =========================================================
  // GET WEIGHT LOSS RECIPES
  // =========================================================

  Future<List<RecipeModel>> getWeightLossRecipes({
    bool? vegetarian,
    bool? vegan,
    int limit = 12,
  }) async {
    final queryParameters = <String, dynamic>{'limit': limit};

    if (vegetarian != null) {
      queryParameters['vegetarian'] = vegetarian;
    }

    if (vegan != null) {
      queryParameters['vegan'] = vegan;
    }

    final response = await _dio.get(
      '/weight-loss/recipes',
      queryParameters: queryParameters,
    );

    if (response.data is! List) {
      throw Exception('Invalid weight loss recipes response.');
    }

    return (response.data as List)
        .map((item) => RecipeModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
