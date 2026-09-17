import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

import '../../data/datasource/favorite_remote_data_source.dart';
import '../../data/repositories/favorite_repository_impl.dart';

import '../../domain/repositories/favorite_repository.dart';
import '../../domain/usecases/add_favorite_usecase.dart';
import '../../domain/usecases/get_favorites_usecase.dart';
import '../../domain/usecases/is_favorite_usecase.dart';
import '../../domain/usecases/remove_favorite_usecase.dart';

// ---------------------------------------------------------
// Dio
// ---------------------------------------------------------

final favoriteDioProvider = Provider((ref) => ApiClient().dio);

// ---------------------------------------------------------
// Remote Data Source
// ---------------------------------------------------------

final favoriteRemoteDataSourceProvider = Provider<FavoriteRemoteDataSource>((
  ref,
) {
  return FavoriteRemoteDataSource(ref.read(favoriteDioProvider));
});

// ---------------------------------------------------------
// Repository
// ---------------------------------------------------------

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepositoryImpl(ref.read(favoriteRemoteDataSourceProvider));
});

// ---------------------------------------------------------
// Add Favorite
// ---------------------------------------------------------

final addFavoriteUseCaseProvider = Provider<AddFavoriteUseCase>((ref) {
  return AddFavoriteUseCase(ref.read(favoriteRepositoryProvider));
});

// ---------------------------------------------------------
// Remove Favorite
// ---------------------------------------------------------

final removeFavoriteUseCaseProvider = Provider<RemoveFavoriteUseCase>((ref) {
  return RemoveFavoriteUseCase(ref.read(favoriteRepositoryProvider));
});

// ---------------------------------------------------------
// Get Favorites
// ---------------------------------------------------------

final getFavoritesUseCaseProvider = Provider<GetFavoritesUseCase>((ref) {
  return GetFavoritesUseCase(ref.read(favoriteRepositoryProvider));
});

// ---------------------------------------------------------
// Check Favorite
// ---------------------------------------------------------

final isFavoriteUseCaseProvider = Provider<IsFavoriteUseCase>((ref) {
  return IsFavoriteUseCase(ref.read(favoriteRepositoryProvider));
});
