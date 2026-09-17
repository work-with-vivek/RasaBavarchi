import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

import '../../data/datasource/review_remote_data_source.dart';
import '../../data/repositories/review_repository_impl.dart';

import '../../domain/repositories/review_repository.dart';

import '../../domain/usecases/create_review_usecase.dart';
import '../../domain/usecases/delete_review_usecase.dart';
import '../../domain/usecases/get_rating_summary_usecase.dart';
import '../../domain/usecases/get_reviews_usecase.dart';
import '../../domain/usecases/update_review_usecase.dart';

// ---------------------------------------------------------
// Dio
// ---------------------------------------------------------

final reviewDioProvider = Provider((ref) {
  return ApiClient().dio;
});

// ---------------------------------------------------------
// Remote Data Source
// ---------------------------------------------------------

final reviewRemoteDataSourceProvider = Provider<ReviewRemoteDataSource>((ref) {
  return ReviewRemoteDataSource(ref.read(reviewDioProvider));
});

// ---------------------------------------------------------
// Repository
// ---------------------------------------------------------

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.read(reviewRemoteDataSourceProvider));
});

// ---------------------------------------------------------
// Get Reviews
// ---------------------------------------------------------

final getReviewsUseCaseProvider = Provider<GetReviewsUseCase>((ref) {
  return GetReviewsUseCase(ref.read(reviewRepositoryProvider));
});

// ---------------------------------------------------------
// Get Rating Summary
// ---------------------------------------------------------

final getRatingSummaryUseCaseProvider = Provider<GetRatingSummaryUseCase>((
  ref,
) {
  return GetRatingSummaryUseCase(ref.read(reviewRepositoryProvider));
});

// ---------------------------------------------------------
// Create Review
// ---------------------------------------------------------

final createReviewUseCaseProvider = Provider<CreateReviewUseCase>((ref) {
  return CreateReviewUseCase(ref.read(reviewRepositoryProvider));
});

// ---------------------------------------------------------
// Update Review
// ---------------------------------------------------------

final updateReviewUseCaseProvider = Provider<UpdateReviewUseCase>((ref) {
  return UpdateReviewUseCase(ref.read(reviewRepositoryProvider));
});

// ---------------------------------------------------------
// Delete Review
// ---------------------------------------------------------

final deleteReviewUseCaseProvider = Provider<DeleteReviewUseCase>((ref) {
  return DeleteReviewUseCase(ref.read(reviewRepositoryProvider));
});
