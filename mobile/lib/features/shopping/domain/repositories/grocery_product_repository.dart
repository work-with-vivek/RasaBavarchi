import 'package:mobile/features/shopping/data/models/grocery_product_model.dart';

abstract class GroceryProductRepository {
  Future<List<GroceryProductModel>> findProducts({
    required String ingredientName,
  });
}
