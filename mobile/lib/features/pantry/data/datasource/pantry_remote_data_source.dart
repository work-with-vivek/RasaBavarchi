import 'package:dio/dio.dart';

import 'package:mobile/features/pantry/data/models/pantry_item_model.dart';

class PantryRemoteDataSource {
  PantryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PantryItemModel>> getPantryItems() async {
    final response = await _dio.get('/pantry/items');

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid pantry response.');
    }

    return data.map((item) {
      return PantryItemModel.fromJson(item as Map<String, dynamic>);
    }).toList();
  }
}
