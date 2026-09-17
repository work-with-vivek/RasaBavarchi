class MealCreateRequest {
  const MealCreateRequest({
    required this.recipeId,
    required this.mealDate,
    required this.mealType,
    this.notes,
  });

  final String recipeId;
  final DateTime mealDate;
  final String mealType;
  final String? notes;

  Map<String, dynamic> toJson() {
    final dateOnly =
        '${mealDate.year.toString().padLeft(4, '0')}-'
        '${mealDate.month.toString().padLeft(2, '0')}-'
        '${mealDate.day.toString().padLeft(2, '0')}';

    return {
      'recipe_id': recipeId,
      'meal_date': dateOnly,
      'meal_type': mealType,
      'notes': notes,
    };
  }
}
