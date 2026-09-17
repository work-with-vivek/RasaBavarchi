import '../../data/models/meal_nutrition_model.dart';

abstract class MealNutritionRepository {
  Future<MealNutritionModel> getMealPlanNutrition(String mealPlanId);
}
