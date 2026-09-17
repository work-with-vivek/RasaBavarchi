import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';

import '../../../../core/storage/secure_storage_service.dart';

import 'auth_providers.dart';

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this.ref) : super(const AsyncData(null));

  final Ref ref;

  // ---------------------------------------------------------
  // Login
  // ---------------------------------------------------------

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();

    try {
      final loginUseCase = ref.read(loginUseCaseProvider);

      final response = await loginUseCase(
        LoginRequest(email: email, password: password),
      );

      await SecureStorageService.saveToken(response.accessToken);

      ref.invalidate(currentUserProvider);

      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  // ---------------------------------------------------------
  // Register
  // ---------------------------------------------------------

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final registerUseCase = ref.read(registerUseCaseProvider);

      await registerUseCase(
        RegisterRequest(username: username, email: email, password: password),
      );

      state = const AsyncData(null);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}
