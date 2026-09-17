import '../../data/models/category_model.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository repository;

  GetCategoriesUseCase(this.repository);

  Future<List<CategoryModel>> call() {
    return repository.getCategories();
  }
}
