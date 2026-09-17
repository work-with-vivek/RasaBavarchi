import '../../data/models/recipe_model.dart';

abstract class RecipeDetailRepository {
  Future<RecipeModel> getRecipe(String recipeId);
}
