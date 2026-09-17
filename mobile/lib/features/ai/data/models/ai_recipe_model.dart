class AIIngredientModel {
  final String item;
  final String quantity;
  final String unit;

  const AIIngredientModel({
    required this.item,
    required this.quantity,
    required this.unit,
  });

  factory AIIngredientModel.fromJson(Map<String, dynamic> json) {
    return AIIngredientModel(
      item: json['item'] as String,
      quantity: json['quantity'] as String,
      unit: json['unit'] as String,
    );
  }
}

class AINutritionModel {
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const AINutritionModel({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory AINutritionModel.fromJson(Map<String, dynamic> json) {
    return AINutritionModel(
      calories: (json['calories'] as num).toInt(),
      proteinG: (json['protein_g'] as num).toDouble(),
      carbsG: (json['carbs_g'] as num).toDouble(),
      fatG: (json['fat_g'] as num).toDouble(),
    );
  }
}

class AIRecipeModel {
  final String recipeName;
  final String description;
  final String category;
  final String cuisine;
  final String difficulty;
  final List<AIIngredientModel> ingredients;
  final List<String> instructions;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final AINutritionModel nutrition;

  const AIRecipeModel({
    required this.recipeName,
    required this.description,
    required this.category,
    required this.cuisine,
    required this.difficulty,
    required this.ingredients,
    required this.instructions,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.nutrition,
  });

  factory AIRecipeModel.fromJson(Map<String, dynamic> json) {
    final ingredientsJson = json['ingredients'] as List<dynamic>? ?? [];

    final instructionsJson = json['instructions'] as List<dynamic>? ?? [];

    return AIRecipeModel(
      recipeName: json['recipe_name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      cuisine: json['cuisine'] as String,
      difficulty: json['difficulty'] as String,
      ingredients: ingredientsJson
          .map(
            (item) => AIIngredientModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      instructions: instructionsJson.map((item) => item.toString()).toList(),
      prepTimeMinutes: (json['prep_time_minutes'] as num).toInt(),
      cookTimeMinutes: (json['cook_time_minutes'] as num).toInt(),
      servings: (json['servings'] as num).toInt(),
      nutrition: AINutritionModel.fromJson(
        json['nutrition'] as Map<String, dynamic>,
      ),
    );
  }
}
