import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/ai/data/datasource/ai_remote_data_source.dart';
import 'package:mobile/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:mobile/features/ai/domain/repositories/ai_repository.dart';

final aiRemoteDataSourceProvider = Provider<AIRemoteDataSource>((ref) {
  return AIRemoteDataSource(ApiClient().dio);
});

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepositoryImpl(ref.read(aiRemoteDataSourceProvider));
});
