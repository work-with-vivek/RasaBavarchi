import 'package:mobile/features/shopping/data/models/grocery_product_model.dart';

class MockGroceryProductDataSource {
  Future<List<GroceryProductModel>> findProducts({
    required String ingredientName,
  }) async {
    final query = ingredientName.trim().toLowerCase();

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final products = <GroceryProductModel>[
      // =========================================================
      // PANEER
      // =========================================================
      const GroceryProductModel(
        id: 'paneer-1',
        name: 'Fresh Paneer',
        brand: 'Amul',
        ingredientName: 'paneer',
        quantity: 200,
        unit: 'g',
        price: 85,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'paneer-2',
        name: 'Premium Paneer',
        brand: 'Mother Dairy',
        ingredientName: 'paneer',
        quantity: 200,
        unit: 'g',
        price: 95,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // BUTTER
      // =========================================================
      const GroceryProductModel(
        id: 'butter-1',
        name: 'Salted Butter',
        brand: 'Amul',
        ingredientName: 'butter',
        quantity: 100,
        unit: 'g',
        price: 58,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'butter-2',
        name: 'Unsalted Butter',
        brand: 'Amul',
        ingredientName: 'butter',
        quantity: 100,
        unit: 'g',
        price: 62,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // CREAM
      // =========================================================
      const GroceryProductModel(
        id: 'cream-1',
        name: 'Fresh Cream',
        brand: 'Amul',
        ingredientName: 'cream',
        quantity: 250,
        unit: 'ml',
        price: 75,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'cream-2',
        name: 'Fresh Cream',
        brand: 'Mother Dairy',
        ingredientName: 'cream',
        quantity: 200,
        unit: 'ml',
        price: 68,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // TOMATO
      // =========================================================
      const GroceryProductModel(
        id: 'tomato-1',
        name: 'Fresh Tomato',
        brand: 'Farm Fresh',
        ingredientName: 'tomato',
        quantity: 500,
        unit: 'g',
        price: 45,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'tomato-2',
        name: 'Premium Tomato',
        brand: 'Farm Fresh',
        ingredientName: 'tomato',
        quantity: 1,
        unit: 'kg',
        price: 78,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // ONION
      // =========================================================
      const GroceryProductModel(
        id: 'onion-1',
        name: 'Fresh Onion',
        brand: 'Farm Fresh',
        ingredientName: 'onion',
        quantity: 500,
        unit: 'g',
        price: 38,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'onion-2',
        name: 'Fresh Onion',
        brand: 'Farm Fresh',
        ingredientName: 'onion',
        quantity: 1,
        unit: 'kg',
        price: 65,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // POTATO
      // =========================================================
      const GroceryProductModel(
        id: 'potato-1',
        name: 'Fresh Potatoes',
        brand: 'Farm Fresh',
        ingredientName: 'potatoes',
        quantity: 1,
        unit: 'kg',
        price: 42,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'potato-2',
        name: 'Premium Potatoes',
        brand: 'Farm Fresh',
        ingredientName: 'potatoes',
        quantity: 500,
        unit: 'g',
        price: 25,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // BABY CARROTS
      // =========================================================
      const GroceryProductModel(
        id: 'baby-carrots-1',
        name: 'Fresh Baby Carrots',
        brand: 'Farm Fresh',
        ingredientName: 'baby carrots',
        quantity: 500,
        unit: 'g',
        price: 55,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'baby-carrots-2',
        name: 'Premium Baby Carrots',
        brand: 'Nature Fresh',
        ingredientName: 'baby carrots',
        quantity: 250,
        unit: 'g',
        price: 35,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // OIL
      // =========================================================
      const GroceryProductModel(
        id: 'oil-1',
        name: 'Cooking Oil',
        brand: 'Fortune',
        ingredientName: 'oil',
        quantity: 1,
        unit: 'L',
        price: 145,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'oil-2',
        name: 'Sunflower Oil',
        brand: 'Saffola',
        ingredientName: 'oil',
        quantity: 1,
        unit: 'L',
        price: 155,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // SALT
      // =========================================================
      const GroceryProductModel(
        id: 'salt-1',
        name: 'Iodized Salt',
        brand: 'Tata',
        ingredientName: 'salt',
        quantity: 1,
        unit: 'kg',
        price: 28,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'salt-2',
        name: 'Iodized Salt',
        brand: 'Aashirvaad',
        ingredientName: 'salt',
        quantity: 1,
        unit: 'kg',
        price: 30,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // NONFAT VANILLA YOGURT
      // =========================================================
      const GroceryProductModel(
        id: 'vanilla-yogurt-1',
        name: 'Nonfat Vanilla Yogurt',
        brand: 'Amul',
        ingredientName: 'nonfat vanilla yogurt',
        quantity: 1,
        unit: 'unk',
        price: 65,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'vanilla-yogurt-2',
        name: 'Vanilla Yogurt',
        brand: 'Mother Dairy',
        ingredientName: 'nonfat vanilla yogurt',
        quantity: 1,
        unit: 'unk',
        price: 72,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // STRAWBERRY
      // =========================================================
      const GroceryProductModel(
        id: 'strawberry-1',
        name: 'Fresh Strawberry',
        brand: 'Farm Fresh',
        ingredientName: 'strawberry',
        quantity: 1,
        unit: 'unk',
        price: 90,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'strawberry-2',
        name: 'Premium Strawberry',
        brand: 'Nature Fresh',
        ingredientName: 'strawberry',
        quantity: 1,
        unit: 'unk',
        price: 110,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // FRESH BLACKBERRIES
      // =========================================================
      const GroceryProductModel(
        id: 'blackberries-1',
        name: 'Fresh Blackberries',
        brand: 'Farm Fresh',
        ingredientName: 'fresh blackberries',
        quantity: 1,
        unit: 'unk',
        price: 120,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'blackberries-2',
        name: 'Premium Blackberries',
        brand: 'Nature Fresh',
        ingredientName: 'fresh blackberries',
        quantity: 1,
        unit: 'unk',
        price: 135,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // BLUEBERRIES
      // =========================================================
      const GroceryProductModel(
        id: 'blueberries-1',
        name: 'Fresh Blueberries',
        brand: 'Farm Fresh',
        ingredientName: 'blueberries',
        quantity: 1,
        unit: 'unk',
        price: 110,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'blueberries-2',
        name: 'Premium Blueberries',
        brand: 'Nature Fresh',
        ingredientName: 'blueberries',
        quantity: 1,
        unit: 'unk',
        price: 125,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // BANANA
      // =========================================================
      const GroceryProductModel(
        id: 'banana-1',
        name: 'Fresh Banana',
        brand: 'Farm Fresh',
        ingredientName: 'banana',
        quantity: 1,
        unit: 'unk',
        price: 45,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'banana-2',
        name: 'Premium Banana',
        brand: 'Farm Fresh',
        ingredientName: 'banana',
        quantity: 1,
        unit: 'unk',
        price: 55,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // APPLE
      // =========================================================
      const GroceryProductModel(
        id: 'apple-1',
        name: 'Fresh Apple',
        brand: 'Farm Fresh',
        ingredientName: 'apple',
        quantity: 1,
        unit: 'unk',
        price: 60,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'apple-2',
        name: 'Premium Apple',
        brand: 'Nature Fresh',
        ingredientName: 'apple',
        quantity: 1,
        unit: 'unk',
        price: 75,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // LEMON
      // =========================================================
      const GroceryProductModel(
        id: 'lemon-1',
        name: 'Fresh Lemon',
        brand: 'Farm Fresh',
        ingredientName: 'lemon',
        quantity: 1,
        unit: 'unk',
        price: 35,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'lemon-2',
        name: 'Fresh Lemon Premium',
        brand: 'Nature Fresh',
        ingredientName: 'lemon',
        quantity: 1,
        unit: 'unk',
        price: 45,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // PECANS
      // =========================================================
      const GroceryProductModel(
        id: 'pecans-1',
        name: 'Premium Pecans',
        brand: 'Nature Fresh',
        ingredientName: 'pecans',
        quantity: 1,
        unit: 'unk',
        price: 180,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'pecans-2',
        name: 'Pecan Nuts',
        brand: 'Farm Fresh',
        ingredientName: 'pecans',
        quantity: 1,
        unit: 'unk',
        price: 210,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // RAISINS
      // =========================================================
      const GroceryProductModel(
        id: 'raisins-1',
        name: 'Premium Raisins',
        brand: 'Tata',
        ingredientName: 'raisins',
        quantity: 1,
        unit: 'unk',
        price: 95,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'raisins-2',
        name: 'Golden Raisins',
        brand: 'Farm Fresh',
        ingredientName: 'raisins',
        quantity: 1,
        unit: 'unk',
        price: 120,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),

      // =========================================================
      // CHERRIES IN SYRUP
      // =========================================================
      const GroceryProductModel(
        id: 'cherries-syrup-1',
        name: 'Cherries in Syrup',
        brand: 'Del Monte',
        ingredientName: 'cherries in syrup',
        quantity: 1,
        unit: 'unk',
        price: 145,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
      const GroceryProductModel(
        id: 'cherries-syrup-2',
        name: 'Premium Cherries in Syrup',
        brand: 'Nature Fresh',
        ingredientName: 'cherries in syrup',
        quantity: 1,
        unit: 'unk',
        price: 165,
        provider: 'Quick Commerce',
        imageUrl: null,
      ),
    ];

    return products.where((product) {
      final productIngredient = product.ingredientName.trim().toLowerCase();

      final productName = product.name.trim().toLowerCase();

      return productIngredient == query ||
          productName.contains(query) ||
          query.contains(productIngredient);
    }).toList();
  }
}
