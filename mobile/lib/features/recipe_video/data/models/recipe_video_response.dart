class RecipeVideoResponse {
  const RecipeVideoResponse({
    required this.status,
    required this.videoUrl,
    required this.duration,
    required this.message,
  });

  final String status;
  final String? videoUrl;
  final int? duration;
  final String message;

  factory RecipeVideoResponse.fromJson(Map<String, dynamic> json) {
    return RecipeVideoResponse(
      status: json['status'] as String? ?? 'failed',
      videoUrl: json['video_url'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      message: json['message'] as String? ?? '',
    );
  }

  bool get isCompleted {
    return status.toLowerCase() == 'completed' &&
        videoUrl != null &&
        videoUrl!.isNotEmpty;
  }
}
