class WeightLossProfileModel {
  final String id;
  final String userId;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  final double goalWeightKg;

  const WeightLossProfileModel({
    required this.id,
    required this.userId,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goalWeightKg,
  });

  factory WeightLossProfileModel.fromJson(Map<String, dynamic> json) {
    return WeightLossProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      heightCm: (json['height_cm'] as num).toDouble(),
      weightKg: (json['weight_kg'] as num).toDouble(),
      activityLevel: json['activity_level'] as String,
      goalWeightKg: (json['goal_weight_kg'] as num).toDouble(),
    );
  }
}
