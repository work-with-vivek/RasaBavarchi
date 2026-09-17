class OtpRequest {
  final String email;
  final String otp;

  const OtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() {
    return {'email': email, 'otp': otp};
  }
}
