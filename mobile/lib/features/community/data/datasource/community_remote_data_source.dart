import 'package:dio/dio.dart';

class CommunityRemoteDataSource {
  final Dio _dio;

  CommunityRemoteDataSource(this._dio);

  // =========================================================
  // POSTS
  // =========================================================

  Future<List<dynamic>> getPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/community/posts',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    if (response.data is! List) {
      throw Exception('Invalid community posts response.');
    }

    return response.data as List;
  }

  Future<Map<String, dynamic>> getPost(
    String postId,
  ) async {
    final response = await _dio.get(
      '/community/posts/$postId',
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid community post response.');
    }

    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPost({
    required String content,
    String? recipeId,
  }) async {
    final data = <String, dynamic>{
      'content': content,
    };

    if (recipeId != null) {
      data['recipe_id'] = recipeId;
    }

    final response = await _dio.post(
      '/community/posts',
      data: data,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid create post response.');
    }

    return response.data as Map<String, dynamic>;
  }

  Future<void> deletePost(
    String postId,
  ) async {
    await _dio.delete(
      '/community/posts/$postId',
    );
  }

  // =========================================================
  // LIKES
  // =========================================================

  Future<Map<String, dynamic>> likePost(
    String postId,
  ) async {
    final response = await _dio.post(
      '/community/posts/$postId/like',
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid like response.');
    }

    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlikePost(
    String postId,
  ) async {
    final response = await _dio.delete(
      '/community/posts/$postId/like',
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid unlike response.');
    }

    return response.data as Map<String, dynamic>;
  }

  // =========================================================
  // COMMENTS
  // =========================================================

  Future<List<dynamic>> getComments(
    String postId,
  ) async {
    final response = await _dio.get(
      '/community/posts/$postId/comments',
    );

    if (response.data is! List) {
      throw Exception('Invalid community comments response.');
    }

    return response.data as List;
  }

  Future<Map<String, dynamic>> createComment({
    required String postId,
    required String content,
  }) async {
    final response = await _dio.post(
      '/community/posts/$postId/comments',
      data: {
        'content': content,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid create comment response.');
    }

    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteComment(
    String commentId,
  ) async {
    await _dio.delete(
      '/community/comments/$commentId',
    );
  }
}