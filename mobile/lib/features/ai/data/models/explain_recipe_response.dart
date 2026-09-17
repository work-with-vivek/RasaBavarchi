class ExplainRecipeResponse {
  const ExplainRecipeResponse({required this.answer});

  final String answer;

  factory ExplainRecipeResponse.fromJson(Map<String, dynamic> json) {
    return ExplainRecipeResponse(answer: json['answer'] as String);
  }
}
