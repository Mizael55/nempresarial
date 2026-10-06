import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../products/presentation/controllers/products_controller.dart';
import '../../data/purchases_repository_impl.dart';
import '../../domain/models/supplier_model.dart';
import '../../domain/models/purchase_model.dart';

// Proveedores
final suppliersSearchQueryProvider = StateProvider<String>((ref) => '');

final suppliersListProvider = AsyncNotifierProvider<SuppliersNotifier, List<SupplierModel>>(() {
  return SuppliersNotifier();
});

class SuppliersNotifier extends AsyncNotifier<List<SupplierModel>> {
  @override
  Future<List<SupplierModel>> build() async {
    final query = ref.watch(suppliersSearchQueryProvider);
    final repo = ref.watch(purchasesRepositoryProvider);
    return repo.getSuppliers(query: query);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final query = ref.read(suppliersSearchQueryProvider);
      return ref.read(purchasesRepositoryProvider).getSuppliers(query: query);
    });
  }

  Future<SupplierModel> addSupplier(SupplierModel supplier) async {
    final created = await ref.read(purchasesRepositoryProvider).createSupplier(supplier);
    await refresh();
    return created;
  }

  Future<SupplierModel> updateSupplier(SupplierModel supplier) async {
    final updated = await ref.read(purchasesRepositoryProvider).updateSupplier(supplier);
    await refresh();
    return updated;
  }

  Future<void> deleteSupplier(String id) async {
    await ref.read(purchasesRepositoryProvider).deleteSupplier(id);
    await refresh();
  }

  Future<void> recordPayment({
    required String supplierId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    await ref.read(purchasesRepositoryProvider).recordSupplierPayment(
      supplierId: supplierId,
      amount: amount,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );
    await refresh();
  }
}

// Historial de Compras
final purchasesFilterStatusProvider = StateProvider<String>((ref) => 'all');
final purchasesSearchQueryProvider = StateProvider<String>((ref) => '');

final purchasesListProvider = AsyncNotifierProvider<PurchasesNotifier, List<PurchaseModel>>(() {
  return PurchasesNotifier();
});

class PurchasesNotifier extends AsyncNotifier<List<PurchaseModel>> {
  @override
  Future<List<PurchaseModel>> build() async {
    final status = ref.watch(purchasesFilterStatusProvider);
    final query = ref.watch(purchasesSearchQueryProvider);
    final repo = ref.watch(purchasesRepositoryProvider);
    return repo.getPurchases(status: status, query: query);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final status = ref.read(purchasesFilterStatusProvider);
      final query = ref.read(purchasesSearchQueryProvider);
      return ref.read(purchasesRepositoryProvider).getPurchases(status: status, query: query);
    });
  }

  Future<void> voidPurchase(String purchaseId, String reason) async {
    await ref.read(purchasesRepositoryProvider).voidPurchase(purchaseId, reason);
    await refresh();
    ref.read(suppliersListProvider.notifier).refresh();
    ref.read(productsControllerProvider.notifier).loadProducts();
  }
}

// Carrito / Borrador de Nueva Compra
class NewPurchaseCartItem {
  final ProductModel product;
  final double quantity;
  final double unitCost;

  const NewPurchaseCartItem({
    required this.product,
    required this.quantity,
    required this.unitCost,
  });

  double get total => quantity * unitCost;

  NewPurchaseCartItem copyWith({
    ProductModel? product,
    double? quantity,
    double? unitCost,
  }) {
    return NewPurchaseCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
    );
  }
}

class NewPurchaseState {
  final SupplierModel? selectedSupplier;
  final String customInvoiceNumber;
  final String paymentMethod; // 'transfer', 'cash', 'card', 'credit'
  final String paymentStatus; // 'paid', 'pending', 'partial'
  final String notes;
  final bool applyTax;
  final double taxRate;
  final List<NewPurchaseCartItem> items;
  final bool isSubmitting;
  final String? errorMessage;

  const NewPurchaseState({
    this.selectedSupplier,
    this.customInvoiceNumber = '',
    this.paymentMethod = 'transfer',
    this.paymentStatus = 'paid',
    this.notes = '',
    this.applyTax = true,
    this.taxRate = 18.0,
    this.items = const [],
    this.isSubmitting = false,
    this.errorMessage,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get taxAmount => applyTax ? (subtotal * (taxRate / 100.0)) : 0.0;
  double get totalAmount => subtotal + taxAmount;
  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity.toInt());

  NewPurchaseState copyWith({
    SupplierModel? selectedSupplier,
    bool clearSupplier = false,
    String? customInvoiceNumber,
    String? paymentMethod,
    String? paymentStatus,
    String? notes,
    bool? applyTax,
    double? taxRate,
    List<NewPurchaseCartItem>? items,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NewPurchaseState(
      selectedSupplier: clearSupplier ? null : (selectedSupplier ?? this.selectedSupplier),
      customInvoiceNumber: customInvoiceNumber ?? this.customInvoiceNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      applyTax: applyTax ?? this.applyTax,
      taxRate: taxRate ?? this.taxRate,
      items: items ?? this.items,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final newPurchaseControllerProvider =
    StateNotifierProvider<NewPurchaseNotifier, NewPurchaseState>((ref) {
  return NewPurchaseNotifier(ref);
});

class NewPurchaseNotifier extends StateNotifier<NewPurchaseState> {
  final Ref ref;

  NewPurchaseNotifier(this.ref) : super(const NewPurchaseState());

  void setSupplier(SupplierModel? supplier) {
    if (supplier == null) {
      state = state.copyWith(clearSupplier: true);
    } else {
      state = state.copyWith(selectedSupplier: supplier);
    }
  }

  void setCustomInvoiceNumber(String val) {
    state = state.copyWith(customInvoiceNumber: val);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setPaymentStatus(String status) {
    state = state.copyWith(paymentStatus: status);
  }

  void setNotes(String val) {
    state = state.copyWith(notes: val);
  }

  void toggleApplyTax(bool val) {
    state = state.copyWith(applyTax: val);
  }

  void addProduct(ProductModel product, {double quantity = 1, double? cost}) {
    final unitCost = cost ?? (product.costPrice > 0 ? product.costPrice : 0.0);
    final idx = state.items.indexWhere((it) => it.product.id == product.id);

    if (idx != -1) {
      final current = state.items[idx];
      final updated = current.copyWith(
        quantity: current.quantity + quantity,
        unitCost: cost ?? current.unitCost,
      );
      final list = List<NewPurchaseCartItem>.from(state.items);
      list[idx] = updated;
      state = state.copyWith(items: list);
    } else {
      final newItem = NewPurchaseCartItem(
        product: product,
        quantity: quantity,
        unitCost: unitCost,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final list = state.items.map((it) {
      if (it.product.id == productId) {
        return it.copyWith(quantity: quantity);
      }
      return it;
    }).toList();
    state = state.copyWith(items: list);
  }

  void updateCost(String productId, double cost) {
    final list = state.items.map((it) {
      if (it.product.id == productId) {
        return it.copyWith(unitCost: cost);
      }
      return it;
    }).toList();
    state = state.copyWith(items: list);
  }

  void removeItem(String productId) {
    final list = state.items.where((it) => it.product.id != productId).toList();
    state = state.copyWith(items: list);
  }

  void clear() {
    state = const NewPurchaseState();
  }

  Future<Map<String, dynamic>> submitPurchase() async {
    if (state.items.isEmpty) {
      throw Exception('Debe agregar al menos un producto a la compra');
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final itemsPayload = state.items.map((it) => {
        'product_id': it.product.id,
        'product_name': it.product.name,
        'quantity': it.quantity,
        'unit_cost': it.unitCost,
      }).toList();

      final result = await ref.read(purchasesRepositoryProvider).createPurchase(
        supplierId: state.selectedSupplier?.id,
        branchId: null,
        paymentMethod: state.paymentMethod,
        paymentStatus: state.paymentStatus,
        notes: state.notes,
        customInvoiceNumber: state.customInvoiceNumber,
        taxAmount: state.taxAmount,
        items: itemsPayload,
      );

      // Limpiar y refrescar listas
      clear();
      ref.read(purchasesListProvider.notifier).refresh();
      ref.read(suppliersListProvider.notifier).refresh();
      ref.read(productsControllerProvider.notifier).loadProducts();

      return result;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      rethrow;
    }
  }
}
