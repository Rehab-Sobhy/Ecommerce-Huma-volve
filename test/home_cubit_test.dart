import 'package:ecommerce_app_huma_volve/features/home/domain/usecases/get_categories_usecase.dart';
import 'package:ecommerce_app_huma_volve/features/home/domain/usecases/get_products_usecase.dart';
import 'package:ecommerce_app_huma_volve/features/home/presentation/cubit/home_cubit.dart';
import 'package:ecommerce_app_huma_volve/features/home/presentation/cubit/home_state.dart';
import 'package:ecommerce_app_huma_volve/features/products/domain/entities/category_entity.dart';
import 'package:ecommerce_app_huma_volve/features/products/domain/entities/product_entity.dart';
import 'package:ecommerce_app_huma_volve/features/products/domain/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProductRepository implements ProductRepository {
  List<ProductEntity> productsToReturn = [];
  List<CategoryEntity> categoriesToReturn = [];
  bool shouldThrowError = false;
  int? lastOffset;
  int? lastLimit;
  int? lastCategoryId;
  String? lastTitle;

  @override
  Future<List<ProductEntity>> getProducts({
    int? offset,
    int? limit,
    String? title,
    int? categoryId,
    double? priceMin,
    double? priceMax,
  }) async {
    lastOffset = offset;
    lastLimit = limit;
    lastCategoryId = categoryId;
    lastTitle = title;
    if (shouldThrowError) {
      throw Exception('Network error');
    }
    return productsToReturn;
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    return categoriesToReturn;
  }

  @override
  Future<ProductEntity> getProductById(int id) async => throw UnimplementedError();

  @override
  Future<ProductEntity> getProductBySlug(String slug) async => throw UnimplementedError();

  @override
  Future<List<ProductEntity>> getRelatedProductsById(int id) async => throw UnimplementedError();

  @override
  Future<List<ProductEntity>> getRelatedProductsBySlug(String slug) async => throw UnimplementedError();
}

ProductEntity _makeProduct(int id) {
  return ProductEntity(
    id: id,
    title: 'Product $id',
    slug: 'product-$id',
    price: 19.99 * id,
    description: 'Description for product $id',
    images: const ['https://example.com/p.png'],
  );
}

void main() {
  late FakeProductRepository repo;
  late HomeCubit cubit;

  setUp(() {
    repo = FakeProductRepository();
    cubit = HomeCubit(
      getProducts: GetProductsUseCase(repo),
      getCategories: GetCategoriesUseCase(repo),
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('HomeCubit Pagination', () {
    test('initial state is HomeInitial', () {
      expect(cubit.state, isA<HomeInitial>());
    });

    test('loadInitialData requests offset 0 and limit 10', () async {
      repo.productsToReturn = List.generate(10, (i) => _makeProduct(i + 1));
      repo.categoriesToReturn = [
        const CategoryEntity(id: 1, name: 'Clothes', slug: 'clothes', image: 'img'),
      ];

      await cubit.loadInitialData();

      expect(repo.lastOffset, 0);
      expect(repo.lastLimit, HomeCubit.pageSize);
      expect(cubit.state, isA<HomeLoaded>());
      final state = cubit.state as HomeLoaded;
      expect(state.products.length, 10);
      expect(state.hasReachedMax, isFalse);
      expect(state.isLoadingMore, isFalse);
    });

    test('loadInitialData sets hasReachedMax to true when fewer than pageSize products are returned', () async {
      repo.productsToReturn = List.generate(5, (i) => _makeProduct(i + 1));

      await cubit.loadInitialData();

      final state = cubit.state as HomeLoaded;
      expect(state.products.length, 5);
      expect(state.hasReachedMax, isTrue);
    });

    test('loadMoreProducts fetches next page using current products count as offset', () async {
      // First page
      repo.productsToReturn = List.generate(10, (i) => _makeProduct(i + 1));
      await cubit.loadInitialData();

      // Second page
      repo.productsToReturn = List.generate(10, (i) => _makeProduct(i + 11));
      await cubit.loadMoreProducts();

      expect(repo.lastOffset, 10);
      expect(repo.lastLimit, HomeCubit.pageSize);

      final state = cubit.state as HomeLoaded;
      expect(state.products.length, 20);
      expect(state.products.first.id, 1);
      expect(state.products.last.id, 20);
      expect(state.isLoadingMore, isFalse);
      expect(state.hasReachedMax, isFalse);
    });

    test('loadMoreProducts sets hasReachedMax when next page returns empty', () async {
      repo.productsToReturn = List.generate(10, (i) => _makeProduct(i + 1));
      await cubit.loadInitialData();

      repo.productsToReturn = [];
      await cubit.loadMoreProducts();

      final state = cubit.state as HomeLoaded;
      expect(state.products.length, 10);
      expect(state.hasReachedMax, isTrue);
    });

    test('loadMoreProducts does not trigger if hasReachedMax is true', () async {
      repo.productsToReturn = List.generate(4, (i) => _makeProduct(i + 1));
      await cubit.loadInitialData();

      repo.lastOffset = null;
      await cubit.loadMoreProducts();

      // Should not have attempted to fetch
      expect(repo.lastOffset, isNull);
    });

    test('loadMoreProducts handles error cleanly without losing loaded products', () async {
      repo.productsToReturn = List.generate(10, (i) => _makeProduct(i + 1));
      await cubit.loadInitialData();

      repo.shouldThrowError = true;
      await cubit.loadMoreProducts();

      final state = cubit.state as HomeLoaded;
      expect(state.products.length, 10);
      expect(state.isLoadingMore, isFalse);
      expect(state.loadMoreError, contains('Network error'));
    });

    test('selectCategory resets offset to 0 and re-evaluates hasReachedMax', () async {
      repo.productsToReturn = List.generate(10, (i) => _makeProduct(i + 1));
      repo.categoriesToReturn = [
        const CategoryEntity(id: 42, name: 'Shoes', slug: 'shoes', image: 'img'),
      ];
      await cubit.loadInitialData();

      repo.productsToReturn = List.generate(3, (i) => _makeProduct(i + 100));
      await cubit.selectCategory(1);

      expect(repo.lastOffset, 0);
      expect(repo.lastCategoryId, 42);

      final state = cubit.state as HomeLoaded;
      expect(state.products.length, 3);
      expect(state.hasReachedMax, isTrue);
      expect(state.selectedCategoryIndex, 1);
    });

    test('search resets offset to 0 and re-evaluates hasReachedMax', () async {
      repo.productsToReturn = List.generate(10, (i) => _makeProduct(i + 1));
      await cubit.loadInitialData();

      repo.productsToReturn = [_makeProduct(99)];
      await cubit.search('jacket');

      expect(repo.lastOffset, 0);
      expect(repo.lastTitle, 'jacket');

      final state = cubit.state as HomeLoaded;
      expect(state.products.length, 1);
      expect(state.hasReachedMax, isTrue);
    });

    test('refresh resets pagination state', () async {
      repo.productsToReturn = List.generate(10, (i) => _makeProduct(i + 1));
      await cubit.loadInitialData();

      repo.productsToReturn = List.generate(10, (i) => _makeProduct(i + 50));
      await cubit.refresh();

      expect(repo.lastOffset, 0);
      final state = cubit.state as HomeLoaded;
      expect(state.products.length, 10);
      expect(state.products.first.id, 50);
      expect(state.hasReachedMax, isFalse);
    });
  });
}
