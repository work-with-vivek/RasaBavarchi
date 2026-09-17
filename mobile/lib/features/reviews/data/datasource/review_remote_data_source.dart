import 'package:dio/dio.dart';

import '../models/recipe_rating_model.dart';
import '../models/review_model.dart';

class ReviewRemoteDataSource {
  final Dio dio;

  ReviewRemoteDataSource(this.dio);

  // ---------------------------------------------------------
  // Get Reviews
  // ---------------------------------------------------------

  Future<List<ReviewModel>> getReviews(String recipeId) async {
    final response = await dio.get("/reviews/recipes/$recipeId");

    final data = response.data as List;

    return data
        .map((item) => ReviewModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------
  // Get Rating Summary
  // ---------------------------------------------------------

  Future<RecipeRatingModel> getRatingSummary(String recipeId) async {
    final response = await dio.get("/reviews/recipes/$recipeId/rating");

    return RecipeRatingModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------
  // Create Review
  // ---------------------------------------------------------

  Future<ReviewModel> createReview({
    required String recipeId,
    required int rating,
    required String comment,
  }) async {
    final response = await dio.post(
      "/reviews/recipes/$recipeId",
      data: {"recipe_id": recipeId, "rating": rating, "comment": comment},
    );

    return ReviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------
  // Update Review
  // ---------------------------------------------------------

  Future<ReviewModel> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    final response = await dio.put(
      "/reviews/$reviewId",
      data: {"rating": rating, "comment": comment},
    );

    return ReviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------
  // Delete Review
  // ---------------------------------------------------------

  Future<void> deleteReview(String reviewId) async {
    await dio.delete("/reviews/$reviewId");
  }
}
