import '../../data/models/recipe_model.dart';
import '../repositories/recipe_repository.dart';

class GetRecipesUseCase {
  final RecipeRepository repository;

  GetRecipesUseCase(this.repository);

  Future<List<RecipeModel>> call({
    int page = 1,
    int pageSize = 10,
    String? categoryId,
    String? foodType,
  }) {
    return repository.getRecipes(
      page: page,
      pageSize: pageSize,
      categoryId: categoryId,
      foodType: foodType,
    );
  }
}
