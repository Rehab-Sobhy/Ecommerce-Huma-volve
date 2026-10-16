import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/dummy_data.dart';
import '../../../../core/theme.dart';
import '../../../products/data/repositories/product_repository_impl.dart';
import '../../../products/domain/entities/category_entity.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/widgets/product_form_dialog.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/product_card.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

/// HomeScreen now owns only UI logic.
/// All data-fetching and state transitions happen inside [HomeCubit].
class HomeScreen extends StatelessWidget {
  /// Optionally inject a custom [ProductRepository] for testing.
  const HomeScreen({super.key, this.repository});

  final ProductRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? ProductRepositoryImpl();
    return BlocProvider(
      create: (_) => HomeCubit(
        getProducts: GetProductsUseCase(repo),
        getCategories: GetCategoriesUseCase(repo),
      )..loadInitialData(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      context.read<HomeCubit>().loadMoreProducts();
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200);
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      context.read<HomeCubit>().search(value);
    });
  }

  Future<void> _openAddProductModal(
    BuildContext context,
    List<CategoryEntity> categories,
  ) async {
    final newProduct = await ProductFormDialog.show(
      context,
      categories: categories,
    );
    if (newProduct != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created "${newProduct.title}" successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.read<HomeCubit>().reloadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is HomeProductsLoading) {
          _scrollToTop();
        }
      },
      builder: (context, state) {
        final categories = _categoriesFrom(state);
        final categoryNames = ['All', ...categories.map((c) => c.name)];
        final selectedIndex = _selectedIndexFrom(state);

        return Scaffold(
          backgroundColor: AppTheme.background,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddProductModal(context, categories),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().refresh(),
              color: AppTheme.primary,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Top bar ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.menu, color: AppTheme.primary),
                              ),
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(dummyUser.profilePictureUrl),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Explore',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(fontSize: 36),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Best trendy collection!',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 28),

                          // --- Search bar ---
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              onSubmitted: (v) =>
                                  context.read<HomeCubit>().search(v),
                              decoration: InputDecoration(
                                hintText: 'Search products by title...',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                prefixIcon:
                                    const Icon(Icons.search, color: Colors.grey),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.grey),
                                        onPressed: () {
                                          _searchController.clear();
                                          context.read<HomeCubit>().search('');
                                        },
                                      )
                                    : Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.tune,
                                            color: Colors.white, size: 20),
                                        ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // --- Category chips ---
                          if (state is HomeLoading)
                            _buildCategorySkeletons()
                          else
                            SizedBox(
                              height: 44,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: categoryNames.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  return CategoryChip(
                                    label: categoryNames[index],
                                    isSelected: selectedIndex == index,
                                    onTap: () => context
                                        .read<HomeCubit>()
                                        .selectCategory(index),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // --- Products section ---
                  _buildProductsSliver(context, state),

                  // --- Pagination footer ---
                  _buildPaginationFooterSliver(context, state),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsSliver(BuildContext context, HomeState state) {
    if (state is HomeLoading || state is HomeProductsLoading) {
      return _buildProductSkeletonSliver();
    }
    if (state is HomeError) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<HomeCubit>().loadInitialData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (state is HomeLoaded) {
      if (state.isRefreshing) return _buildProductSkeletonSliver();
      if (state.products.isEmpty) return _buildEmptySliver(context);
      return _buildProductGridSliver(state.products);
    }
    return _buildProductSkeletonSliver();
  }

  Widget _buildProductGridSliver(List<ProductEntity> products) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ProductCard(
            product: products[index],
            onProductChanged: () =>
                context.read<HomeCubit>().reloadProducts(),
          ),
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildPaginationFooterSliver(BuildContext context, HomeState state) {
    if (state is! HomeLoaded) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (state.products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (state.isLoadingMore) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Loading more products...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.loadMoreError != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
          child: Center(
            child: Column(
              children: [
                const Text(
                  'Failed to load more products.',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.read<HomeCubit>().loadMoreProducts(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.hasReachedMax) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 1,
                  width: 40,
                  color: Colors.grey.shade300,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'No more products',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  width: 40,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildProductSkeletonSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => _buildSkeletonCard(),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildEmptySliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Try selecting another category or searching something else.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySkeletons() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => Container(
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                      height: 14,
                      width: double.infinity,
                      color: Colors.grey.shade200),
                  Container(height: 14, width: 70, color: Colors.grey.shade200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers to extract state fields safely ---

  List<CategoryEntity> _categoriesFrom(HomeState state) {
    if (state is HomeLoaded) return state.categories;
    if (state is HomeProductsLoading) return state.categories;
    return [];
  }

  int _selectedIndexFrom(HomeState state) {
    if (state is HomeLoaded) return state.selectedCategoryIndex;
    if (state is HomeProductsLoading) return state.selectedCategoryIndex;
    return 0;
  }

}
