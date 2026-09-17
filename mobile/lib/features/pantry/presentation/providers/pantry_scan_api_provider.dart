import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/pantry/data/datasource/pantry_scan_remote_data_source.dart';
import 'package:mobile/features/pantry/data/repositories/pantry_scan_repository_impl.dart';

final pantryScanRemoteDataSourceProvider = Provider<PantryScanRemoteDataSource>(
  (ref) {
    return PantryScanRemoteDataSource(ApiClient().dio);
  },
);

final pantryScanRepositoryProvider = Provider<PantryScanRepositoryImpl>((ref) {
  return PantryScanRepositoryImpl(ref.read(pantryScanRemoteDataSourceProvider));
});
