class RecipeNutritionModel {
  final String recipeId;
  final String recipeName;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const RecipeNutritionModel({
    required this.recipeId,
    required this.recipeName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory RecipeNutritionModel.fromJson(Map<String, dynamic> json) {
    return RecipeNutritionModel(
      recipeId: json['recipe_id'] as String,
      recipeName: json['recipe_name'] as String,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
    );
  }
}
