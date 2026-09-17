import '../datasource/community_remote_data_source.dart';
import '../models/community_comment_model.dart';
import '../models/community_post_model.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDataSource _remoteDataSource;

  CommunityRepositoryImpl(this._remoteDataSource);

  // =========================================================
  // POSTS
  // =========================================================

  @override
  Future<List<CommunityPostModel>> getPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _remoteDataSource.getPosts(
      limit: limit,
      offset: offset,
    );

    return response
        .map(
          (item) => CommunityPostModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<CommunityPostModel> getPost(
    String postId,
  ) async {
    final response = await _remoteDataSource.getPost(postId);

    return CommunityPostModel.fromJson(response);
  }

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    String? recipeId,
  }) async {
    final response = await _remoteDataSource.createPost(
      content: content,
      recipeId: recipeId,
    );

    return CommunityPostModel.fromJson(response);
  }

  @override
  Future<void> deletePost(
    String postId,
  ) async {
    await _remoteDataSource.deletePost(postId);
  }

  // =========================================================
  // LIKES
  // =========================================================

  @override
  Future<Map<String, dynamic>> likePost(
    String postId,
  ) async {
    return _remoteDataSource.likePost(postId);
  }

  @override
  Future<Map<String, dynamic>> unlikePost(
    String postId,
  ) async {
    return _remoteDataSource.unlikePost(postId);
  }

  // =========================================================
  // COMMENTS
  // =========================================================

  @override
  Future<List<CommunityCommentModel>> getComments(
    String postId,
  ) async {
    final response = await _remoteDataSource.getComments(postId);

    return response
        .map(
          (item) => CommunityCommentModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<CommunityCommentModel> createComment({
    required String postId,
    required String content,
  }) async {
    final response = await _remoteDataSource.createComment(
      postId: postId,
      content: content,
    );

    return CommunityCommentModel.fromJson(response);
  }

  @override
  Future<void> deleteComment(
    String commentId,
  ) async {
    await _remoteDataSource.deleteComment(commentId);
  }
}