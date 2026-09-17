import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/pantry/data/datasource/pantry_management_remote_data_source.dart';
import 'package:mobile/features/pantry/data/repositories/pantry_management_repository_impl.dart';
import 'package:mobile/features/pantry/domain/repositories/pantry_management_repository.dart';

final pantryManagementRemoteDataSourceProvider =
    Provider<PantryManagementRemoteDataSource>((ref) {
      return PantryManagementRemoteDataSource(ApiClient().dio);
    });

final pantryManagementRepositoryProvider = Provider<PantryManagementRepository>(
  (ref) {
    return PantryManagementRepositoryImpl(
      ref.read(pantryManagementRemoteDataSourceProvider),
    );
  },
);
