import 'package:mobile/features/pantry/data/models/pantry_item_model.dart';

abstract class PantryRepository {
  Future<List<PantryItemModel>> getPantryItems();
}
