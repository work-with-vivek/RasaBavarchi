import 'nutrition_summary_model.dart';

class MealPlanNutritionModel {
  final NutritionSummaryModel breakfast;
  final NutritionSummaryModel lunch;
  final NutritionSummaryModel dinner;
  final NutritionSummaryModel snack;
  final NutritionSummaryModel total;

  const MealPlanNutritionModel({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
    required this.total,
  });

  factory MealPlanNutritionModel.fromJson(Map<String, dynamic> json) {
    return MealPlanNutritionModel(
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
