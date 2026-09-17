import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recipe_model.dart';
import 'recipe_provider.dart';

class RecipeNotifier extends StateNotifier<AsyncValue<List<RecipeModel>>> {
  RecipeNotifier(this.ref) : super(const AsyncLoading()) {
    loadRecipes();
  }

  final Ref ref;

  // =========================================================
  // Selected Category
  // =========================================================

  String? selectedCategoryId;

  // =========================================================
  // Selected Food Type
  // =========================================================
  //
  // null              = All
  // VEGAN             = Vegan
  // VEGETARIAN        = Vegetarian
  // NON_VEGETARIAN    = Non-Vegetarian
  // UNKNOWN           = Unknown
  //
  // Backend source of truth:
  // recipes.food_type
  // =========================================================

  String? selectedFoodType;

  // =========================================================
  // Search Query
  // =========================================================

  String _currentSearchQuery = "";

  // =========================================================
  // Load Recipes
  // =========================================================

  Future<void> loadRecipes() async {
    try {
      state = const AsyncLoading();

      final recipes = await ref
          .read(getRecipesUseCaseProvider)
          .call(categoryId: selectedCategoryId, foodType: selectedFoodType);

      state = AsyncData(recipes);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  // =========================================================
  // Select Category
  // =========================================================

  Future<void> selectCategory(String? categoryId) async {
    selectedCategoryId = categoryId;

    if (_currentSearchQuery.isEmpty) {
      await loadRecipes();
    } else {
      await searchRecipes(_currentSearchQuery);
    }
  }

  // =========================================================
  // Select Food Type
  // =========================================================

  Future<void> selectFoodType(String? foodType) async {
    selectedFoodType = foodType;

    if (_currentSearchQuery.isEmpty) {
      await loadRecipes();
    } else {
      await searchRecipes(_currentSearchQuery);
    }
  }

  // =========================================================
  // Search Recipes
  // =========================================================

  Future<void> searchRecipes(String query) async {
    final searchQuery = query.trim();

    _currentSearchQuery = searchQuery;

    if (searchQuery.isEmpty) {
      await loadRecipes();
      return;
    }

    try {
      state = const AsyncLoading();

      final recipes = await ref
          .read(searchRecipesUseCaseProvider)
          .call(
            title: searchQuery,
            categoryId: selectedCategoryId,
            foodType: selectedFoodType,
          );

      state = AsyncData(recipes);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  // =========================================================
  // Refresh
  // =========================================================

  Future<void> refresh() async {
    if (_currentSearchQuery.isEmpty) {
      await loadRecipes();
    } else {
      await searchRecipes(_currentSearchQuery);
    }
  }
}

// =========================================================
// Provider
// =========================================================

final recipeNotifierProvider =
    StateNotifierProvider<RecipeNotifier, AsyncValue<List<RecipeModel>>>(
      (ref) => RecipeNotifier(ref),
    );
