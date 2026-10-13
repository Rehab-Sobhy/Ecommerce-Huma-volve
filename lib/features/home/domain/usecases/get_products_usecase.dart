import '../../../products/domain/entities/product_entity.dart';
import '../../../products/domain/repositories/product_repository.dart';

/// Use case: fetches a filtered/paginated list of products.
class GetProductsUseCase {
  const GetProductsUseCase(this._repository);

  final ProductRepository _repository;

  Future<List<ProductEntity>> call({
    String? title,
    int? categoryId,
    double? priceMin,
    double? priceMax,
    int? offset,
    int? limit,
  }) {
    return _repository.getProducts(
      title: title,
      categoryId: categoryId,
      priceMin: priceMin,
      priceMax: priceMax,
      offset: offset,
      limit: limit,
    );
  }
}
