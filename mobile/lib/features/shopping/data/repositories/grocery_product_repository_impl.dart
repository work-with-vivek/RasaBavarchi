import 'package:mobile/features/shopping/data/datasources/mock_grocery_product_data_source.dart';
import 'package:mobile/features/shopping/data/models/grocery_product_model.dart';
import 'package:mobile/features/shopping/domain/repositories/grocery_product_repository.dart';

class GroceryProductRepositoryImpl implements GroceryProductRepository {
  GroceryProductRepositoryImpl(this._dataSource);

  final MockGroceryProductDataSource _dataSource;

  @override
  Future<List<GroceryProductModel>> findProducts({
    required String ingredientName,
  }) {
    return _dataSource.findProducts(ingredientName: ingredientName);
  }
}
