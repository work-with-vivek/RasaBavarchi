class CommunityAuthorModel {
  final String id;
  final String username;

  const CommunityAuthorModel({
    required this.id,
    required this.username,
  });

  factory CommunityAuthorModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommunityAuthorModel(
      id: json['id'] as String,
      username: json['username'] as String,
    );
  }
}