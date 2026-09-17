import '../../data/datasource/meal_plan_remote_data_source.dart';
import '../../data/models/meal_create_request.dart';
import '../../data/models/meal_plan_model.dart';
import '../../data/models/meal_plan_request.dart';
import '../../data/models/meal_plan_update_request.dart';
import '../../domain/repositories/meal_plan_repository.dart';

class MealPlanRepositoryImpl implements MealPlanRepository {
  MealPlanRepositoryImpl(this._remoteDataSource);

  final MealPlanRemoteDataSource _remoteDataSource;

  @override
  Future<List<MealPlanModel>> getMealPlans() {
    return _remoteDataSource.getMealPlans();
  }

  @override
  Future<MealPlanModel?> getMealPlan(String mealPlanId) {
    return _remoteDataSource.getMealPlan(mealPlanId);
  }

  @override
  Future<MealPlanModel> createMealPlan(MealPlanRequest request) {
    return _remoteDataSource.createMealPlan(request);
  }

  @override
  Future<MealPlanModel> updateMealPlan(
    String mealPlanId,
    MealPlanUpdateRequest request,
  ) {
    return _remoteDataSource.updateMealPlan(mealPlanId, request);
  }

  @override
  Future<void> deleteMealPlan(String mealPlanId) {
    return _remoteDataSource.deleteMealPlan(mealPlanId);
  }

  @override
  Future<void> addMeal(String mealPlanId, MealCreateRequest request) {
    return _remoteDataSource.addMeal(mealPlanId, request);
  }

  @override
  Future<void> deleteMeal(String mealId) {
    return _remoteDataSource.deleteMeal(mealId);
  }
}
