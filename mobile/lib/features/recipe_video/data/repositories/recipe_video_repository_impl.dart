import 'package:mobile/features/recipe_video/data/datasources/recipe_video_remote_data_source.dart';
import 'package:mobile/features/recipe_video/data/models/recipe_video_request.dart';
import 'package:mobile/features/recipe_video/data/models/recipe_video_response.dart';
import 'package:mobile/features/recipe_video/domain/repositories/recipe_video_repository.dart';

class RecipeVideoRepositoryImpl implements RecipeVideoRepository {
  RecipeVideoRepositoryImpl(this._remoteDataSource);

  final RecipeVideoRemoteDataSource _remoteDataSource;

  @override
  Future<RecipeVideoResponse> generateVideo({
    required String recipeId,
    required RecipeVideoRequest request,
  }) {
    return _remoteDataSource.generateVideo(
      recipeId: recipeId,
      request: request,
    );
  }
}
