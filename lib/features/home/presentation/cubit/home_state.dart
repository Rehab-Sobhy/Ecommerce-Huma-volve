import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/category_entity.dart';
import '../../../products/domain/entities/product_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Both products and categories are being loaded for the first time.
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Data loaded successfully.
class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.products,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.searchQuery,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.loadMoreError,
  });

  final List<ProductEntity> products;
  final List<CategoryEntity> categories;
  final int selectedCategoryIndex;
  final String searchQuery;

  /// True when silently refreshing in the background (pull-to-refresh).
  final bool isRefreshing;

  /// True when fetching the next page of products.
  final bool isLoadingMore;

  /// True when no more products are available from the server.
  final bool hasReachedMax;

  /// Error message if loading the next page failed.
  final String? loadMoreError;

  HomeLoaded copyWith({
    List<ProductEntity>? products,
    List<CategoryEntity>? categories,
    int? selectedCategoryIndex,
    String? searchQuery,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasReachedMax,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return HomeLoaded(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryIndex: selectedCategoryIndex ?? this.selectedCategoryIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      loadMoreError: clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }

  @override
  List<Object?> get props => [
        products,
        categories,
        selectedCategoryIndex,
        searchQuery,
        isRefreshing,
        isLoadingMore,
        hasReachedMax,
        loadMoreError,
      ];
}

/// An error occurred while loading.
class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Products are reloading (e.g. after category/search change) while categories
/// are already available.
class HomeProductsLoading extends HomeState {
  const HomeProductsLoading({
    required this.categories,
    required this.selectedCategoryIndex,
    required this.searchQuery,
  });

  final List<CategoryEntity> categories;
  final int selectedCategoryIndex;
  final String searchQuery;

  @override
  List<Object?> get props => [categories, selectedCategoryIndex, searchQuery];
}
