import 'package:mobile/features/pantry/data/datasource/pantry_management_remote_data_source.dart';
import 'package:mobile/features/pantry/data/models/pantry_item_model.dart';
import 'package:mobile/features/pantry/domain/repositories/pantry_management_repository.dart';

class PantryManagementRepositoryImpl implements PantryManagementRepository {
  const PantryManagementRepositoryImpl(this._remoteDataSource);

  final PantryManagementRemoteDataSource _remoteDataSource;

  @override
  Future<PantryItemModel> addPantryItem({
    required String ingredientId,
    required double quantity,
    required String unitId,
    DateTime? expiresAt,
  }) {
    return _remoteDataSource.addPantryItem(
      ingredientId: ingredientId,
      quantity: quantity,
      unitId: unitId,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<PantryItemModel> updatePantryItem({
    required String itemId,
    required double quantity,
    required String unitId,
    DateTime? expiresAt,
  }) {
    return _remoteDataSource.updatePantryItem(
      itemId: itemId,
      quantity: quantity,
      unitId: unitId,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> deletePantryItem(String itemId) {
    return _remoteDataSource.deletePantryItem(itemId);
  }

  @override
  Future<Map<String, dynamic>> getIngredientByName(String name) {
    return _remoteDataSource.getIngredientByName(name);
  }

  @override
  Future<List<Map<String, dynamic>>> searchIngredients(String name) {
    return _remoteDataSource.searchIngredients(name);
  }

  @override
  Future<Map<String, dynamic>> getUnitBySymbol(String symbol) {
    return _remoteDataSource.getUnitBySymbol(symbol);
  }

  @override
  Future<List<Map<String, dynamic>>> getUnits() {
    return _remoteDataSource.getUnits();
  }
}
