import '../../data/datasource/auth_remote_data_source.dart';
import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../../data/models/message_response.dart';
import '../../data/models/register_request.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<LoginResponse> login(LoginRequest request) {
    return remoteDataSource.login(request);
  }

  @override
  Future<MessageResponse> register(RegisterRequest request) {
    return remoteDataSource.register(request);
  }

  @override
  Future<UserModel> getCurrentUser(String token) {
    return remoteDataSource.getCurrentUser(token);
  }
}
