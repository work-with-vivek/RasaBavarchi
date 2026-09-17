import '../../data/models/recipe_model.dart';

abstract class RecipeRepository {
  // ---------------------------------------------------------
  // Get Recipes
  // ---------------------------------------------------------

  Future<List<RecipeModel>> getRecipes({
    int page = 1,
    int pageSize = 10,
    String? categoryId,
    String? foodType,
  });

  // ---------------------------------------------------------
  // Search Recipes
  // ---------------------------------------------------------

  Future<List<RecipeModel>> searchRecipes({
    String? title,
    String? categoryId,
    String? cuisineId,
    String? difficultyId,
    String? foodType,
    int page = 1,
    int pageSize = 10,
  });
}
