import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

import '../../data/datasource/recipe_remote_data_source.dart';
import '../../data/repositories/recipe_repository_impl.dart';

import '../../domain/repositories/recipe_repository.dart';
import '../../domain/usecases/get_recipes_usecase.dart';
import '../../domain/usecases/search_recipes_usecase.dart';

// ---------------------------------------------------------
// Dio
// ---------------------------------------------------------

final dioProvider = Provider((ref) => ApiClient().dio);

// ---------------------------------------------------------
// Remote Data Source
// ---------------------------------------------------------

final recipeRemoteDataSourceProvider = Provider<RecipeRemoteDataSource>((ref) {
  return RecipeRemoteDataSource(ref.read(dioProvider));
});

// ---------------------------------------------------------
// Repository
// ---------------------------------------------------------

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepositoryImpl(ref.read(recipeRemoteDataSourceProvider));
});

// ---------------------------------------------------------
// Get Recipes Use Case
// ---------------------------------------------------------

final getRecipesUseCaseProvider = Provider<GetRecipesUseCase>((ref) {
  return GetRecipesUseCase(ref.read(recipeRepositoryProvider));
});

// ---------------------------------------------------------
// Search Recipes Use Case
// ---------------------------------------------------------

final searchRecipesUseCaseProvider = Provider<SearchRecipesUseCase>((ref) {
  return SearchRecipesUseCase(ref.read(recipeRepositoryProvider));
});
