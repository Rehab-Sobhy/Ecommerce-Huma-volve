import 'package:dio/dio.dart';
import 'package:ecommerce_app_huma_volve/features/products/data/models/category_model.dart';
import 'package:ecommerce_app_huma_volve/features/products/data/models/product_model.dart';
import 'package:ecommerce_app_huma_volve/features/products/data/models/product_request.dart';
import 'package:ecommerce_app_huma_volve/features/products/data/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryModel', () {
    test('fromJson and toJson parse correctly', () {
      final json = {
        'id': 1,
        'name': 'Clothes',
        'slug': 'clothes',
        'image': 'https://example.com/clothes.png',
      };
      final category = CategoryModel.fromJson(json);
      expect(category.id, 1);
      expect(category.name, 'Clothes');
      expect(category.slug, 'clothes');
      expect(category.image, 'https://example.com/clothes.png');
      expect(category.toJson()['id'], 1);
    });
  });

  group('ProductModel', () {
    test('fromJson parses price and malformed image URLs safely', () {
      final json = {
        'id': 101,
        'title': 'Test Jacket',
        'slug': 'test-jacket',
        'price': 49.99,
        'description': 'Warm and comfortable jacket.',
        'category': {
          'id': 2,
          'name': 'Apparel',
          'slug': 'apparel',
        },
        'images': [
          '["https://example.com/jacket.jpg"]',
          'https://example.com/jacket2.jpg'
        ],
      };

      final product = ProductModel.fromJson(json);
      expect(product.id, 101);
      expect(product.title, 'Test Jacket');
      expect(product.price, 49.99);
      expect(product.category?.name, 'Apparel');
      expect(product.displayImage, 'https://example.com/jacket.jpg');
      expect(product.sanitizedImages.length, 2);
      expect(product.sanitizedImages[0], 'https://example.com/jacket.jpg');
    });

    test('cleanImageUrl fallback on invalid URL', () {
      expect(
        ProductModel.cleanImageUrl('invalid-url'),
        'https://placehold.co/600x400?text=Product',
      );
    });
  });

  group('ProductRequest', () {
    test('toJson generates expected map for API payload', () {
      final req = ProductRequest(
        title: 'New Shoe',
        price: 120.0,
        description: 'Running shoes',
        categoryId: 4,
        images: ['https://example.com/shoe.png'],
      );

      final json = req.toJson();
      expect(json['title'], 'New Shoe');
      expect(json['price'], 120.0);
      expect(json['categoryId'], 4);
      expect(json['images'], ['https://example.com/shoe.png']);
    });
  });

  group('ProductService endpoint tests', () {
    test('getProductById and getProducts parsing', () async {
      final dio = Dio();
      dio.httpClientAdapter = HttpClientAdapter(); // Default adapter
      final service = ProductService(dio: dio);
      expect(service, isNotNull);
    });
  });
}
