import 'package:dio/dio.dart';

import '../models/recipe_model.dart';
import '../models/recipe_page_model.dart';

class RecipeRemoteDataSource {
  final Dio dio;

  RecipeRemoteDataSource(this.dio);

  // =========================================================
  // Get Recipes
  // =========================================================

  Future<RecipePageModel> getRecipes({
    int page = 1,
    int pageSize = 10,
    String? categoryId,
    String? foodType,
  }) async {
    final queryParameters = <String, dynamic>{
      "page": page,
      "page_size": pageSize,
    };

    // -------------------------------------------------------
    // Category
    // -------------------------------------------------------

    if (categoryId != null && categoryId.isNotEmpty) {
      queryParameters["category_id"] = categoryId;
    }

    // -------------------------------------------------------
    // Food Type
    // -------------------------------------------------------
    //
    // Possible values:
    //
    // VEGAN
    // VEGETARIAN
    // NON_VEGETARIAN
    // UNKNOWN
    //
    // Backend parameter:
    //
    // food_type
    //
    // -------------------------------------------------------

    if (foodType != null && foodType.isNotEmpty) {
      queryParameters["food_type"] = foodType.toUpperCase();
    }

    // -------------------------------------------------------
    // Request
    // -------------------------------------------------------

    final response = await dio.get(
      "/recipes",
      queryParameters: queryParameters,
    );

    return RecipePageModel.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // Search Recipes
  // =========================================================

  Future<List<RecipeModel>> searchRecipes({
    String? title,
    String? categoryId,
    String? cuisineId,
    String? difficultyId,
    String? foodType,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParameters = <String, dynamic>{
      "page": page,
      "page_size": pageSize,
    };

    // -------------------------------------------------------
    // Title
    // -------------------------------------------------------

    if (title != null && title.trim().isNotEmpty) {
      queryParameters["title"] = title.trim();
    }

    // -------------------------------------------------------
    // Category
    // -------------------------------------------------------

    if (categoryId != null && categoryId.isNotEmpty) {
      queryParameters["category_id"] = categoryId;
    }

    // -------------------------------------------------------
    // Cuisine
    // -------------------------------------------------------

    if (cuisineId != null && cuisineId.isNotEmpty) {
      queryParameters["cuisine_id"] = cuisineId;
    }

    // -------------------------------------------------------
    // Difficulty
    // -------------------------------------------------------

    if (difficultyId != null && difficultyId.isNotEmpty) {
      queryParameters["difficulty_id"] = difficultyId;
    }

    // -------------------------------------------------------
    // Food Type
    // -------------------------------------------------------

    if (foodType != null && foodType.isNotEmpty) {
      queryParameters["food_type"] = foodType.toUpperCase();
    }

    // -------------------------------------------------------
    // Request
    // -------------------------------------------------------

    final response = await dio.get(
      "/recipes/search",
      queryParameters: queryParameters,
    );

    final data = response.data as List;

    return data
        .map((item) => RecipeModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
