import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasource/community_remote_data_source.dart';
import '../../data/models/community_comment_model.dart';
import '../../data/models/community_post_model.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/repositories/community_repository.dart';


// =============================================================
// DEPENDENCIES
// =============================================================

final communityRemoteDataSourceProvider =
    Provider<CommunityRemoteDataSource>((ref) {
  return CommunityRemoteDataSource(ApiClient().dio);
});


final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(
    ref.read(communityRemoteDataSourceProvider),
  );
});


// =============================================================
// POSTS
// =============================================================

final communityPostsProvider =
    FutureProvider<List<CommunityPostModel>>((ref) async {
  final repository = ref.read(communityRepositoryProvider);

  return repository.getPosts();
});


final communityPostProvider = FutureProvider.family<
    CommunityPostModel,
    String>((ref, postId) async {
  final repository = ref.read(communityRepositoryProvider);

  return repository.getPost(postId);
});


// =============================================================
// COMMENTS
// =============================================================

final communityCommentsProvider = FutureProvider.family<
    List<CommunityCommentModel>,
    String>((ref, postId) async {
  final repository = ref.read(communityRepositoryProvider);

  return repository.getComments(postId);
});


// =============================================================
// COMMUNITY NOTIFIER
// =============================================================

class CommunityNotifier extends Notifier<void> {
  CommunityRepository get _repository =>
      ref.read(communityRepositoryProvider);

  @override
  void build() {}

  Future<CommunityPostModel> createPost({
    required String content,
    String? recipeId,
  }) async {
    final post = await _repository.createPost(
      content: content,
      recipeId: recipeId,
    );

    ref.invalidate(communityPostsProvider);

    return post;
  }

  Future<void> deletePost(
    String postId,
  ) async {
    await _repository.deletePost(postId);

    ref.invalidate(communityPostsProvider);
    ref.invalidate(communityPostProvider(postId));
  }

  Future<void> likePost(
    String postId,
  ) async {
    await _repository.likePost(postId);

    ref.invalidate(communityPostsProvider);
    ref.invalidate(communityPostProvider(postId));
  }

  Future<void> unlikePost(
    String postId,
  ) async {
    await _repository.unlikePost(postId);

    ref.invalidate(communityPostsProvider);
    ref.invalidate(communityPostProvider(postId));
  }

  Future<CommunityCommentModel> createComment({
    required String postId,
    required String content,
  }) async {
    final comment = await _repository.createComment(
      postId: postId,
      content: content,
    );

    ref.invalidate(communityCommentsProvider(postId));
    ref.invalidate(communityPostProvider(postId));
    ref.invalidate(communityPostsProvider);

    return comment;
  }

  Future<void> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    await _repository.deleteComment(commentId);

    ref.invalidate(communityCommentsProvider(postId));
    ref.invalidate(communityPostProvider(postId));
    ref.invalidate(communityPostsProvider);
  }
}


final communityNotifierProvider =
    NotifierProvider<CommunityNotifier, void>(
  CommunityNotifier.new,
);