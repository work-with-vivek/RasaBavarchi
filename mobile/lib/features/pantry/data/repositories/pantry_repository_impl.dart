import 'package:mobile/features/pantry/data/datasource/pantry_remote_data_source.dart';
import 'package:mobile/features/pantry/data/models/pantry_item_model.dart';
import 'package:mobile/features/pantry/domain/repositories/pantry_repository.dart';

class PantryRepositoryImpl implements PantryRepository {
  PantryRepositoryImpl(this._remoteDataSource);

  final PantryRemoteDataSource _remoteDataSource;

  @override
  Future<List<PantryItemModel>> getPantryItems() {
    return _remoteDataSource.getPantryItems();
  }
}
