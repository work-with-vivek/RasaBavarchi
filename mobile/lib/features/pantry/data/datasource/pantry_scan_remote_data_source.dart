import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mobile/features/pantry/data/models/pantry_scan_response_model.dart';

class PantryScanRemoteDataSource {
  PantryScanRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PantryScanResponseModel> scanPantry(XFile image) async {
    final bytes = await image.readAsBytes();

    final fileName = image.name.isEmpty ? 'pantry.jpg' : image.name;

    final mimeType = _mimeTypeFromFileName(fileName);

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    final response = await _dio.post('/ai/pantry-scan', data: formData);

    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('Invalid pantry scan response.');
    }

    return PantryScanResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  String _mimeTypeFromFileName(String fileName) {
    final name = fileName.toLowerCase();

    if (name.endsWith('.png')) {
      return 'image/png';
    }

    if (name.endsWith('.webp')) {
      return 'image/webp';
    }

    if (name.endsWith('.gif')) {
      return 'image/gif';
    }

    return 'image/jpeg';
  }
}
