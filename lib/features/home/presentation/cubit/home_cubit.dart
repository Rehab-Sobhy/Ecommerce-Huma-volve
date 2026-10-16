import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../products/domain/entities/category_entity.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import 'home_state.dart';

/// Manages the business logic for the Home screen.
/// The screen calls methods here; the Cubit emits states.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required this._getProducts,
    required this._getCategories,
  }) : super(const HomeInitial());

  final GetProductsUseCase _getProducts;
  final GetCategoriesUseCase _getCategories;

  // Page size for paginated requests
  static const int pageSize = 10;

  // Cached filter state so products can be re-fetched after category/search change
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  /// Loads categories and initial products in parallel.
  Future<void> loadInitialData() async {
    emit(const HomeLoading());
    try {
      final categoriesFuture = _getCategories();
      final productsFuture = _getProducts(offset: 0, limit: pageSize);
      final List<CategoryEntity> categories = await categoriesFuture;
      final List<ProductEntity> products = await productsFuture;

      emit(HomeLoaded(
        categories: categories,
        products: products,
        selectedCategoryIndex: _selectedCategoryIndex,
        searchQuery: _searchQuery,
        hasReachedMax: products.length < pageSize,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// Refreshes both data sets silently (used for pull-to-refresh).
  Future<void> refresh() async {
    final current = state;
    if (current is HomeLoaded) {
      emit(current.copyWith(isRefreshing: true, clearLoadMoreError: true));
    }
    try {
      final categoryId = _resolvedCategoryId(
        current is HomeLoaded ? current.categories : [],
      );

      final categoriesFuture = _getCategories();
      final productsFuture = _getProducts(
        offset: 0,
        limit: pageSize,
        categoryId: categoryId,
        title: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      final List<CategoryEntity> categories = await categoriesFuture;
      final List<ProductEntity> products = await productsFuture;

      emit(HomeLoaded(
        categories: categories,
        products: products,
        selectedCategoryIndex: _selectedCategoryIndex,
        searchQuery: _searchQuery,
        hasReachedMax: products.length < pageSize,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// Filters products by category chip index.
  Future<void> selectCategory(int index) async {
    if (_selectedCategoryIndex == index) return;
    _selectedCategoryIndex = index;

    final current = state;
    final List<CategoryEntity> categories =
        current is HomeLoaded ? current.categories : [];

    emit(HomeProductsLoading(
      categories: categories,
      selectedCategoryIndex: _selectedCategoryIndex,
      searchQuery: _searchQuery,
    ));

    try {
      final List<ProductEntity> products = await _getProducts(
        offset: 0,
        limit: pageSize,
        categoryId: _resolvedCategoryId(categories),
        title: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      emit(HomeLoaded(
        categories: categories,
        products: products,
        selectedCategoryIndex: _selectedCategoryIndex,
        searchQuery: _searchQuery,
        hasReachedMax: products.length < pageSize,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// Filters products by search query.
  Future<void> search(String query) async {
    _searchQuery = query.trim();

    final current = state;
    final List<CategoryEntity> categories =
        current is HomeLoaded ? current.categories : [];

    emit(HomeProductsLoading(
      categories: categories,
      selectedCategoryIndex: _selectedCategoryIndex,
      searchQuery: _searchQuery,
    ));

    try {
      final List<ProductEntity> products = await _getProducts(
        offset: 0,
        limit: pageSize,
        categoryId: _resolvedCategoryId(categories),
        title: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      emit(HomeLoaded(
        categories: categories,
        products: products,
        selectedCategoryIndex: _selectedCategoryIndex,
        searchQuery: _searchQuery,
        hasReachedMax: products.length < pageSize,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// Called after a product is added/edited/deleted to sync the list.
  Future<void> reloadProducts() async {
    final current = state;
    final List<CategoryEntity> categories =
        current is HomeLoaded ? current.categories : [];

    emit(HomeProductsLoading(
      categories: categories,
      selectedCategoryIndex: _selectedCategoryIndex,
      searchQuery: _searchQuery,
    ));

    try {
      final List<ProductEntity> products = await _getProducts(
        offset: 0,
        limit: pageSize,
        categoryId: _resolvedCategoryId(categories),
        title: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      emit(HomeLoaded(
        categories: categories,
        products: products,
        selectedCategoryIndex: _selectedCategoryIndex,
        searchQuery: _searchQuery,
        hasReachedMax: products.length < pageSize,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// Loads the next page of products (pagination / infinite scroll).
  Future<void> loadMoreProducts() async {
    final current = state;
    if (current is! HomeLoaded) return;
    if (current.isLoadingMore || current.hasReachedMax || current.isRefreshing) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    try {
      final categoryId = _resolvedCategoryId(current.categories);
      final newProducts = await _getProducts(
        offset: current.products.length,
        limit: pageSize,
        categoryId: categoryId,
        title: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      final existingIds = current.products.map((p) => p.id).toSet();
      final uniqueNewProducts =
          newProducts.where((p) => !existingIds.contains(p.id)).toList();

      emit(current.copyWith(
        products: [...current.products, ...uniqueNewProducts],
        isLoadingMore: false,
        hasReachedMax: newProducts.isEmpty || newProducts.length < pageSize,
      ));
    } catch (e) {
      emit(current.copyWith(
        isLoadingMore: false,
        loadMoreError: e.toString(),
      ));
    }
  }

  // Resolves the category ID from the currently selected index.
  int? _resolvedCategoryId(List<CategoryEntity> categories) {
    if (_selectedCategoryIndex > 0 &&
        _selectedCategoryIndex - 1 < categories.length) {
      return categories[_selectedCategoryIndex - 1].id;
    }
    return null;
  }
}
