import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/recipe_video/data/datasources/recipe_video_remote_data_source.dart';
import 'package:mobile/features/recipe_video/data/repositories/recipe_video_repository_impl.dart';
import 'package:mobile/features/recipe_video/domain/repositories/recipe_video_repository.dart';

final recipeVideoRemoteDataSourceProvider =
    Provider<RecipeVideoRemoteDataSource>((ref) {
      return RecipeVideoRemoteDataSource(ApiClient().dio);
    });

final recipeVideoRepositoryProvider = Provider<RecipeVideoRepository>((ref) {
  return RecipeVideoRepositoryImpl(
    ref.read(recipeVideoRemoteDataSourceProvider),
  );
});
