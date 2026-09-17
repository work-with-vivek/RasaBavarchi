import 'package:dio/dio.dart';

class ApiErrorHandler {
  ApiErrorHandler._();

  static String getMessage(Object error) {
    if (error is DioException) {
      return _extractDioMessage(error);
    }

    return error.toString();
  }

  static String _extractDioMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final detail = responseData['detail'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }

      if (detail is Map<String, dynamic>) {
        final message = detail['message'];

        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }

      final message = responseData['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server. Please check your connection.';
    }

    if (error.response?.statusCode == 429) {
      return 'Too many requests. Please wait and try again.';
    }

    if (error.response?.statusCode != null) {
      return 'Something went wrong. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}
