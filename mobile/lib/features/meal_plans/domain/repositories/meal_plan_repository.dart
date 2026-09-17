import '../../data/models/meal_create_request.dart';
import '../../data/models/meal_plan_model.dart';
import '../../data/models/meal_plan_request.dart';
import '../../data/models/meal_plan_update_request.dart';

abstract class MealPlanRepository {
  Future<List<MealPlanModel>> getMealPlans();

  Future<MealPlanModel?> getMealPlan(String mealPlanId);

  Future<MealPlanModel> createMealPlan(MealPlanRequest request);

  Future<MealPlanModel> updateMealPlan(
    String mealPlanId,
    MealPlanUpdateRequest request,
  );

  Future<void> deleteMealPlan(String mealPlanId);

  Future<void> addMeal(String mealPlanId, MealCreateRequest request);

  Future<void> deleteMeal(String mealId);
}
