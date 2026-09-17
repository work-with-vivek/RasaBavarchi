import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/pantry/data/datasource/pantry_remote_data_source.dart';
import 'package:mobile/features/pantry/data/models/pantry_item_model.dart';
import 'package:mobile/features/pantry/data/repositories/pantry_repository_impl.dart';
import 'package:mobile/features/pantry/domain/repositories/pantry_repository.dart';

final pantryDioProvider = Provider((ref) {
  return ApiClient().dio;
});

final pantryRemoteDataSourceProvider = Provider<PantryRemoteDataSource>((ref) {
  return PantryRemoteDataSource(ref.read(pantryDioProvider));
});

final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  return PantryRepositoryImpl(ref.read(pantryRemoteDataSourceProvider));
});

final pantryItemsProvider = FutureProvider<List<PantryItemModel>>((ref) {
  return ref.read(pantryRepositoryProvider).getPantryItems();
});
