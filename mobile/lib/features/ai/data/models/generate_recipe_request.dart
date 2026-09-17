class GenerateRecipeRequest {
  const GenerateRecipeRequest({
    required this.ingredients,
    this.cuisine,
    this.dietaryPreference,
    required this.servings,
  });

  final List<String> ingredients;
  final String? cuisine;
  final String? dietaryPreference;
  final int servings;

  Map<String, dynamic> toJson() {
    return {
      'ingredients': ingredients,
      'cuisine': cuisine,
      'dietary_preference': dietaryPreference,
      'servings': servings,
    };
  }
}
