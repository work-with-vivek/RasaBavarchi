import 'package:dio/dio.dart';

import 'package:mobile/features/ai/data/models/ai_recipe_model.dart';
import 'package:mobile/features/ai/data/models/explain_recipe_request.dart';
import 'package:mobile/features/ai/data/models/explain_recipe_response.dart';
import 'package:mobile/features/ai/data/models/generate_pantry_recipe_request.dart';
import 'package:mobile/features/ai/data/models/generate_recipe_request.dart';

class AIRemoteDataSource {
  AIRemoteDataSource(this._dio);

  final Dio _dio;

  // =========================================================
  // GENERATE RECIPE
  // =========================================================

  Future<AIRecipeModel> generateRecipe(GenerateRecipeRequest request) async {
    final response = await _dio.post(
      '/ai/generate-recipe',
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid AI recipe response.');
    }

    return AIRecipeModel.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // GENERATE RECIPE FROM PANTRY
  // =========================================================

  Future<AIRecipeModel> generateRecipeFromPantry(
    GeneratePantryRecipeRequest request,
  ) async {
    final response = await _dio.post(
      '/ai/generate-recipe-from-pantry',
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid AI recipe response.');
    }

    return AIRecipeModel.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // EXPLAIN RECIPE
  // =========================================================

  Future<ExplainRecipeResponse> explainRecipe(
    ExplainRecipeRequest request,
  ) async {
    final response = await _dio.post(
      '/ai/explain-recipe',
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid AI explanation response.');
    }

    return ExplainRecipeResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
