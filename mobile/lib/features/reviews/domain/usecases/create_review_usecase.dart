import '../../data/models/review_model.dart';
import '../repositories/review_repository.dart';

class CreateReviewUseCase {
  final ReviewRepository repository;

  CreateReviewUseCase(this.repository);

  Future<ReviewModel> call({
    required String recipeId,
    required int rating,
    required String comment,
  }) {
    return repository.createReview(
      recipeId: recipeId,
      rating: rating,
      comment: comment,
    );
  }
}
