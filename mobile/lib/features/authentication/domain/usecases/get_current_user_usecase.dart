import '../../data/models/user_model.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<UserModel> call(String token) {
    return repository.getCurrentUser(token);
  }
}
