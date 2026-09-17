import '../../../recipes/data/models/recipe_model.dart';
import '../../domain/repositories/weight_loss_repository.dart';
import '../datasource/weight_loss_remote_data_source.dart';
import '../models/weight_loss_calculation_model.dart';
import '../models/weight_loss_profile_model.dart';

class WeightLossRepositoryImpl implements WeightLossRepository {
  WeightLossRepositoryImpl(this._remoteDataSource);

  final WeightLossRemoteDataSource _remoteDataSource;

  @override
  Future<WeightLossProfileModel?> getProfile() {
    return _remoteDataSource.getProfile();
  }

  @override
  Future<WeightLossProfileModel> saveProfile({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required double goalWeightKg,
  }) {
    return _remoteDataSource.saveProfile(
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      goalWeightKg: goalWeightKg,
    );
  }

  @override
  Future<WeightLossCalculationModel> getCalculation() {
    return _remoteDataSource.getCalculation();
  }

  @override
  Future<List<RecipeModel>> getWeightLossRecipes({
    bool? vegetarian,
    bool? vegan,
    int limit = 12,
  }) {
    return _remoteDataSource.getWeightLossRecipes(
      vegetarian: vegetarian,
      vegan: vegan,
      limit: limit,
    );
  }
}
