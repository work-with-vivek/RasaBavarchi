class GroceryProductModel {
  final String id;
  final String name;
  final String brand;
  final String ingredientName;
  final double quantity;
  final String unit;
  final double price;
  final String provider;
  final String? imageUrl;

  const GroceryProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.provider,
    required this.imageUrl,
  });
}
