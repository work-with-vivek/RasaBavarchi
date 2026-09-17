import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../recipes/data/models/recipe_model.dart';
import '../../data/datasource/weight_loss_remote_data_source.dart';
import '../../data/models/weight_loss_calculation_model.dart';
import '../../data/models/weight_loss_profile_model.dart';
import '../../data/repositories/weight_loss_repository_impl.dart';
import '../../domain/repositories/weight_loss_repository.dart';

final weightLossRemoteDataSourceProvider = Provider<WeightLossRemoteDataSource>(
  (ref) {
    return WeightLossRemoteDataSource(ApiClient().dio);
  },
);

final weightLossRepositoryProvider = Provider<WeightLossRepository>((ref) {
  return WeightLossRepositoryImpl(ref.read(weightLossRemoteDataSourceProvider));
});

final weightLossProfileProvider = FutureProvider<WeightLossProfileModel?>((
  ref,
) async {
  final repository = ref.read(weightLossRepositoryProvider);

  return repository.getProfile();
});

final weightLossCalculationProvider =
    FutureProvider<WeightLossCalculationModel>((ref) async {
      final repository = ref.read(weightLossRepositoryProvider);

      return repository.getCalculation();
    });

final weightLossRecipesProvider =
    FutureProvider.family<List<RecipeModel>, ({bool? vegetarian, bool? vegan})>(
      (ref, filters) async {
        final repository = ref.read(weightLossRepositoryProvider);

        return repository.getWeightLossRecipes(
          vegetarian: filters.vegetarian,
          vegan: filters.vegan,
          limit: 12,
        );
      },
    );
