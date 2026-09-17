import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasource/meal_nutrition_remote_data_source.dart';
import '../../data/models/meal_nutrition_model.dart';
import '../../data/repositories/meal_nutrition_repository_impl.dart';
import '../../domain/repositories/meal_nutrition_repository.dart';

final mealNutritionDioProvider = Provider((ref) {
  return ApiClient().dio;
});

final mealNutritionRemoteDataSourceProvider =
    Provider<MealNutritionRemoteDataSource>((ref) {
      return MealNutritionRemoteDataSource(ref.read(mealNutritionDioProvider));
    });

final mealNutritionRepositoryProvider = Provider<MealNutritionRepository>((
  ref,
) {
  return MealNutritionRepositoryImpl(
    ref.read(mealNutritionRemoteDataSourceProvider),
  );
});

final mealPlanNutritionProvider =
    FutureProvider.family<MealNutritionModel, String>((ref, mealPlanId) async {
      final repository = ref.read(mealNutritionRepositoryProvider);

      return repository.getMealPlanNutrition(mealPlanId);
    });
