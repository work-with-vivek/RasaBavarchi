import '../repositories/review_repository.dart';

class DeleteReviewUseCase {
  final ReviewRepository repository;

  DeleteReviewUseCase(this.repository);

  Future<void> call(String reviewId) {
    return repository.deleteReview(reviewId);
  }
}
