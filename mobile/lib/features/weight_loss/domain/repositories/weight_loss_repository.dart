import '../../../recipes/data/models/recipe_model.dart';
import '../../data/models/weight_loss_calculation_model.dart';
import '../../data/models/weight_loss_profile_model.dart';

abstract class WeightLossRepository {
  Future<WeightLossProfileModel?> getProfile();

  Future<WeightLossProfileModel> saveProfile({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required double goalWeightKg,
  });

  Future<WeightLossCalculationModel> getCalculation();

  Future<List<RecipeModel>> getWeightLossRecipes({
    bool? vegetarian,
    bool? vegan,
    int limit = 12,
  });
}
