import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

import '../../data/datasource/auth_remote_data_source.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

import 'auth_notifier.dart';

// ---------------------------------------------------------
// Dio
// ---------------------------------------------------------

final dioProvider = Provider((ref) {
  return ApiClient().dio;
});

// ---------------------------------------------------------
// Remote Data Source
// ---------------------------------------------------------

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.read(dioProvider));
});

// ---------------------------------------------------------
// Repository
// ---------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});

// ---------------------------------------------------------
// Login Use Case
// ---------------------------------------------------------

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

// ---------------------------------------------------------
// Register Use Case
// ---------------------------------------------------------

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.read(authRepositoryProvider));
});

// ---------------------------------------------------------
// Get Current User Use Case
// ---------------------------------------------------------

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

// ---------------------------------------------------------
// Auth Notifier
// ---------------------------------------------------------

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
      (ref) => AuthNotifier(ref),
    );

// ---------------------------------------------------------
// Current User
// ---------------------------------------------------------

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final token = await SecureStorageService.getToken();

  if (token == null || token.isEmpty) {
    return null;
  }

  try {
    return await ref.read(getCurrentUserUseCaseProvider).call(token);
  } catch (_) {
    return null;
  }
});
