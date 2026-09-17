import 'package:dio/dio.dart';

import '../models/category_model.dart';

class CategoryRemoteDataSource {
  final Dio dio;

  CategoryRemoteDataSource(this.dio);

  Future<List<CategoryModel>> getCategories() async {
    final response = await dio.get("/categories");

    final data = response.data as List;

    return data
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
