import 'package:mobile/features/shopping/domain/entities/shopping_provider.dart';

abstract class ShoppingProviderRepository {
  Future<List<ShoppingProvider>> getProviders();
}
