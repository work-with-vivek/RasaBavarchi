import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

import '../../data/datasource/recipe_detail_remote_data_source.dart';
import '../../data/repositories/recipe_detail_repository_impl.dart';

import '../../domain/repositories/recipe_detail_repository.dart';
import '../../domain/usecases/get_recipe_usecase.dart';

// ---------------------------------------------------------
// Dio
// ---------------------------------------------------------

final recipeDetailDioProvider = Provider((ref) => ApiClient().dio);

// ---------------------------------------------------------
// Remote Data Source
// ---------------------------------------------------------

final recipeDetailRemoteDataSourceProvider =
    Provider<RecipeDetailRemoteDataSource>((ref) {
      return RecipeDetailRemoteDataSource(ref.read(recipeDetailDioProvider));
    });

// ---------------------------------------------------------
// Repository
// ---------------------------------------------------------

final recipeDetailRepositoryProvider = Provider<RecipeDetailRepository>((ref) {
  return RecipeDetailRepositoryImpl(
    ref.read(recipeDetailRemoteDataSourceProvider),
  );
});

// ---------------------------------------------------------
// Get Recipe Use Case
// ---------------------------------------------------------

final getRecipeUseCaseProvider = Provider<GetRecipeUseCase>((ref) {
  return GetRecipeUseCase(ref.read(recipeDetailRepositoryProvider));
});
