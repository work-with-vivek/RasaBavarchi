class GeneratePantryRecipeRequest {
  final List<String>? pantryItemIds;
  final String? cuisine;
  final String? dietaryPreference;
  final int servings;

  const GeneratePantryRecipeRequest({
    this.pantryItemIds,
    this.cuisine,
    this.dietaryPreference,
    required this.servings,
  });

  Map<String, dynamic> toJson() {
    return {
      if (pantryItemIds != null && pantryItemIds!.isNotEmpty)
        'pantry_item_ids': pantryItemIds,
      if (cuisine != null && cuisine!.trim().isNotEmpty)
        'cuisine': cuisine!.trim(),
      if (dietaryPreference != null && dietaryPreference!.trim().isNotEmpty)
        'dietary_preference': dietaryPreference!.trim(),
      'servings': servings,
    };
  }
}
