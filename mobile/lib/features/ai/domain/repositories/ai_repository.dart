import 'package:mobile/features/ai/data/models/ai_recipe_model.dart';
import 'package:mobile/features/ai/data/models/explain_recipe_request.dart';
import 'package:mobile/features/ai/data/models/explain_recipe_response.dart';
import 'package:mobile/features/ai/data/models/generate_pantry_recipe_request.dart';
import 'package:mobile/features/ai/data/models/generate_recipe_request.dart';

abstract class AIRepository {
  Future<AIRecipeModel> generateRecipe(GenerateRecipeRequest request);

  Future<AIRecipeModel> generateRecipeFromPantry(
    GeneratePantryRecipeRequest request,
  );

  Future<ExplainRecipeResponse> explainRecipe(ExplainRecipeRequest request);
}
