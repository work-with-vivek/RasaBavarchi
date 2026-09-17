import '../repositories/favorite_repository.dart';
import '../../data/models/favorite_model.dart';

class AddFavoriteUseCase {
  final FavoriteRepository repository;

  AddFavoriteUseCase(this.repository);

  Future<FavoriteModel> call(String recipeId) {
    return repository.addFavorite(recipeId);
  }
}
