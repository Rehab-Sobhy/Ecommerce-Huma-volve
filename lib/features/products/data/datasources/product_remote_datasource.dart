import 'package:dio/dio.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_request.dart';

/// Responsible only for raw HTTP calls and JSON parsing.
/// Returns data models (not entities) — mapping happens in the repository.
class ProductRemoteDataSource {
  ProductRemoteDataSource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.escuelajs.co/api/v1/',
                headers: const {'Content-Type': 'application/json'},
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  final Dio _dio;

  Future<List<ProductModel>> getProducts({
    int? offset,
    int? limit,
    String? title,
    int? categoryId,
    double? price,
    double? priceMin,
    double? priceMax,
  }) async {
    final queryParams = <String, dynamic>{};
    if (offset != null) queryParams['offset'] = offset;
    if (limit != null) queryParams['limit'] = limit;
    if (title != null && title.trim().isNotEmpty) queryParams['title'] = title.trim();
    if (categoryId != null && categoryId > 0) queryParams['categoryId'] = categoryId;
    if (price != null) queryParams['price'] = price;
    if (priceMin != null) queryParams['price_min'] = priceMin;
    if (priceMax != null) queryParams['price_max'] = priceMax;

    final response = await _dio.get<Object?>(
      'products',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return _parseList(response.data)
        .map((item) => ProductModel.fromJson(_asJsonObject(item)))
        .toList();
  }

  Future<ProductModel> getProductById(int id) async {
    final response = await _dio.get<Object?>('products/$id');
    return ProductModel.fromJson(_asJsonObject(response.data));
  }

  Future<ProductModel> getProductBySlug(String slug) async {
    final response = await _dio.get<Object?>('products/slug/$slug');
    return ProductModel.fromJson(_asJsonObject(response.data));
  }

  Future<List<ProductModel>> getRelatedProductsById(int id) async {
    final response = await _dio.get<Object?>('products/$id/related');
    return _parseList(response.data)
        .map((item) => ProductModel.fromJson(_asJsonObject(item)))
        .toList();
  }

  Future<List<ProductModel>> getRelatedProductsBySlug(String slug) async {
    final response = await _dio.get<Object?>('products/slug/$slug/related');
    return _parseList(response.data)
        .map((item) => ProductModel.fromJson(_asJsonObject(item)))
        .toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.get<Object?>('categories');
    return _parseList(response.data)
        .map((item) => CategoryModel.fromJson(_asJsonObject(item)))
        .toList();
  }

  Future<ProductModel> createProduct(ProductRequest request) async {
    final response = await _dio.post<Object?>('products', data: request.toJson());
    return ProductModel.fromJson(_asJsonObject(response.data));
  }

  Future<ProductModel> updateProduct(int id, ProductRequest request) async {
    final response = await _dio.put<Object?>('products/$id', data: request.toUpdateJson());
    return ProductModel.fromJson(_asJsonObject(response.data));
  }

  Future<bool> deleteProduct(int id) async {
    final response = await _dio.delete<Object?>('products/$id');
    return response.data == true ||
        response.statusCode == 200 ||
        response.statusCode == 204;
  }

  // --- Helpers ---

  static Map<String, dynamic> _asJsonObject(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('The server returned an invalid response object.');
  }

  static List<dynamic> _parseList(Object? value) {
    if (value is List) return value;
    throw const FormatException('The server returned an invalid response list.');
  }
}
