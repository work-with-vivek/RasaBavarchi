class ExplainRecipeRequest {
  const ExplainRecipeRequest({required this.question});

  final String question;

  Map<String, dynamic> toJson() {
    return {'question': question};
  }
}
