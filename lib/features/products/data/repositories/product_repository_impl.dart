import 'package:dio/dio.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_request.dart';

/// Concrete implementation of [ProductRepository].
/// Translates data-layer exceptions into domain-layer [ProductException]s
/// and maps data models to domain entities.
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({ProductRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? ProductRemoteDataSource();

  final ProductRemoteDataSource _dataSource;

  @override
  Future<List<ProductEntity>> getProducts({
    int? offset,
    int? limit,
    String? title,
    int? categoryId,
    double? priceMin,
    double? priceMax,
  }) async {
    try {
      final models = await _dataSource.getProducts(
        offset: offset,
        limit: limit,
        title: title,
        categoryId: categoryId,
        priceMin: priceMin,
        priceMax: priceMax,
      );
      return models.map(_modelToEntity).toList();
    } on DioException catch (e) {
      throw ProductException(_messageFor(e));
    } on FormatException catch (e) {
      throw ProductException(e.message);
    }
  }

  @override
  Future<ProductEntity> getProductById(int id) async {
    try {
      return _modelToEntity(await _dataSource.getProductById(id));
    } on DioException catch (e) {
      throw ProductException(_messageFor(e));
    } on FormatException catch (e) {
      throw ProductException(e.message);
    }
  }

  @override
  Future<ProductEntity> getProductBySlug(String slug) async {
    try {
      return _modelToEntity(await _dataSource.getProductBySlug(slug));
    } on DioException catch (e) {
      throw ProductException(_messageFor(e));
    } on FormatException catch (e) {
      throw ProductException(e.message);
    }
  }

  @override
  Future<List<ProductEntity>> getRelatedProductsById(int id) async {
    try {
      final models = await _dataSource.getRelatedProductsById(id);
      return models.map(_modelToEntity).toList();
    } on DioException catch (e) {
      throw ProductException(_messageFor(e));
    } on FormatException catch (e) {
      throw ProductException(e.message);
    }
  }

  @override
  Future<List<ProductEntity>> getRelatedProductsBySlug(String slug) async {
    try {
      final models = await _dataSource.getRelatedProductsBySlug(slug);
      return models.map(_modelToEntity).toList();
    } on DioException catch (e) {
      throw ProductException(_messageFor(e));
    } on FormatException catch (e) {
      throw ProductException(e.message);
    }
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      final models = await _dataSource.getCategories();
      return models.map(_categoryModelToEntity).toList();
    } on DioException catch (e) {
      throw ProductException(_messageFor(e));
    } on FormatException catch (e) {
      throw ProductException(e.message);
    }
  }

  // --- Write operations (not in domain interface to keep domain pure) ---

  /// Creates a new product and returns a [ProductEntity].
  Future<ProductEntity> createProductEntity(ProductRequest request) async {
    try {
      final model = await _dataSource.createProduct(request);
      return _modelToEntity(model);
    } on DioException catch (e) {
      throw ProductException(_messageFor(e));
    } on FormatException catch (e) {
      throw ProductException(e.message);
    }
  }

  /// Updates an existing product and returns the updated [ProductEntity].
  Future<ProductEntity> updateProductEntity(int id, ProductRequest request) async {
    try {
      final model = await _dataSource.updateProduct(id, request);
      return _modelToEntity(model);
    } on DioException catch (e) {
      throw ProductException(_messageFor(e));
    } on FormatException catch (e) {
      throw ProductException(e.message);
    }
  }

  /// Deletes a product by ID.
  Future<bool> deleteProductEntity(int id) async {
    try {
      return await _dataSource.deleteProduct(id);
    } on DioException catch (e) {
      throw ProductException(_messageFor(e));
    } on FormatException catch (e) {
      throw ProductException(e.message);
    }
  }

  // --- Mapping helpers ---

  static ProductEntity _modelToEntity(ProductModel m) => ProductEntity(
        id: m.id,
        title: m.title,
        slug: m.slug,
        price: m.price,
        description: m.description,
        category: m.category != null ? _categoryModelToEntity(m.category!) : null,
        images: m.images,
      );

  static CategoryEntity _categoryModelToEntity(CategoryModel m) => CategoryEntity(
        id: m.id,
        name: m.name,
        slug: m.slug,
        image: m.image,
      );

  static String _messageFor(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
      if (msg is List && msg.isNotEmpty) return (msg).join('\n');
    }
    if (error.response?.statusCode == 404) {
      return 'The requested product was not found.';
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'The request timed out. Please try again.',
      DioExceptionType.connectionError =>
        'Unable to connect to the server. Check your internet connection.',
      _ => 'An error occurred while communicating with the product server.',
    };
  }
}

/// Domain-level exception thrown by [ProductRepositoryImpl].
class ProductException implements Exception {
  const ProductException(this.message);
  final String message;

  @override
  String toString() => message;
}
