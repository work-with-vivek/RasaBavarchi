class RecipeVideoRequest {
  const RecipeVideoRequest({this.language = 'en', this.voice = 'female'});

  final String language;
  final String voice;

  Map<String, dynamic> toJson() {
    return {'language': language, 'voice': voice};
  }
}
