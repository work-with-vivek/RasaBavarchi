enum ShoppingProviderType { providerA, providerB, providerC }

class ShoppingProvider {
  final ShoppingProviderType type;
  final String id;
  final String name;
  final String deliveryTime;
  final double deliveryFee;

  const ShoppingProvider({
    required this.type,
    required this.id,
    required this.name,
    required this.deliveryTime,
    required this.deliveryFee,
  });
}
