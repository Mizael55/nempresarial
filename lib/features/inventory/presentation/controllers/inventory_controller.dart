import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/inventory_item_model.dart';
import '../../domain/models/inventory_movement_model.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/inventory_repository_impl.dart';

class InventoryState {
  final bool isLoading;
  final bool isSubmitting;
  final List<InventoryItemModel> items;
  final List<InventoryMovementModel> movements;
  final Map<String, dynamic> metrics;
  final String searchQuery;
  final String? selectedCategoryId;
  final bool onlyLowStock;
  final int selectedTab; // 0 = Stock actual, 1 = Kardex / Movimientos
  final String? errorMessage;
  final String? successMessage;

  const InventoryState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.items = const [],
    this.movements = const [],
    this.metrics = const {},
    this.searchQuery = '',
    this.selectedCategoryId,
    this.onlyLowStock = false,
    this.selectedTab = 0,
    this.errorMessage,
    this.successMessage,
  });

  InventoryState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<InventoryItemModel>? items,
    List<InventoryMovementModel>? movements,
    Map<String, dynamic>? metrics,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearCategory = false,
    bool? onlyLowStock,
    int? selectedTab,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      items: items ?? this.items,
      movements: movements ?? this.movements,
      metrics: metrics ?? this.metrics,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      onlyLowStock: onlyLowStock ?? this.onlyLowStock,
      selectedTab: selectedTab ?? this.selectedTab,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class InventoryController extends StateNotifier<InventoryState> {
  final InventoryRepository _repository;

  InventoryController(this._repository) : super(const InventoryState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final itemsFuture = _repository.getInventoryOverview(
        searchQuery: state.searchQuery.isEmpty ? null : state.searchQuery,
        categoryId: state.selectedCategoryId,
        onlyLowStock: state.onlyLowStock ? true : null,
      );

      final movementsFuture = _repository.getMovements();
      final metricsFuture = _repository.getInventoryMetrics();

      final results = await Future.wait([itemsFuture, movementsFuture, metricsFuture]);

      state = state.copyWith(
        isLoading: false,
        items: results[0] as List<InventoryItemModel>,
        movements: results[1] as List<InventoryMovementModel>,
        metrics: results[2] as Map<String, dynamic>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al sincronizar datos de inventario.',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadData();
  }

  void setCategory(String? categoryId) {
    if (state.selectedCategoryId == categoryId) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
    loadData();
  }

  void toggleLowStockFilter() {
    state = state.copyWith(onlyLowStock: !state.onlyLowStock);
    loadData();
  }

  void setSelectedTab(int tab) {
    state = state.copyWith(selectedTab: tab);
  }

  Future<bool> recordMovement({
    required String productId,
    required String movementType,
    required double quantity,
    double? unitCost,
    String? notes,
    String? branchId,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.recordMovement(
        productId: productId,
        movementType: movementType,
        quantity: quantity,
        unitCost: unitCost,
        notes: notes,
        branchId: branchId,
      );

      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Movimiento de inventario registrado correctamente.',
      );
      await loadData();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final inventoryControllerProvider =
    StateNotifierProvider<InventoryController, InventoryState>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return InventoryController(repository);
});
