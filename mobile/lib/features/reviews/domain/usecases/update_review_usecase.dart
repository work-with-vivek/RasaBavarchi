import '../../data/models/review_model.dart';
import '../repositories/review_repository.dart';

class UpdateReviewUseCase {
  final ReviewRepository repository;

  UpdateReviewUseCase(this.repository);

  Future<ReviewModel> call({
    required String reviewId,
    required int rating,
    required String comment,
  }) {
    return repository.updateReview(
      reviewId: reviewId,
      rating: rating,
      comment: comment,
    );
  }
}
