class WeightLossCalculationModel {
  final double bmi;
  final double bmr;
  final double tdee;
  final double dailyCalorieTarget;
  final double currentWeightKg;
  final double goalWeightKg;
  final double weightToLoseKg;

  const WeightLossCalculationModel({
    required this.bmi,
    required this.bmr,
    required this.tdee,
    required this.dailyCalorieTarget,
    required this.currentWeightKg,
    required this.goalWeightKg,
    required this.weightToLoseKg,
  });

  factory WeightLossCalculationModel.fromJson(Map<String, dynamic> json) {
    return WeightLossCalculationModel(
      bmi: (json['bmi'] as num).toDouble(),
      bmr: (json['bmr'] as num).toDouble(),
      tdee: (json['tdee'] as num).toDouble(),
      dailyCalorieTarget: (json['daily_calorie_target'] as num).toDouble(),
      currentWeightKg: (json['current_weight_kg'] as num).toDouble(),
      goalWeightKg: (json['goal_weight_kg'] as num).toDouble(),
      weightToLoseKg: (json['weight_to_lose_kg'] as num).toDouble(),
    );
  }
}
