import '../repositories/favorite_repository.dart';

class IsFavoriteUseCase {
  final FavoriteRepository repository;

  IsFavoriteUseCase(this.repository);

  Future<bool> call(String recipeId) {
    return repository.isFavorite(recipeId);
  }
}
