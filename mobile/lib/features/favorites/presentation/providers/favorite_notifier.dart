import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/favorite_model.dart';
import 'favorite_provider.dart';

class FavoriteNotifier extends StateNotifier<AsyncValue<List<FavoriteModel>>> {
  FavoriteNotifier(this.ref) : super(const AsyncData([]));

  final Ref ref;

  // ---------------------------------------------------------
  // Load Favorites
  // ---------------------------------------------------------

  Future<void> loadFavorites() async {
    state = const AsyncLoading();

    try {
      final useCase = ref.read(getFavoritesUseCaseProvider);

      final result = await useCase();

      state = AsyncData(result.items);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  // ---------------------------------------------------------
  // Check Favorite Status
  // ---------------------------------------------------------

  Future<bool> isFavorite(String recipeId) async {
    final useCase = ref.read(isFavoriteUseCaseProvider);

    return useCase(recipeId);
  }

  // ---------------------------------------------------------
  // Add Favorite
  // ---------------------------------------------------------

  Future<FavoriteModel> addFavorite(String recipeId) async {
    final useCase = ref.read(addFavoriteUseCaseProvider);

    final favorite = await useCase(recipeId);

    final current = state.value ?? [];

    final alreadyExists = current.any((item) => item.recipeId == recipeId);

    if (!alreadyExists) {
      state = AsyncData([...current, favorite]);
    }

    return favorite;
  }

  // ---------------------------------------------------------
  // Remove Favorite
  // ---------------------------------------------------------

  Future<void> removeFavorite(String recipeId) async {
    final useCase = ref.read(removeFavoriteUseCaseProvider);

    await useCase(recipeId);

    final current = state.value ?? [];

    state = AsyncData(
      current.where((item) => item.recipeId != recipeId).toList(),
    );
  }

  // ---------------------------------------------------------
  // Toggle Favorite
  // ---------------------------------------------------------

  Future<void> toggleFavorite(String recipeId) async {
    final current = await isFavorite(recipeId);

    if (current) {
      await removeFavorite(recipeId);
    } else {
      await addFavorite(recipeId);
    }
  }
}

// ---------------------------------------------------------
// Provider
// ---------------------------------------------------------

final favoriteNotifierProvider =
    StateNotifierProvider<FavoriteNotifier, AsyncValue<List<FavoriteModel>>>(
      (ref) => FavoriteNotifier(ref),
    );
