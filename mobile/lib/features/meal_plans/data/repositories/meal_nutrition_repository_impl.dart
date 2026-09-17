import '../../domain/repositories/meal_nutrition_repository.dart';
import '../datasource/meal_nutrition_remote_data_source.dart';
import '../models/meal_nutrition_model.dart';

class MealNutritionRepositoryImpl implements MealNutritionRepository {
  MealNutritionRepositoryImpl(this._remoteDataSource);

  final MealNutritionRemoteDataSource _remoteDataSource;

  @override
  Future<MealNutritionModel> getMealPlanNutrition(String mealPlanId) {
    return _remoteDataSource.getMealPlanNutrition(mealPlanId);
  }
}
