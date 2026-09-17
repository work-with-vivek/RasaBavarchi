import '../../data/models/recipe_model.dart';
import '../repositories/recipe_repository.dart';

class SearchRecipesUseCase {
  final RecipeRepository repository;

  SearchRecipesUseCase(this.repository);

  Future<List<RecipeModel>> call({
    String? title,
    String? categoryId,
    String? cuisineId,
    String? difficultyId,
    String? foodType,
    int page = 1,
    int pageSize = 10,
  }) {
    return repository.searchRecipes(
      title: title,
      categoryId: categoryId,
      cuisineId: cuisineId,
      difficultyId: difficultyId,
      foodType: foodType,
      page: page,
      pageSize: pageSize,
    );
  }
}
