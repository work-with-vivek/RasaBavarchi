import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasource/meal_plan_remote_data_source.dart';
import '../../data/models/meal_create_request.dart';
import '../../data/models/meal_plan_model.dart';
import '../../data/models/meal_plan_request.dart';
import '../../data/models/meal_plan_update_request.dart';
import '../../data/repositories/meal_plan_repository_impl.dart';
import '../../domain/repositories/meal_plan_repository.dart';

final mealPlanRemoteDataSourceProvider = Provider<MealPlanRemoteDataSource>((
  ref,
) {
  return MealPlanRemoteDataSource(ApiClient().dio);
});

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepositoryImpl(ref.read(mealPlanRemoteDataSourceProvider));
});

// =============================================================
// ALL MEAL PLANS
// =============================================================

final mealPlansProvider = FutureProvider<List<MealPlanModel>>((ref) async {
  final repository = ref.read(mealPlanRepositoryProvider);

  return repository.getMealPlans();
});

// =============================================================
// SINGLE MEAL PLAN
// =============================================================

final mealPlanDetailProvider = FutureProvider.family<MealPlanModel?, String>((
  ref,
  mealPlanId,
) async {
  final repository = ref.read(mealPlanRepositoryProvider);

  return repository.getMealPlan(mealPlanId);
});

// =============================================================
// CREATE MEAL PLAN
// =============================================================

final createMealPlanProvider =
    Provider<Future<MealPlanModel> Function(MealPlanRequest)>((ref) {
      final repository = ref.read(mealPlanRepositoryProvider);

      return (request) async {
        final result = await repository.createMealPlan(request);

        ref.invalidate(mealPlansProvider);

        return result;
      };
    });

// =============================================================
// UPDATE MEAL PLAN
// =============================================================

final updateMealPlanProvider =
    Provider<Future<MealPlanModel> Function(String, MealPlanUpdateRequest)>((
      ref,
    ) {
      final repository = ref.read(mealPlanRepositoryProvider);

      return (String mealPlanId, MealPlanUpdateRequest request) async {
        final result = await repository.updateMealPlan(mealPlanId, request);

        ref.invalidate(mealPlansProvider);

        ref.invalidate(mealPlanDetailProvider(mealPlanId));

        return result;
      };
    });

// =============================================================
// DELETE MEAL PLAN
// =============================================================

final deleteMealPlanProvider = Provider<Future<void> Function(String)>((ref) {
  final repository = ref.read(mealPlanRepositoryProvider);

  return (String mealPlanId) async {
    await repository.deleteMealPlan(mealPlanId);

    ref.invalidate(mealPlansProvider);

    ref.invalidate(mealPlanDetailProvider(mealPlanId));
  };
});

// =============================================================
// ADD MEAL
// =============================================================

final addMealProvider =
    Provider<Future<void> Function(String, MealCreateRequest)>((ref) {
      final repository = ref.read(mealPlanRepositoryProvider);

      return (String mealPlanId, MealCreateRequest request) async {
        await repository.addMeal(mealPlanId, request);

        ref.invalidate(mealPlansProvider);

        ref.invalidate(mealPlanDetailProvider(mealPlanId));
      };
    });

// =============================================================
// DELETE MEAL
// =============================================================

final deleteMealProvider = Provider<Future<void> Function(String, String)>((
  ref,
) {
  final repository = ref.read(mealPlanRepositoryProvider);

  return (String mealPlanId, String mealId) async {
    await repository.deleteMeal(mealId);

    ref.invalidate(mealPlansProvider);

    ref.invalidate(mealPlanDetailProvider(mealPlanId));
  };
});
