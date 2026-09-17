import 'package:mobile/features/shopping/domain/entities/shopping_provider.dart';
import 'package:mobile/features/shopping/domain/providers/shopping_provider_repository.dart';

class MockShoppingProviderRepository implements ShoppingProviderRepository {
  @override
  Future<List<ShoppingProvider>> getProviders() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return const [
      ShoppingProvider(
        type: ShoppingProviderType.providerA,
        id: 'blinkit',
        name: 'Blinkit',
        deliveryTime: '10–20 min',
        deliveryFee: 0,
      ),
      ShoppingProvider(
        type: ShoppingProviderType.providerB,
        id: 'zepto',
        name: 'Zepto',
        deliveryTime: '10–20 min',
        deliveryFee: 10,
      ),
      ShoppingProvider(
        type: ShoppingProviderType.providerC,
        id: 'swiggy_instamart',
        name: 'Swiggy Instamart',
        deliveryTime: '15–25 min',
        deliveryFee: 20,
      ),
    ];
  }
}
