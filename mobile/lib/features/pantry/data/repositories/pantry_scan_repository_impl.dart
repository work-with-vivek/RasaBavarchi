import 'package:image_picker/image_picker.dart';

import 'package:mobile/features/pantry/data/datasource/pantry_scan_remote_data_source.dart';
import 'package:mobile/features/pantry/data/models/pantry_scan_response_model.dart';

class PantryScanRepositoryImpl {
  const PantryScanRepositoryImpl(this._remoteDataSource);

  final PantryScanRemoteDataSource _remoteDataSource;

  Future<PantryScanResponseModel> scanPantry(XFile image) {
    return _remoteDataSource.scanPantry(image);
  }
}
