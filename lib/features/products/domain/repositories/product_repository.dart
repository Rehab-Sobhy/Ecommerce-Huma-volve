import '../entities/category_entity.dart';
import '../entities/product_entity.dart';

/// Abstract contract for product data operations.
/// Screens and use-cases depend on this interface, not on any concrete implementation.
abstract interface class ProductRepository {
  Future<List<ProductEntity>> getProducts({
    int? offset,
    int? limit,
    String? title,
    int? categoryId,
    double? priceMin,
    double? priceMax,
  });

  Future<ProductEntity> getProductById(int id);

  Future<ProductEntity> getProductBySlug(String slug);

  Future<List<ProductEntity>> getRelatedProductsById(int id);

  Future<List<ProductEntity>> getRelatedProductsBySlug(String slug);

  Future<List<CategoryEntity>> getCategories();
}
