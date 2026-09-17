import '../../../../core/constants/api_constants.dart';

// =============================================================
// RECIPE INFO
// =============================================================

class RecipeInfo {
  final String id;
  final String name;

  const RecipeInfo({required this.id, required this.name});

  factory RecipeInfo.fromJson(Map<String, dynamic> json) {
    return RecipeInfo(id: json['id'] as String, name: json['name'] as String);
  }
}

// =============================================================
// RECIPE INGREDIENT
// =============================================================

class RecipeIngredientModel {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final bool isOptional;

  const RecipeIngredientModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isOptional,
  });

  // -----------------------------------------------------------
  // MEASUREMENT HELPERS
  // -----------------------------------------------------------

  /// The current recipe dataset does not contain real
  /// measurements for many ingredients.
  ///
  /// The backend represents an unavailable measurement with
  /// the unit symbol `unk`.
  bool get hasSpecifiedQuantity {
    final normalizedUnit = unit.trim().toLowerCase();

    return normalizedUnit.isNotEmpty &&
        normalizedUnit != 'unk' &&
        normalizedUnit != 'unknown';
  }

  /// Returns a clean quantity for display.
  ///
  /// Example:
  /// 1.0  -> "1"
  /// 1.50 -> "1.5"
  /// 2.25 -> "2.25"
  String get displayQuantity {
    if (!hasSpecifiedQuantity) {
      return 'Quantity not specified';
    }

    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  /// Returns the complete human-readable measurement.
  ///
  /// Example:
  /// "250 g"
  /// "2 tbsp"
  /// "Quantity not specified"
  String get displayMeasurement {
    if (!hasSpecifiedQuantity) {
      return 'Quantity not specified';
    }

    return '$displayQuantity $unit';
  }

  // -----------------------------------------------------------
  // JSON -> MODEL
  // -----------------------------------------------------------

  factory RecipeIngredientModel.fromJson(Map<String, dynamic> json) {
    final ingredient = json['ingredient'] as Map<String, dynamic>;

    final unit = json['unit'] as Map<String, dynamic>;

    return RecipeIngredientModel(
      id: json['id'] as String,
      name: ingredient['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: unit['symbol'] as String,
      isOptional: json['is_optional'] as bool,
    );
  }
}

// =============================================================
// RECIPE MODEL
// =============================================================

class RecipeModel {
  // -----------------------------------------------------------
  // BASIC
  // -----------------------------------------------------------

  final String id;
  final String title;
  final String description;
  final String instructions;

  // -----------------------------------------------------------
  // TIME / SERVINGS
  // -----------------------------------------------------------

  final int prepTime;
  final int cookTime;
  final int servings;

  // -----------------------------------------------------------
  // NUTRITION
  // -----------------------------------------------------------

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  // -----------------------------------------------------------
  // IMAGE
  // -----------------------------------------------------------

  final String? imageUrl;

  // -----------------------------------------------------------
  // PUBLISHING
  // -----------------------------------------------------------

  final bool isPublished;

  // -----------------------------------------------------------
  // LEGACY FOOD FLAGS
  // -----------------------------------------------------------

  final bool isVegetarian;
  final bool isVegan;

  // -----------------------------------------------------------
  // FOOD TYPE
  // -----------------------------------------------------------

  final String foodType;

  // -----------------------------------------------------------
  // CATEGORY / CUISINE / DIFFICULTY
  // -----------------------------------------------------------

  final RecipeInfo category;
  final RecipeInfo cuisine;
  final RecipeInfo difficulty;

  // -----------------------------------------------------------
  // AUTHOR / EXTERNAL ID
  // -----------------------------------------------------------

  final String authorId;
  final int? externalId;

  // -----------------------------------------------------------
  // INGREDIENTS
  // -----------------------------------------------------------

  final List<RecipeIngredientModel> ingredients;

  // ===========================================================
  // CONSTRUCTOR
  // ===========================================================

  const RecipeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.imageUrl,
    required this.isPublished,
    required this.isVegetarian,
    required this.isVegan,
    required this.foodType,
    required this.category,
    required this.cuisine,
    required this.difficulty,
    required this.authorId,
    required this.externalId,
    required this.ingredients,
  });

  // ===========================================================
  // FOOD TYPE HELPERS
  // ===========================================================

  bool get isVeganType => foodType == 'VEGAN';

  bool get isVegetarianType => foodType == 'VEGETARIAN';

  bool get isNonVegetarian => foodType == 'NON_VEGETARIAN';

  bool get isUnknown => foodType == 'UNKNOWN';

  bool get isVeg => isVeganType || isVegetarianType;

  // ===========================================================
  // IMAGE URL RESOLVER
  // ===========================================================

  static String? _resolveImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return null;
    }

    final value = imageUrl.trim();

    // Already an absolute URL.
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    // Convert relative backend path to absolute API URL.
    final normalizedPath = value.startsWith('/') ? value : '/$value';

    return '${ApiConstants.baseUrl}$normalizedPath';
  }

  // ===========================================================
  // JSON -> MODEL
  // ===========================================================

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      // -------------------------------------------------------
      // BASIC
      // -------------------------------------------------------

      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      instructions: json['instructions'] as String,

      // -------------------------------------------------------
      // TIME / SERVINGS
      // -------------------------------------------------------
      prepTime: json['prep_time'] as int,
      cookTime: json['cook_time'] as int,
      servings: json['servings'] as int,

      // -------------------------------------------------------
      // NUTRITION
      // -------------------------------------------------------
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein_g'] as num).toDouble(),
      carbs: (json['carbs_g'] as num).toDouble(),
      fat: (json['fat_g'] as num).toDouble(),

      // -------------------------------------------------------
      // IMAGE
      // -------------------------------------------------------
      imageUrl: _resolveImageUrl(json['image_url'] as String?),

      // -------------------------------------------------------
      // PUBLISHING
      // -------------------------------------------------------
      isPublished: json['is_published'] as bool,

      // -------------------------------------------------------
      // LEGACY FOOD FLAGS
      // -------------------------------------------------------
      isVegetarian: json['is_vegetarian'] as bool,
      isVegan: json['is_vegan'] as bool,

      // -------------------------------------------------------
      // FOOD TYPE
      // -------------------------------------------------------
      foodType: (json['food_type'] as String? ?? 'UNKNOWN').toUpperCase(),

      // -------------------------------------------------------
      // CATEGORY
      // -------------------------------------------------------
      category: RecipeInfo.fromJson(json['category'] as Map<String, dynamic>),

      // -------------------------------------------------------
      // CUISINE
      // -------------------------------------------------------
      cuisine: RecipeInfo.fromJson(json['cuisine'] as Map<String, dynamic>),

      // -------------------------------------------------------
      // DIFFICULTY
      // -------------------------------------------------------
      difficulty: RecipeInfo.fromJson(
        json['difficulty'] as Map<String, dynamic>,
      ),

      // -------------------------------------------------------
      // AUTHOR
      // -------------------------------------------------------
      authorId: json['author_id'] as String,

      // -------------------------------------------------------
      // EXTERNAL ID
      // -------------------------------------------------------
      externalId: json['external_id'] as int?,

      // -------------------------------------------------------
      // INGREDIENTS
      // -------------------------------------------------------
      ingredients: (json['ingredients'] as List)
          .map(
            (item) =>
                RecipeIngredientModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
