class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.0.2.2:8000';

  // =========================================================
  // Authentication
  // =========================================================

  static const String login = '/auth/login';

  static const String register = '/auth/register';

  static const String verifyRegistration = '/auth/register/verify';

  static const String resendRegistrationOtp = '/auth/register/resend-otp';

  static const String forgotPassword = '/auth/forgot-password';

  static const String resetPassword = '/auth/reset-password';

  static const String requestChangePasswordOtp =
      '/auth/change-password/request-otp';

  static const String changePassword = '/auth/change-password';

  static const String me = '/auth/me';

  // =========================================================
  // Recipe Video API
  // =========================================================

  static const String recipeVideo = '/api/v1/recipe-video';
}
