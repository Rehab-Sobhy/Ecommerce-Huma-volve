import 'package:ecommerce_app_huma_volve/core/services/deep_link_parser.dart';
import 'package:ecommerce_app_huma_volve/core/services/deep_link_service.dart';
import 'package:ecommerce_app_huma_volve/features/details/screens/product_details_screen.dart';
import 'package:ecommerce_app_huma_volve/features/products/domain/entities/category_entity.dart';
import 'package:ecommerce_app_huma_volve/features/products/domain/entities/product_entity.dart';
import 'package:ecommerce_app_huma_volve/features/products/domain/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockProductRepository implements ProductRepository {
  MockProductRepository({
    this.productToReturn,
    this.shouldThrow = false,
  });

  ProductEntity? productToReturn;
  bool shouldThrow;

  @override
  Future<ProductEntity> getProductById(int id) async {
    if (shouldThrow) {
      throw Exception('Product with ID $id was not found.');
    }
    return productToReturn ??
        ProductEntity(
          id: id,
          title: 'Deep Linked Product $id',
          slug: 'deep-linked-product-$id',
          price: 99.99,
          description: 'Loaded directly via deep link.',
          images: const ['https://example.com/item.png'],
        );
  }

  @override
  Future<ProductEntity> getProductBySlug(String slug) async {
    if (shouldThrow) {
      throw Exception('Product with slug "$slug" was not found.');
    }
    return productToReturn ??
        ProductEntity(
          id: 77,
          title: 'Slug Product $slug',
          slug: slug,
          price: 149.00,
          description: 'Loaded by slug via deep link.',
          images: const ['https://example.com/slug-item.png'],
        );
  }

  @override
  Future<List<ProductEntity>> getRelatedProductsById(int id) async => [];

  @override
  Future<List<ProductEntity>> getRelatedProductsBySlug(String slug) async => [];

  @override
  Future<List<CategoryEntity>> getCategories() async => [];

  @override
  Future<List<ProductEntity>> getProducts({
    int? offset,
    int? limit,
    String? title,
    int? categoryId,
    double? priceMin,
    double? priceMax,
  }) async =>
      [];
}

void main() {
  group('ProductDeepLinkParser', () {
    const parser = ProductDeepLinkParser();

    test('parses custom scheme humavolve://product/42', () {
      final data = parser.parse(Uri.parse('humavolve://product/42'));
      expect(data, isNotNull);
      expect(data!.productId, 42);
      expect(data.isValid, isTrue);
    });

    test('parses custom scheme humavolve://products/42', () {
      final data = parser.parse(Uri.parse('humavolve://products/42'));
      expect(data, isNotNull);
      expect(data!.productId, 42);
    });

    test('parses custom scheme query param humavolve://product?id=105', () {
      final data = parser.parse(Uri.parse('humavolve://product?id=105'));
      expect(data, isNotNull);
      expect(data!.productId, 105);
    });

    test('parses custom scheme ecommerce://product/88', () {
      final data = parser.parse(Uri.parse('ecommerce://product/88'));
      expect(data, isNotNull);
      expect(data!.productId, 88);
    });

    test('parses universal web URL https://ecommerce.humavolve.com/products/42', () {
      final data = parser.parse(
        Uri.parse('https://ecommerce.humavolve.com/products/42'),
      );
      expect(data, isNotNull);
      expect(data!.productId, 42);
    });

    test('parses universal web URL with query param ?productId=55', () {
      final data = parser.parse(
        Uri.parse('https://ecommerce.humavolve.com/products?productId=55'),
      );
      expect(data, isNotNull);
      expect(data!.productId, 55);
    });

    test('parses slug from universal web link https://ecommerce.humavolve.com/product/modern-shoes', () {
      final data = parser.parse(
        Uri.parse('https://ecommerce.humavolve.com/product/modern-shoes'),
      );
      expect(data, isNotNull);
      expect(data!.productSlug, 'modern-shoes');
      expect(data.productId, isNull);
    });

    test('parses slug from custom scheme humavolve://product/running-jacket', () {
      final data = parser.parse(
        Uri.parse('humavolve://product/running-jacket'),
      );
      expect(data, isNotNull);
      expect(data!.productSlug, 'running-jacket');
    });

    test('returns null for unsupported schemes', () {
      expect(parser.parse(Uri.parse('ftp://ecommerce.humavolve.com/products/42')), isNull);
      expect(parser.parse(Uri.parse('mailto:test@example.com')), isNull);
    });

    test('returns null for non-supported hosts on HTTP/HTTPS', () {
      expect(parser.parse(Uri.parse('https://external-site.com/products/42')), isNull);
    });

    test('returns null for non-product routes without identifiers', () {
      expect(parser.parse(Uri.parse('humavolve://settings')), isNull);
      expect(parser.parse(Uri.parse('https://ecommerce.humavolve.com/about')), isNull);
      expect(parser.parse(Uri.parse('humavolve://product')), isNull);
    });
  });

  group('DeepLinkService link generation', () {
    test('buildWebLink produces valid universal HTTPS link', () {
      final link = DeepLinkService.buildWebLink(productId: 25);
      expect(link, 'https://ecommerce.humavolve.com/products/25');
    });

    test('buildCustomSchemeLink produces valid app scheme link', () {
      final link = DeepLinkService.buildCustomSchemeLink(productId: 25);
      expect(link, 'humavolve://products/25');
    });

    test('buildWebSlugLink and buildCustomSchemeSlugLink', () {
      expect(
        DeepLinkService.buildWebSlugLink(slug: 'black-hoodie'),
        'https://ecommerce.humavolve.com/product/black-hoodie',
      );
      expect(
        DeepLinkService.buildCustomSchemeSlugLink(slug: 'black-hoodie'),
        'humavolve://product/black-hoodie',
      );
    });
  });

  group('DeepLinkService lifecycle and routing', () {
    test('broadcasts parsed link and stores pending link when navigator is not ready', () async {
      final service = DeepLinkService();
      final captured = <ProductDeepLinkData>[];
      final sub = service.onProductDeepLink.listen(captured.add);

      final handled = service.handleUri(Uri.parse('humavolve://products/50'));
      expect(handled, isTrue);
      expect(service.pendingLink?.productId, 50);

      await Future.delayed(Duration.zero);
      expect(captured.length, 1);
      expect(captured.first.productId, 50);

      await sub.cancel();
      service.dispose();
    });
  });

  group('ProductDetailsScreen Deep Link resolution widget test', () {
    testWidgets('fetches and displays product when opened via productId', (tester) async {
      final mockRepo = MockProductRepository(
        productToReturn: const ProductEntity(
          id: 123,
          title: 'Deep Link Sneaker',
          slug: 'deep-link-sneaker',
          price: 89.99,
          description: 'A sneaker loaded directly via deep link.',
          images: ['https://example.com/sneaker.png'],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsScreen(
            productId: 123,
            repository: mockRepo,
          ),
        ),
      );

      // Initially shows loading
      expect(find.text('Opening deep link product...'), findsOneWidget);

      // Settle async fetch
      await tester.pumpAndSettle();

      // Product loaded
      expect(find.text('Deep Link Sneaker'), findsOneWidget);
      expect(find.text('\$89.99'), findsOneWidget);
      expect(find.text('A sneaker loaded directly via deep link.'), findsOneWidget);
    });

    testWidgets('displays error state and retry button when fetch fails', (tester) async {
      final mockRepo = MockProductRepository(shouldThrow: true);

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsScreen(
            productId: 999,
            repository: mockRepo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Product Not Found'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Fix repo and tap Try Again
      mockRepo.shouldThrow = false;
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Deep Linked Product 999'), findsOneWidget);
    });

    testWidgets('opens share modal when share button is tapped', (tester) async {
      final mockRepo = MockProductRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsScreen(
            productId: 42,
            repository: mockRepo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final shareBtn = find.byTooltip('Share Deep Link');
      expect(shareBtn, findsOneWidget);

      await tester.tap(shareBtn);
      await tester.pumpAndSettle();

      expect(find.text('Share Product Deep Link'), findsOneWidget);
      expect(find.text('Universal Web Link (HTTPS)'), findsOneWidget);
      expect(find.text('App Scheme Deep Link'), findsOneWidget);
      expect(find.text('https://ecommerce.humavolve.com/products/42'), findsOneWidget);
      expect(find.text('humavolve://products/42'), findsOneWidget);
    });
  });
}
