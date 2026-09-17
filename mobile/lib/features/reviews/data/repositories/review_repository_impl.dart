import '../../domain/repositories/review_repository.dart';
import '../datasource/review_remote_data_source.dart';
import '../models/recipe_rating_model.dart';
import '../models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;

  ReviewRepositoryImpl(this.remoteDataSource);

  // ---------------------------------------------------------
  // Get Reviews
  // ---------------------------------------------------------

  @override
  Future<List<ReviewModel>> getReviews(String recipeId) {
    return remoteDataSource.getReviews(recipeId);
  }

  // ---------------------------------------------------------
  // Get Rating Summary
  // ---------------------------------------------------------

  @override
  Future<RecipeRatingModel> getRatingSummary(String recipeId) {
    return remoteDataSource.getRatingSummary(recipeId);
  }

  // ---------------------------------------------------------
  // Create Review
  // ---------------------------------------------------------

  @override
  Future<ReviewModel> createReview({
    required String recipeId,
    required int rating,
    required String comment,
  }) {
    return remoteDataSource.createReview(
      recipeId: recipeId,
      rating: rating,
      comment: comment,
    );
  }

  // ---------------------------------------------------------
  // Update Review
  // ---------------------------------------------------------

  @override
  Future<ReviewModel> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) {
    return remoteDataSource.updateReview(
      reviewId: reviewId,
      rating: rating,
      comment: comment,
    );
  }

  // ---------------------------------------------------------
  // Delete Review
  // ---------------------------------------------------------

  @override
  Future<void> deleteReview(String reviewId) {
    return remoteDataSource.deleteReview(reviewId);
  }
}
