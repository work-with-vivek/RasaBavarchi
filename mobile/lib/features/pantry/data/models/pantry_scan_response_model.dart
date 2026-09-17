class PantryScanIngredientModel {
  const PantryScanIngredientModel({required this.name});

  final String name;

  factory PantryScanIngredientModel.fromJson(Map<String, dynamic> json) {
    return PantryScanIngredientModel(name: json['name'] as String);
  }
}

class PantryScanResponseModel {
  const PantryScanResponseModel({required this.ingredients});

  final List<PantryScanIngredientModel> ingredients;

  factory PantryScanResponseModel.fromJson(Map<String, dynamic> json) {
    final ingredientsJson = json['ingredients'];

    if (ingredientsJson is! List) {
      throw const FormatException('Invalid pantry scan response.');
    }

    return PantryScanResponseModel(
      ingredients: ingredientsJson
          .map(
            (item) => PantryScanIngredientModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
