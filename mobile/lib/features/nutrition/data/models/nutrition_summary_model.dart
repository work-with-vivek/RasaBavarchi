class NutritionSummaryModel {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const NutritionSummaryModel({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory NutritionSummaryModel.fromJson(Map<String, dynamic> json) {
    return NutritionSummaryModel(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
    );
  }
}
