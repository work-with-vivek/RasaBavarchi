import '../../domain/repositories/recipe_repository.dart';
import '../datasource/recipe_remote_data_source.dart';
import '../models/recipe_model.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final RecipeRemoteDataSource remoteDataSource;

  RecipeRepositoryImpl(this.remoteDataSource);

  // =========================================================
  // Get Recipes
  // =========================================================

  @override
  Future<List<RecipeModel>> getRecipes({
    int page = 1,
    int pageSize = 10,
    String? categoryId,
    String? foodType,
  }) async {
    final recipePage = await remoteDataSource.getRecipes(
      page: page,
      pageSize: pageSize,
      categoryId: categoryId,
      foodType: foodType,
    );

    return recipePage.items;
  }

  // =========================================================
  // Search Recipes
  // =========================================================

  @override
  Future<List<RecipeModel>> searchRecipes({
    String? title,
    String? categoryId,
    String? cuisineId,
    String? difficultyId,
    String? foodType,
    int page = 1,
    int pageSize = 10,
  }) async {
    return remoteDataSource.searchRecipes(
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
