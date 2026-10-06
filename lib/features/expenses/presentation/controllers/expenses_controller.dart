import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/expense_category_model.dart';
import '../../domain/models/expense_model.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../data/expenses_repository_impl.dart';

class ExpensesState {
  final bool isLoading;
  final bool isSubmitting;
  final List<ExpenseModel> expenses;
  final List<ExpenseCategoryModel> categories;
  final String searchQuery;
  final String? selectedCategoryId;
  final String? errorMessage;
  final String? successMessage;

  const ExpensesState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.expenses = const [],
    this.categories = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.errorMessage,
    this.successMessage,
  });

  double get totalExpensesAmount {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  double get todayExpensesAmount {
    final now = DateTime.now();
    return expenses.where((e) {
      return e.createdAt.year == now.year &&
          e.createdAt.month == now.month &&
          e.createdAt.day == now.day;
    }).fold(0.0, (sum, e) => sum + e.amount);
  }

  double get thisMonthExpensesAmount {
    final now = DateTime.now();
    return expenses.where((e) {
      return e.createdAt.year == now.year && e.createdAt.month == now.month;
    }).fold(0.0, (sum, e) => sum + e.amount);
  }

  int get count => expenses.length;

  ExpensesState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<ExpenseModel>? expenses,
    List<ExpenseCategoryModel>? categories,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ExpensesState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ExpensesController extends StateNotifier<ExpensesState> {
  final ExpensesRepository _repository;

  ExpensesController(this._repository) : super(const ExpensesState()) {
    init();
  }

  Future<void> init() async {
    await loadCategories();
    await loadExpenses();
  }

  Future<void> loadCategories() async {
    try {
      final cats = await _repository.getCategories();
      state = state.copyWith(categories: cats);
    } catch (_) {}
  }

  Future<void> loadExpenses() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getExpenses(
        categoryId: state.selectedCategoryId,
        searchQuery: state.searchQuery,
      );
      state = state.copyWith(isLoading: false, expenses: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadExpenses();
  }

  void setSelectedCategory(String? categoryId) {
    if (categoryId == null || categoryId == 'all') {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
    loadExpenses();
  }

  Future<bool> createExpense({
    required String concept,
    required double amount,
    required String paymentMethod,
    String? categoryId,
    String? reference,
    String? notes,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      String? categoryName;
      String? categoryColor;
      if (categoryId != null) {
        final cat = state.categories.where((c) => c.id == categoryId).firstOrNull;
        categoryName = cat?.name;
        categoryColor = cat?.color;
      }

      final expense = ExpenseModel(
        id: '',
        categoryId: categoryId,
        categoryName: categoryName,
        categoryColor: categoryColor,
        branchId: 'a0000000-0000-0000-0000-000000000001',
        concept: concept.trim(),
        amount: amount,
        paymentMethod: paymentMethod,
        reference: reference?.trim().isNotEmpty == true ? reference!.trim() : null,
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
        createdAt: DateTime.now(),
      );

      final created = await _repository.createExpense(expense);
      state = state.copyWith(
        isSubmitting: false,
        expenses: [created, ...state.expenses],
        successMessage: 'Gasto registrado correctamente.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Error al registrar gasto: $e',
      );
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _repository.deleteExpense(id);
      state = state.copyWith(
        isSubmitting: false,
        expenses: state.expenses.where((e) => e.id != id).toList(),
        successMessage: 'Gasto eliminado.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Error al eliminar gasto: $e',
      );
      return false;
    }
  }
}

final expensesControllerProvider =
    StateNotifierProvider<ExpensesController, ExpensesState>((ref) {
  final repo = ref.watch(expensesRepositoryProvider);
  return ExpensesController(repo);
});
