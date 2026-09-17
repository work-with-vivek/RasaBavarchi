import '../../data/models/recipe_rating_model.dart';
import '../../data/models/review_model.dart';

abstract class ReviewRepository {
  // ---------------------------------------------------------
  // Get Reviews
  // ---------------------------------------------------------

  Future<List<ReviewModel>> getReviews(String recipeId);

  // ---------------------------------------------------------
  // Get Rating Summary
  // ---------------------------------------------------------

  Future<RecipeRatingModel> getRatingSummary(String recipeId);

  // ---------------------------------------------------------
  // Create Review
  // ---------------------------------------------------------

  Future<ReviewModel> createReview({
    required String recipeId,
    required int rating,
    required String comment,
  });

  // ---------------------------------------------------------
  // Update Review
  // ---------------------------------------------------------

  Future<ReviewModel> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  });

  // ---------------------------------------------------------
  // Delete Review
  // ---------------------------------------------------------

  Future<void> deleteReview(String reviewId);
}
