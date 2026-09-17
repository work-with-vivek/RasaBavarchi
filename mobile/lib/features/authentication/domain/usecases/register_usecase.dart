import '../../data/models/message_response.dart';
import '../../data/models/register_request.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<MessageResponse> call(RegisterRequest request) {
    return repository.register(request);
  }
}
