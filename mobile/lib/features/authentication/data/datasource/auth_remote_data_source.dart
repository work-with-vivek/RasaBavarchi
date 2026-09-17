import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/message_response.dart';
import '../models/otp_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  // =========================================================
  // Login
  // =========================================================

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: request.toJson(),
    );

    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // Register
  // =========================================================

  Future<MessageResponse> register(RegisterRequest request) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: request.toJson(),
    );

    return MessageResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // Verify Registration OTP
  // =========================================================

  Future<MessageResponse> verifyRegistrationOtp(OtpRequest request) async {
    final response = await _dio.post(
      ApiConstants.verifyRegistration,
      data: request.toJson(),
    );

    return MessageResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // Resend Registration OTP
  // =========================================================

  Future<MessageResponse> resendRegistrationOtp(String email) async {
    final response = await _dio.post(
      ApiConstants.resendRegistrationOtp,
      data: {'email': email},
    );

    return MessageResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // Forgot Password
  // =========================================================

  Future<MessageResponse> forgotPassword(String email) async {
    final response = await _dio.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );

    return MessageResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // Reset Password
  // =========================================================

  Future<MessageResponse> resetPassword(
    OtpRequest request,
    String newPassword,
  ) async {
    final response = await _dio.post(
      ApiConstants.resetPassword,
      data: {
        'email': request.email,
        'otp': request.otp,
        'new_password': newPassword,
      },
    );

    return MessageResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // Request Change Password OTP
  // =========================================================

  Future<MessageResponse> requestChangePasswordOtp(String token) async {
    final response = await _dio.post(
      ApiConstants.requestChangePasswordOtp,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return MessageResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // Change Password
  // =========================================================

  Future<MessageResponse> changePassword(
    String token,
    String otp,
    String newPassword,
  ) async {
    final response = await _dio.post(
      ApiConstants.changePassword,
      data: {'otp': otp, 'new_password': newPassword},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return MessageResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // Current User
  // =========================================================

  Future<UserModel> getCurrentUser(String token) async {
    final response = await _dio.get(
      ApiConstants.me,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
