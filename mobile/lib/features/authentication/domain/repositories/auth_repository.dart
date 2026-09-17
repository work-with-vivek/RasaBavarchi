import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/models/message_response.dart';
import '../../data/models/register_request.dart';
import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(LoginRequest request);

  Future<MessageResponse> register(RegisterRequest request);

  Future<UserModel> getCurrentUser(String token);
}
