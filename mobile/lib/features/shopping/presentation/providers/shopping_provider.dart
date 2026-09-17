import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/shopping/data/datasources/mock_grocery_product_data_source.dart';
import 'package:mobile/features/shopping/data/models/grocery_product_model.dart';
import 'package:mobile/features/shopping/data/providers/mock_shopping_provider_repository.dart';
import 'package:mobile/features/shopping/data/repositories/grocery_product_repository_impl.dart';
import 'package:mobile/features/shopping/domain/entities/shopping_provider.dart';
import 'package:mobile/features/shopping/domain/providers/shopping_provider_repository.dart';
import 'package:mobile/features/shopping/domain/repositories/grocery_product_repository.dart';

final groceryProductDataSourceProvider = Provider<MockGroceryProductDataSource>(
  (ref) {
    return MockGroceryProductDataSource();
  },
);

final groceryProductRepositoryProvider = Provider<GroceryProductRepository>((
  ref,
) {
  return GroceryProductRepositoryImpl(
    ref.read(groceryProductDataSourceProvider),
  );
});

final groceryProductsProvider =
    FutureProvider.family<List<GroceryProductModel>, String>((
      ref,
      ingredientName,
    ) {
      return ref
          .read(groceryProductRepositoryProvider)
          .findProducts(ingredientName: ingredientName);
    });

// =============================================================
// SHOPPING PROVIDERS
// =============================================================

final shoppingProviderRepositoryProvider = Provider<ShoppingProviderRepository>(
  (ref) {
    return MockShoppingProviderRepository();
  },
);

final shoppingProvidersProvider = FutureProvider<List<ShoppingProvider>>((ref) {
  return ref.read(shoppingProviderRepositoryProvider).getProviders();
});
