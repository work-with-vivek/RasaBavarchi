import 'package:mobile/features/pantry/data/models/pantry_comparison_model.dart';
import 'package:mobile/features/shopping/data/models/grocery_product_model.dart';

class ShoppingCartItem {
  final PantryComparisonItem ingredient;
  final GroceryProductModel product;
  final int packCount;
  final double totalQuantity;
  final double totalPrice;

  const ShoppingCartItem({
    required this.ingredient,
    required this.product,
    required this.packCount,
    required this.totalQuantity,
    required this.totalPrice,
  });
}
