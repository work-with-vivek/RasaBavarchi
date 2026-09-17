import 'package:dio/dio.dart';

import '../models/favorite_model.dart';

class FavoriteRemoteDataSource {
  final Dio dio;

  FavoriteRemoteDataSource(this.dio);

  // ---------------------------------------------------------
  // Add Favorite
  // ---------------------------------------------------------

  Future<FavoriteModel> addFavorite(String recipeId) async {
    final response = await dio.post(
      '/favorites',
      data: {'recipe_id': recipeId},
    );

    return FavoriteModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------
  // Get My Favorites
  // ---------------------------------------------------------

  Future<FavoriteListModel> getFavorites() async {
    final response = await dio.get('/favorites');

    return FavoriteListModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------
  // Check Favorite Status
  // ---------------------------------------------------------

  Future<bool> isFavorite(String recipeId) async {
    final response = await dio.get('/favorites/$recipeId');

    return (response.data as Map<String, dynamic>)['is_favorite'] as bool;
  }

  // ---------------------------------------------------------
  // Remove Favorite
  // ---------------------------------------------------------

  Future<void> removeFavorite(String recipeId) async {
    await dio.delete('/favorites/$recipeId');
  }
}
