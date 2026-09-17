import '../../data/models/favorite_model.dart';

abstract class FavoriteRepository {
  Future<FavoriteModel> addFavorite(String recipeId);

  Future<FavoriteListModel> getFavorites();

  Future<bool> isFavorite(String recipeId);

  Future<void> removeFavorite(String recipeId);
}
