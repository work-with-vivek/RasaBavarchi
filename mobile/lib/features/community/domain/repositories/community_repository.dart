import '../../data/models/community_comment_model.dart';
import '../../data/models/community_post_model.dart';

abstract class CommunityRepository {
  // =========================================================
  // POSTS
  // =========================================================

  Future<List<CommunityPostModel>> getPosts({
    int limit = 20,
    int offset = 0,
  });

  Future<CommunityPostModel> getPost(
    String postId,
  );

  Future<CommunityPostModel> createPost({
    required String content,
    String? recipeId,
  });

  Future<void> deletePost(
    String postId,
  );

  // =========================================================
  // LIKES
  // =========================================================

  Future<Map<String, dynamic>> likePost(
    String postId,
  );

  Future<Map<String, dynamic>> unlikePost(
    String postId,
  );

  // =========================================================
  // COMMENTS
  // =========================================================

  Future<List<CommunityCommentModel>> getComments(
    String postId,
  );

  Future<CommunityCommentModel> createComment({
    required String postId,
    required String content,
  });

  Future<void> deleteComment(
    String commentId,
  );
}