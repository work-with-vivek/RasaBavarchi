class RecipeRatingModel {
  final double averageRating;
  final int totalReviews;

  const RecipeRatingModel({
    required this.averageRating,
    required this.totalReviews,
  });

  factory RecipeRatingModel.fromJson(Map<String, dynamic> json) {
    return RecipeRatingModel(
      averageRating: (json["average_rating"] as num).toDouble(),
      totalReviews: json["total_reviews"] as int,
    );
  }
}
