import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_request.dart';

class ProductService {
  ProductService({Dio? dio})
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

  /// GET /api/v1/products
  /// Fetches products with optional pagination and filters.
  Future<List<ProductModel>> getProducts({
    int? offset,
    int? limit,
    String? title,
    int? categoryId,
    double? price,
    double? priceMin,
    double? priceMax,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (offset != null) queryParams['offset'] = offset;
      if (limit != null) queryParams['limit'] = limit;
      if (title != null && title.trim().isNotEmpty) {
        queryParams['title'] = title.trim();
      }
      if (categoryId != null && categoryId > 0) {
        queryParams['categoryId'] = categoryId;
      }
      if (price != null) queryParams['price'] = price;
      if (priceMin != null) queryParams['price_min'] = priceMin;
      if (priceMax != null) queryParams['price_max'] = priceMax;

      final response = await _dio.get<Object?>(
        'products',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final list = _asJsonList(response.data);
      return list
          .map((item) => ProductModel.fromJson(_asJsonObject(item)))
          .toList();
    } on DioException catch (error) {
      throw ProductException(_messageFor(error));
    } on FormatException catch (error) {
      throw ProductException(error.message);
    }
  }

  /// POST /api/v1/products
  /// Creates a new product.
  Future<ProductModel> createProduct(ProductRequest request) async {
    try {
      final response = await _dio.post<Object?>(
        'products',
        data: request.toJson(),
      );
      return ProductModel.fromJson(_asJsonObject(response.data));
    } on DioException catch (error) {
      throw ProductException(_messageFor(error));
    } on FormatException catch (error) {
      throw ProductException(error.message);
    }
  }

  /// GET /api/v1/products/{id}
  /// Fetches a single product by its numeric ID.
  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await _dio.get<Object?>('products/$id');
      return ProductModel.fromJson(_asJsonObject(response.data));
    } on DioException catch (error) {
      throw ProductException(_messageFor(error));
    } on FormatException catch (error) {
      throw ProductException(error.message);
    }
  }

  /// PUT /api/v1/products/{id}
  /// Updates an existing product by its numeric ID.
  Future<ProductModel> updateProduct(int id, ProductRequest request) async {
    try {
      final response = await _dio.put<Object?>(
        'products/$id',
        data: request.toUpdateJson(),
      );
      return ProductModel.fromJson(_asJsonObject(response.data));
    } on DioException catch (error) {
      throw ProductException(_messageFor(error));
    } on FormatException catch (error) {
      throw ProductException(error.message);
    }
  }

  /// DELETE /api/v1/products/{id}
  /// Deletes a product by its numeric ID.
  Future<bool> deleteProduct(int id) async {
    try {
      final response = await _dio.delete<Object?>('products/$id');
      if (response.data == true ||
          response.statusCode == 200 ||
          response.statusCode == 204) {
        return true;
      }
      return true;
    } on DioException catch (error) {
      throw ProductException(_messageFor(error));
    } on FormatException catch (error) {
      throw ProductException(error.message);
    }
  }

  /// GET /api/v1/products/{id}/related
  /// Fetches products related to a specific product by its ID.
  Future<List<ProductModel>> getRelatedProductsById(int id) async {
    try {
      final response = await _dio.get<Object?>('products/$id/related');
      final list = _asJsonList(response.data);
      return list
          .map((item) => ProductModel.fromJson(_asJsonObject(item)))
          .toList();
    } on DioException catch (error) {
      throw ProductException(_messageFor(error));
    } on FormatException catch (error) {
      throw ProductException(error.message);
    }
  }

  /// GET /api/v1/products/slug/{slug}
  /// Fetches a single product by its slug.
  Future<ProductModel> getProductBySlug(String slug) async {
    try {
      final response = await _dio.get<Object?>('products/slug/$slug');
      return ProductModel.fromJson(_asJsonObject(response.data));
    } on DioException catch (error) {
      throw ProductException(_messageFor(error));
    } on FormatException catch (error) {
      throw ProductException(error.message);
    }
  }

  /// GET /api/v1/products/slug/{slug}/related
  /// Fetches products related to a specific product by its slug.
  Future<List<ProductModel>> getRelatedProductsBySlug(String slug) async {
    try {
      final response = await _dio.get<Object?>('products/slug/$slug/related');
      final list = _asJsonList(response.data);
      return list
          .map((item) => ProductModel.fromJson(_asJsonObject(item)))
          .toList();
    } on DioException catch (error) {
      throw ProductException(_messageFor(error));
    } on FormatException catch (error) {
      throw ProductException(error.message);
    }
  }

  /// GET /api/v1/categories
  /// Fetches all available categories.
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get<Object?>('categories');
      final list = _asJsonList(response.data);
      return list
          .map((item) => CategoryModel.fromJson(_asJsonObject(item)))
          .toList();
    } on DioException catch (error) {
      throw ProductException(_messageFor(error));
    } on FormatException catch (error) {
      throw ProductException(error.message);
    }
  }

  // --- Helper Methods ---

  static Map<String, dynamic> _asJsonObject(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw const FormatException('The server returned an invalid response object.');
  }

  static List<dynamic> _asJsonList(Object? value) {
    if (value is List) {
      return value;
    }
    throw const FormatException('The server returned an invalid response list.');
  }

  static String _messageFor(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      if (message is List && message.isNotEmpty) {
        return message.join('\n');
      }
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

class ProductException implements Exception {
  const ProductException(this.message);

  final String message;

  @override
  String toString() => message;
}
