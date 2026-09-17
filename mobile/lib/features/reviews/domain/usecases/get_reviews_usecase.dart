import '../../data/models/review_model.dart';
import '../repositories/review_repository.dart';

class GetReviewsUseCase {
  final ReviewRepository repository;

  GetReviewsUseCase(this.repository);

  Future<List<ReviewModel>> call(String recipeId) {
    return repository.getReviews(recipeId);
  }
}
