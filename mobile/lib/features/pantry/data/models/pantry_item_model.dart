class PantryIngredientModel {
  final String id;
  final String name;

  const PantryIngredientModel({required this.id, required this.name});

  factory PantryIngredientModel.fromJson(Map<String, dynamic> json) {
    return PantryIngredientModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class PantryUnitModel {
  final String id;
  final String name;
  final String symbol;

  const PantryUnitModel({
    required this.id,
    required this.name,
    required this.symbol,
  });

  factory PantryUnitModel.fromJson(Map<String, dynamic> json) {
    return PantryUnitModel(
      id: json['id'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
    );
  }
}

class PantryItemModel {
  final String id;
  final PantryIngredientModel ingredient;
  final double quantity;
  final PantryUnitModel unit;
  final DateTime? expiresAt;

  const PantryItemModel({
    required this.id,
    required this.ingredient,
    required this.quantity,
    required this.unit,
    required this.expiresAt,
  });

  factory PantryItemModel.fromJson(Map<String, dynamic> json) {
    final ingredientJson = json['ingredient'] as Map<String, dynamic>;

    final unitJson = json['unit'] as Map<String, dynamic>;

    return PantryItemModel(
      id: json['id'] as String,
      ingredient: PantryIngredientModel.fromJson(ingredientJson),
      quantity: (json['quantity'] as num).toDouble(),
      unit: PantryUnitModel.fromJson(unitJson),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
    );
  }
}
