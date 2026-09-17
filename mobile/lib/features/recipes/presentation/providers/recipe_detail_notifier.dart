import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recipe_model.dart';
import 'recipe_detail_provider.dart';

class RecipeDetailNotifier extends StateNotifier<AsyncValue<RecipeModel?>> {
  RecipeDetailNotifier(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<void> loadRecipe(String recipeId) async {
    state = const AsyncLoading();

    try {
      final useCase = ref.read(getRecipeUseCaseProvider);

      final recipe = await useCase(recipeId);

      state = AsyncData(recipe);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}

final recipeDetailNotifierProvider =
    StateNotifierProvider<RecipeDetailNotifier, AsyncValue<RecipeModel?>>(
      (ref) => RecipeDetailNotifier(ref),
    );
