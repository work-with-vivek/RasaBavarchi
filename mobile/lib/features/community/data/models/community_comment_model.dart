import 'community_author_model.dart';

class CommunityCommentModel {
  final String id;
  final String content;
  final CommunityAuthorModel author;
  final DateTime createdAt;

  const CommunityCommentModel({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  factory CommunityCommentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommunityCommentModel(
      id: json['id'] as String,
      content: json['content'] as String,
      author: CommunityAuthorModel.fromJson(
        json['author'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
    );
  }
}