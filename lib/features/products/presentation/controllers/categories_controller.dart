import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/products_repository.dart';
import '../../data/products_repository_impl.dart';

class CategoriesState {
  final bool isLoading;
  final List<CategoryModel> categories;
  final String? errorMessage;

  const CategoriesState({
    this.isLoading = false,
    this.categories = const [],
    this.errorMessage,
  });

  CategoriesState copyWith({
    bool? isLoading,
    List<CategoryModel>? categories,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoriesState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CategoriesController extends StateNotifier<CategoriesState> {
  final ProductsRepository _repository;

  CategoriesController(this._repository) : super(const CategoriesState()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categories = await _repository.getCategories();
      state = state.copyWith(isLoading: false, categories: categories);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createCategory(CategoryModel category) async {
    try {
      final created = await _repository.createCategory(category);
      state = state.copyWith(
        categories: [...state.categories, created],
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateCategory(CategoryModel category) async {
    try {
      final updated = await _repository.updateCategory(category);
      state = state.copyWith(
        categories: state.categories.map((c) => c.id == updated.id ? updated : c).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      state = state.copyWith(
        categories: state.categories.where((c) => c.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final categoriesControllerProvider =
    StateNotifierProvider<CategoriesController, CategoriesState>((ref) {
  final repo = ref.watch(productsRepositoryProvider);
  return CategoriesController(repo);
});
