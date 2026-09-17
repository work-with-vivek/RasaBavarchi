import 'package:mobile/features/ai/data/models/ai_recipe_model.dart';
import 'package:mobile/features/recipes/data/models/recipe_model.dart';

class AIRecipeOrderAdapter {
  const AIRecipeOrderAdapter._();

  static RecipeModel toRecipeModel(AIRecipeModel aiRecipe) {
    return RecipeModel(
      id: 'ai-recipe-${aiRecipe.recipeName.hashCode}',
      title: aiRecipe.recipeName,
      description: aiRecipe.description,
      instructions: aiRecipe.instructions.join('\n'),
      prepTime: aiRecipe.prepTimeMinutes,
      cookTime: aiRecipe.cookTimeMinutes,
      servings: aiRecipe.servings > 0 ? aiRecipe.servings : 1,
      calories: aiRecipe.nutrition.calories.toDouble(),
      protein: aiRecipe.nutrition.proteinG,
      carbs: aiRecipe.nutrition.carbsG,
      fat: aiRecipe.nutrition.fatG,
      imageUrl: null,
      isPublished: false,
      isVegetarian: false,
      isVegan: false,
      foodType: 'UNKNOWN',
      category: RecipeInfo(id: 'ai-category', name: aiRecipe.category),
      cuisine: RecipeInfo(id: 'ai-cuisine', name: aiRecipe.cuisine),
      difficulty: RecipeInfo(id: 'ai-difficulty', name: aiRecipe.difficulty),
      authorId: 'ai-generated',
      externalId: null,
      ingredients: aiRecipe.ingredients.asMap().entries.map((entry) {
        final index = entry.key;
        final ingredient = entry.value;

        final parsedQuantity = _parseQuantity(ingredient.quantity);
        final normalizedUnit = _normalizeUnit(ingredient.unit);

        return RecipeIngredientModel(
          id: 'ai-ingredient-$index-${ingredient.item.hashCode}',
          name: ingredient.item.trim(),
          quantity: parsedQuantity,
          unit: normalizedUnit,
          isOptional: false,
        );
      }).toList(),
    );
  }

  static double _parseQuantity(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return 1.0;
    }

    // Simple decimal/integer.
    final direct = double.tryParse(normalized);
    if (direct != null && direct > 0) {
      return direct;
    }

    // Fractions such as:
    // 1/2
    // 3/4
    // 2 1/2
    final mixedFraction = RegExp(
      r'^(\d+(?:\.\d+)?)\s+(\d+)\s*/\s*(\d+)$',
    ).firstMatch(normalized);

    if (mixedFraction != null) {
      final whole = double.parse(mixedFraction.group(1)!);
      final numerator = double.parse(mixedFraction.group(2)!);
      final denominator = double.parse(mixedFraction.group(3)!);

      if (denominator != 0) {
        return whole + numerator / denominator;
      }
    }

    final fraction = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(normalized);

    if (fraction != null) {
      final numerator = double.parse(fraction.group(1)!);
      final denominator = double.parse(fraction.group(2)!);

      if (denominator != 0) {
        return numerator / denominator;
      }
    }

    // Values such as "2-3".
    final range = RegExp(
      r'^(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)$',
    ).firstMatch(normalized);

    if (range != null) {
      final first = double.parse(range.group(1)!);
      final second = double.parse(range.group(2)!);

      return (first + second) / 2;
    }

    // AI quantities such as "to taste", "as needed", etc.
    // Keep a presence-based ingredient instead of dropping it.
    return 1.0;
  }

  static String _normalizeUnit(String unit) {
    final normalized = unit.trim().toLowerCase();

    if (normalized.isEmpty) {
      return 'unknown';
    }

    switch (normalized) {
      case 'gram':
      case 'grams':
      case 'g':
        return 'g';

      case 'kilogram':
      case 'kilograms':
      case 'kg':
        return 'kg';

      case 'milliliter':
      case 'milliliters':
      case 'millilitre':
      case 'millilitres':
      case 'ml':
        return 'ml';

      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
      case 'l':
        return 'l';

      case 'teaspoon':
      case 'teaspoons':
      case 'tsp':
        return 'tsp';

      case 'tablespoon':
      case 'tablespoons':
      case 'tbsp':
        return 'tbsp';

      case 'cup':
      case 'cups':
        return 'cup';

      case 'pinch':
      case 'pinches':
        return 'pinch';

      case 'piece':
      case 'pieces':
      case 'pc':
      case 'pcs':
        return 'pc';

      case 'clove':
      case 'cloves':
        return 'pc';

      default:
        return normalized;
    }
  }
}
