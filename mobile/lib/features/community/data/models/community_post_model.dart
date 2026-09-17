import 'community_author_model.dart';
import 'community_comment_model.dart';

class CommunityRecipeModel {
  final String id;
  final String title;
  final String? imageUrl;

  const CommunityRecipeModel({
    required this.id,
    required this.title,
    this.imageUrl,
  });

  factory CommunityRecipeModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommunityRecipeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class CommunityPostModel {
  final String id;
  final String content;
  final CommunityAuthorModel author;
  final CommunityRecipeModel? recipe;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CommunityCommentModel> comments;

  const CommunityPostModel({
    required this.id,
    required this.content,
    required this.author,
    this.recipe,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
    this.comments = const [],
  });

  factory CommunityPostModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final commentsJson = json['comments'];

    return CommunityPostModel(
      id: json['id'] as String,
      content: json['content'] as String,
      author: CommunityAuthorModel.fromJson(
        json['author'] as Map<String, dynamic>,
      ),
      recipe: json['recipe'] != null
          ? CommunityRecipeModel.fromJson(
              json['recipe'] as Map<String, dynamic>,
            )
          : null,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String,
      ),
      comments: commentsJson is List
          ? commentsJson
              .map(
                (item) => CommunityCommentModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList()
          : const [],
    );
  }
}