import '../../data/models/meal_plan_nutrition_model.dart';
import '../../data/models/recipe_nutrition_model.dart';

abstract class NutritionRepository {
  Future<RecipeNutritionModel> getRecipeNutrition(String recipeId);

  Future<MealPlanNutritionModel> getMealPlanNutrition(String mealPlanId);
}
