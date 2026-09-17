import 'package:mobile/features/recipe_video/data/models/recipe_video_request.dart';
import 'package:mobile/features/recipe_video/data/models/recipe_video_response.dart';

abstract class RecipeVideoRepository {
  Future<RecipeVideoResponse> generateVideo({
    required String recipeId,
    required RecipeVideoRequest request,
  });
}
