import 'package:dio/dio.dart';

import 'package:mobile/features/recipe_video/data/models/recipe_video_request.dart';
import 'package:mobile/features/recipe_video/data/models/recipe_video_response.dart';

class RecipeVideoRemoteDataSource {
  RecipeVideoRemoteDataSource(this._dio);

  final Dio _dio;

  Future<RecipeVideoResponse> generateVideo({
    required String recipeId,
    required RecipeVideoRequest request,
  }) async {
    final response = await _dio.post(
      '/recipes/$recipeId/explain-video',
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid recipe video response.');
    }

    return RecipeVideoResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
