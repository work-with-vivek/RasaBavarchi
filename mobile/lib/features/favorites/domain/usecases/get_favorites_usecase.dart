import '../repositories/favorite_repository.dart';
import '../../data/models/favorite_model.dart';

class GetFavoritesUseCase {
  final FavoriteRepository repository;

  GetFavoritesUseCase(this.repository);

  Future<FavoriteListModel> call() {
    return repository.getFavorites();
  }
}
