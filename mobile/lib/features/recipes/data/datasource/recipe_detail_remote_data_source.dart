import 'package:dio/dio.dart';

import '../models/recipe_model.dart';

class RecipeDetailRemoteDataSource {
  final Dio dio;

  RecipeDetailRemoteDataSource(this.dio);

  Future<RecipeModel> getRecipe(String recipeId) async {
    final response = await dio.get("/recipes/$recipeId");

    return RecipeModel.fromJson(response.data as Map<String, dynamic>);
  }
}
