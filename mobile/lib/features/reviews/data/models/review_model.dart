class ReviewModel {
  final String id;
  final String recipeId;
  final String userId;
  final String? userName;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReviewModel({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json["id"] as String,
      recipeId: json["recipe_id"] as String,
      userId: json["user_id"] as String,
      userName: json["user_name"] as String?,
      rating: json["rating"] as int,
      comment: json["comment"] as String?,
      createdAt: json["created_at"] != null
          ? DateTime.parse(json["created_at"] as String)
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.parse(json["updated_at"] as String)
          : null,
    );
  }
}
