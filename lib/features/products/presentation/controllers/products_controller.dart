import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repositories/products_repository.dart';
import '../../data/products_repository_impl.dart';

enum ProductSortBy { nameAsc, nameDesc, priceAsc, priceDesc, stockAsc, stockDesc }

class ProductsState {
  final bool isLoading;
  final List<ProductModel> products;
  final String searchQuery;
  final String? selectedCategoryId;
  final bool? filterOnlyActive;
  final ProductSortBy sortBy;
  final String? errorMessage;

  const ProductsState({
    this.isLoading = false,
    this.products = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.filterOnlyActive = true,
    this.sortBy = ProductSortBy.nameAsc,
    this.errorMessage,
  });

  // Filtered & Sorted items
  List<ProductModel> get filteredProducts {
    var list = List<ProductModel>.from(products);

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          (p.barcode != null && p.barcode!.toLowerCase().contains(q))).toList();
    }

    if (selectedCategoryId != null && selectedCategoryId!.isNotEmpty) {
      list = list.where((p) => p.categoryId == selectedCategoryId).toList();
    }

    if (filterOnlyActive == true) {
      list = list.where((p) => p.isActive).toList();
    }

    switch (sortBy) {
      case ProductSortBy.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ProductSortBy.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ProductSortBy.priceAsc:
        list.sort((a, b) => a.salePrice.compareTo(b.salePrice));
        break;
      case ProductSortBy.priceDesc:
        list.sort((a, b) => b.salePrice.compareTo(a.salePrice));
        break;
      case ProductSortBy.stockAsc:
        list.sort((a, b) => a.currentStock.compareTo(b.currentStock));
        break;
      case ProductSortBy.stockDesc:
        list.sort((a, b) => b.currentStock.compareTo(a.currentStock));
        break;
    }

    return list;
  }

  // Dashboard stats for the products view
  int get totalProductsCount => products.length;
  double get totalInventoryValue =>
      products.fold(0.0, (sum, p) => sum + (p.costPrice * p.currentStock));
  double get totalExpectedProfit =>
      products.fold(0.0, (sum, p) => sum + p.totalExpectedProfit);
  double get totalExpectedRevenue =>
      products.fold(0.0, (sum, p) => sum + p.totalExpectedRevenue);
  int get lowStockCount => products.where((p) => p.isLowStock).length;
  int get outOfStockCount => products.where((p) => p.isOutOfStock).length;

  ProductsState copyWith({
    bool? isLoading,
    List<ProductModel>? products,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearCategory = false,
    bool? filterOnlyActive,
    ProductSortBy? sortBy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductsState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      filterOnlyActive: filterOnlyActive ?? this.filterOnlyActive,
      sortBy: sortBy ?? this.sortBy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProductsController extends StateNotifier<ProductsState> {
  final ProductsRepository _repository;

  ProductsController(this._repository) : super(const ProductsState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getProducts(
        searchQuery: state.searchQuery,
        categoryId: state.selectedCategoryId,
        onlyActive: state.filterOnlyActive,
      );
      state = state.copyWith(isLoading: false, products: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedCategory(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  void setSortBy(ProductSortBy sort) {
    state = state.copyWith(sortBy: sort);
  }

  Future<bool> createProduct(ProductModel product, {double initialStock = 0.0}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _repository.createProduct(product, initialStock: initialStock);
      state = state.copyWith(
        isLoading: false,
        products: [created, ...state.products],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateProduct(product);
      final index = state.products.indexWhere((p) => p.id == updated.id);
      if (index != -1) {
        final newProducts = List<ProductModel>.from(state.products);
        newProducts[index] = updated;
        state = state.copyWith(isLoading: false, products: newProducts);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.deleteProduct(id);
      state = state.copyWith(
        isLoading: false,
        products: state.products.where((p) => p.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final productsControllerProvider =
    StateNotifierProvider<ProductsController, ProductsState>((ref) {
  final repo = ref.watch(productsRepositoryProvider);
  return ProductsController(repo);
});
