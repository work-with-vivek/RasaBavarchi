import '../datasource/nutrition_remote_data_source.dart';
import '../models/meal_plan_nutrition_model.dart';
import '../models/recipe_nutrition_model.dart';
import '../../domain/repositories/nutrition_repository.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  NutritionRepositoryImpl(this._remoteDataSource);

  final NutritionRemoteDataSource _remoteDataSource;

  @override
  Future<RecipeNutritionModel> getRecipeNutrition(String recipeId) {
    return _remoteDataSource.getRecipeNutrition(recipeId);
  }

  @override
  Future<MealPlanNutritionModel> getMealPlanNutrition(String mealPlanId) {
    return _remoteDataSource.getMealPlanNutrition(mealPlanId);
  }
}
