import '../../domain/repositories/recipe_detail_repository.dart';
import '../datasource/recipe_detail_remote_data_source.dart';
import '../models/recipe_model.dart';

class RecipeDetailRepositoryImpl implements RecipeDetailRepository {
  final RecipeDetailRemoteDataSource remoteDataSource;

  RecipeDetailRepositoryImpl(this.remoteDataSource);

  @override
  Future<RecipeModel> getRecipe(String recipeId) {
    return remoteDataSource.getRecipe(recipeId);
  }
}
