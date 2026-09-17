import 'recipe_model.dart';

class RecipePageModel {
  final List<RecipeModel> items;

  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const RecipePageModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory RecipePageModel.fromJson(Map<String, dynamic> json) {
    return RecipePageModel(
      items: (json["items"] as List)
          .map((item) => RecipeModel.fromJson(item as Map<String, dynamic>))
          .toList(),

      page: json["page"] as int,

      pageSize: json["page_size"] as int,

      total: json["total"] as int,

      totalPages: json["total_pages"] as int,
    );
  }
}
