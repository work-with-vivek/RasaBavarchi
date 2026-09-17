import '../../data/models/recipe_rating_model.dart';
import '../repositories/review_repository.dart';

class GetRatingSummaryUseCase {
  final ReviewRepository repository;

  GetRatingSummaryUseCase(this.repository);

  Future<RecipeRatingModel> call(String recipeId) {
    return repository.getRatingSummary(recipeId);
  }
}
