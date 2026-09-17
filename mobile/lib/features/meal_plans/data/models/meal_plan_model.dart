class MealPlanModel {
  const MealPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.meals,
  });

  final String id;
  final String name;
  final String? description;
  final List<MealModel> meals;

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    final rawMeals = json['meals'];

    return MealPlanModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Meal Plan',
      description: json['description']?.toString(),
      meals: rawMeals is List
          ? rawMeals
                .whereType<Map<String, dynamic>>()
                .map(MealModel.fromJson)
                .toList()
          : const [],
    );
  }
}

class MealModel {
  const MealModel({
    required this.id,
    required this.recipeId,
    required this.mealDate,
    required this.mealType,
    required this.notes,
  });

  final String id;
  final String recipeId;
  final DateTime mealDate;
  final String mealType;
  final String? notes;

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id']?.toString() ?? '',
      recipeId: json['recipe_id']?.toString() ?? '',
      mealDate:
          DateTime.tryParse(json['meal_date']?.toString() ?? '') ??
          DateTime.now(),
      mealType: json['meal_type']?.toString() ?? 'Meal',
      notes: json['notes']?.toString(),
    );
  }
}
