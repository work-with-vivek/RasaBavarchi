import '../../domain/repositories/favorite_repository.dart';
import '../datasource/favorite_remote_data_source.dart';
import '../models/favorite_model.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteRemoteDataSource remoteDataSource;

  FavoriteRepositoryImpl(this.remoteDataSource);

  @override
  Future<FavoriteModel> addFavorite(String recipeId) {
    return remoteDataSource.addFavorite(recipeId);
  }

  @override
  Future<FavoriteListModel> getFavorites() {
    return remoteDataSource.getFavorites();
  }

  @override
  Future<bool> isFavorite(String recipeId) {
    return remoteDataSource.isFavorite(recipeId);
  }

  @override
  Future<void> removeFavorite(String recipeId) {
    return remoteDataSource.removeFavorite(recipeId);
  }
}
