import 'package:mobile/features/ai/data/datasource/ai_remote_data_source.dart';
import 'package:mobile/features/ai/data/models/ai_recipe_model.dart';
import 'package:mobile/features/ai/data/models/explain_recipe_request.dart';
import 'package:mobile/features/ai/data/models/explain_recipe_response.dart';
import 'package:mobile/features/ai/data/models/generate_pantry_recipe_request.dart';
import 'package:mobile/features/ai/data/models/generate_recipe_request.dart';
import 'package:mobile/features/ai/domain/repositories/ai_repository.dart';

class AIRepositoryImpl implements AIRepository {
  AIRepositoryImpl(this._remoteDataSource);

  final AIRemoteDataSource _remoteDataSource;

  @override
  Future<AIRecipeModel> generateRecipe(GenerateRecipeRequest request) {
    return _remoteDataSource.generateRecipe(request);
  }

  @override
  Future<AIRecipeModel> generateRecipeFromPantry(
    GeneratePantryRecipeRequest request,
  ) {
    return _remoteDataSource.generateRecipeFromPantry(request);
  }

  @override
  Future<ExplainRecipeResponse> explainRecipe(ExplainRecipeRequest request) {
    return _remoteDataSource.explainRecipe(request);
  }
}
