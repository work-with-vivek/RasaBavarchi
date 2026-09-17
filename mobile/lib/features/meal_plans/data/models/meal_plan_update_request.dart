class MealPlanUpdateRequest {
  const MealPlanUpdateRequest({this.name, this.description});

  final String? name;
  final String? description;

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description};
  }
}
