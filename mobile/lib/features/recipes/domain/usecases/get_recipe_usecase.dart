import '../../data/models/recipe_model.dart';
import '../repositories/recipe_detail_repository.dart';

class GetRecipeUseCase {
  final RecipeDetailRepository repository;

  GetRecipeUseCase(this.repository);

  Future<RecipeModel> call(String recipeId) {
    return repository.getRecipe(recipeId);
  }
}
