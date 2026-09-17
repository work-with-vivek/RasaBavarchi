class FavoriteModel {
  final String id;
  final String userId;
  final String recipeId;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.recipeId,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json["id"] as String,
      userId: json["user_id"] as String,
      recipeId: json["recipe_id"] as String,
    );
  }
}

class FavoriteListModel {
  final List<FavoriteModel> items;
  final int total;

  const FavoriteListModel({required this.items, required this.total});

  factory FavoriteListModel.fromJson(Map<String, dynamic> json) {
    return FavoriteListModel(
      items: (json["items"] as List)
          .map((item) => FavoriteModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json["total"] as int,
    );
  }
}
