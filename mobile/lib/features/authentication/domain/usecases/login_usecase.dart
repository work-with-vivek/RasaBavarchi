import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<LoginResponse> call(LoginRequest request) {
    return repository.login(request);
  }
}
