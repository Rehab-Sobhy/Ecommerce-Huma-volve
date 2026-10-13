import '../../../products/domain/entities/category_entity.dart';
import '../../../products/domain/repositories/product_repository.dart';

/// Use case: fetches all available product categories.
class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);

  final ProductRepository _repository;

  Future<List<CategoryEntity>> call() => _repository.getCategories();
}
