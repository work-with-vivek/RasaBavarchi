import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recipe_rating_model.dart';
import '../../data/models/review_model.dart';

import 'review_provider.dart';

class ReviewState {
  final List<ReviewModel> reviews;
  final RecipeRatingModel? ratingSummary;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const ReviewState({
    this.reviews = const [],
    this.ratingSummary,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  ReviewState copyWith({
    List<ReviewModel>? reviews,
    RecipeRatingModel? ratingSummary,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      ratingSummary: ratingSummary ?? this.ratingSummary,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  ReviewNotifier(this.ref) : super(const ReviewState());

  final Ref ref;

  // ---------------------------------------------------------
  // Load Reviews + Rating
  // ---------------------------------------------------------

  Future<void> loadReviews(String recipeId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        ref.read(getReviewsUseCaseProvider).call(recipeId),
        ref.read(getRatingSummaryUseCaseProvider).call(recipeId),
      ]);

      final reviews = results[0] as List<ReviewModel>;

      final ratingSummary = results[1] as RecipeRatingModel;

      state = state.copyWith(
        reviews: reviews,
        ratingSummary: ratingSummary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------
  // Create Review
  // ---------------------------------------------------------

  Future<void> createReview({
    required String recipeId,
    required int rating,
    required String comment,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await ref
          .read(createReviewUseCaseProvider)
          .call(recipeId: recipeId, rating: rating, comment: comment);

      await loadReviews(recipeId);

      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------
  // Update Review
  // ---------------------------------------------------------

  Future<void> updateReview({
    required String recipeId,
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await ref
          .read(updateReviewUseCaseProvider)
          .call(reviewId: reviewId, rating: rating, comment: comment);

      await loadReviews(recipeId);

      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------
  // Delete Review
  // ---------------------------------------------------------

  Future<void> deleteReview({
    required String recipeId,
    required String reviewId,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await ref.read(deleteReviewUseCaseProvider).call(reviewId);

      await loadReviews(recipeId);

      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }
}

final reviewNotifierProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>(
      (ref) => ReviewNotifier(ref),
    );
