class NutritionSummaryModel {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionSummaryModel({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionSummaryModel.fromJson(Map<String, dynamic> json) {
    return NutritionSummaryModel(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fat: (json['fat_g'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MealNutritionModel {
  final NutritionSummaryModel breakfast;
  final NutritionSummaryModel lunch;
  final NutritionSummaryModel dinner;
  final NutritionSummaryModel snack;
  final NutritionSummaryModel total;

  const MealNutritionModel({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
    required this.total,
  });

  factory MealNutritionModel.fromJson(Map<String, dynamic> json) {
    return MealNutritionModel(
      breakfast: NutritionSummaryModel.fromJson(
        json['breakfast'] as Map<String, dynamic>,
      ),
      lunch: NutritionSummaryModel.fromJson(
        json['lunch'] as Map<String, dynamic>,
      ),
      dinner: NutritionSummaryModel.fromJson(
        json['dinner'] as Map<String, dynamic>,
      ),
      snack: NutritionSummaryModel.fromJson(
        json['snack'] as Map<String, dynamic>,
      ),
      total: NutritionSummaryModel.fromJson(
        json['total'] as Map<String, dynamic>,
      ),
    );
  }
}
