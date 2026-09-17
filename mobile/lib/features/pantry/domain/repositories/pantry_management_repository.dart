import 'package:mobile/features/pantry/data/models/pantry_item_model.dart';

abstract class PantryManagementRepository {
  Future<PantryItemModel> addPantryItem({
    required String ingredientId,
    required double quantity,
    required String unitId,
    DateTime? expiresAt,
  });

  Future<PantryItemModel> updatePantryItem({
    required String itemId,
    required double quantity,
    required String unitId,
    DateTime? expiresAt,
  });

  Future<void> deletePantryItem(String itemId);

  Future<Map<String, dynamic>> getIngredientByName(String name);

  Future<List<Map<String, dynamic>>> searchIngredients(String name);

  Future<Map<String, dynamic>> getUnitBySymbol(String symbol);

  Future<List<Map<String, dynamic>>> getUnits();
}
