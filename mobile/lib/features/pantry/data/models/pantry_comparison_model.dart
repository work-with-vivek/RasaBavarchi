import 'package:mobile/features/recipes/data/models/recipe_model.dart';

class PantryComparisonItem {
  final RecipeIngredientModel recipeIngredient;
  final double requiredQuantity;
  final double pantryQuantity;
  final double missingQuantity;
  final String unit;
  final bool isAvailable;
  final bool hasSpecifiedQuantity;

  const PantryComparisonItem({
    required this.recipeIngredient,
    required this.requiredQuantity,
    required this.pantryQuantity,
    required this.missingQuantity,
    required this.unit,
    required this.isAvailable,
    this.hasSpecifiedQuantity = true,
  });
}
