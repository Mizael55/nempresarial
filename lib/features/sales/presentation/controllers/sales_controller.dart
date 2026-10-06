import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/sale_model.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/cart_item_model.dart';
import '../../domain/models/sale_item_model.dart';
import '../../data/sales_repository_impl.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../products/presentation/controllers/products_controller.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';

// --- Estado del Carrito y POS ---
class PosState {
  final List<CartItemModel> cart;
  final CustomerModel? selectedCustomer;
  final double globalDiscount;
  final String? selectedCategoryId;
  final String searchQuery;
  final bool isProcessing;
  final String? errorMessage;
  final Map<String, dynamic>? lastCompletedSale;

  const PosState({
    this.cart = const [],
    this.selectedCustomer,
    this.globalDiscount = 0.0,
    this.selectedCategoryId,
    this.searchQuery = '',
    this.isProcessing = false,
    this.errorMessage,
    this.lastCompletedSale,
  });

  PosState copyWith({
    List<CartItemModel>? cart,
    CustomerModel? Function()? selectedCustomer,
    double? globalDiscount,
    String? Function()? selectedCategoryId,
    String? searchQuery,
    bool? isProcessing,
    String? Function()? errorMessage,
    Map<String, dynamic>? Function()? lastCompletedSale,
  }) {
    return PosState(
      cart: cart ?? this.cart,
      selectedCustomer: selectedCustomer != null ? selectedCustomer() : this.selectedCustomer,
      globalDiscount: globalDiscount ?? this.globalDiscount,
      selectedCategoryId: selectedCategoryId != null ? selectedCategoryId() : this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      lastCompletedSale: lastCompletedSale != null ? lastCompletedSale() : this.lastCompletedSale,
    );
  }

  double get subtotal => cart.fold(0.0, (sum, item) => sum + item.netSubtotal);
  double get totalTax => cart.fold(0.0, (sum, item) => sum + item.taxAmount);
  double get totalGross => subtotal + totalTax;
  double get totalWithDiscount => (totalGross - globalDiscount).clamp(0.0, double.infinity);
  int get totalItemsCount => cart.fold(0, (sum, item) => sum + item.quantity.toInt());
}

class PosNotifier extends StateNotifier<PosState> {
  final Ref _ref;

  PosNotifier(this._ref) : super(const PosState());

  void addToCart(ProductModel product, {double? defaultTaxRate}) {
    double businessTaxRate = 18.0;
    try {
      final settings = _ref.read(onboardingControllerProvider).settings;
      businessTaxRate = settings.taxRate;
    } catch (_) {}

    final effectiveTaxRate = (product.isTaxable && businessTaxRate > 0)
        ? businessTaxRate
        : 0.0;

    final existingIndex = state.cart.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      final updatedCart = List<CartItemModel>.from(state.cart);
      final currentItem = updatedCart[existingIndex];
      updatedCart[existingIndex] = currentItem.copyWith(
        quantity: currentItem.quantity + 1.0,
        taxRate: effectiveTaxRate,
      );
      state = state.copyWith(cart: updatedCart);
    } else {
      final newItem = CartItemModel(
        product: product,
        quantity: 1.0,
        unitPrice: product.salePrice,
        taxRate: effectiveTaxRate,
      );
      state = state.copyWith(cart: [...state.cart, newItem]);
    }
  }

  void syncCartTaxWithSettings() {
    double businessTaxRate = 18.0;
    try {
      final settings = _ref.read(onboardingControllerProvider).settings;
      businessTaxRate = settings.taxRate;
    } catch (_) {}

    final updatedCart = state.cart.map((item) {
      final effectiveRate = (item.product.isTaxable && businessTaxRate > 0)
          ? businessTaxRate
          : 0.0;
      return item.copyWith(taxRate: effectiveRate);
    }).toList();
    state = state.copyWith(cart: updatedCart);
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final updatedCart = state.cart.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(cart: updatedCart);
  }

  void updateUnitPrice(String productId, double price) {
    final updatedCart = state.cart.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(unitPrice: price.clamp(0.0, double.infinity));
      }
      return item;
    }).toList();

    state = state.copyWith(cart: updatedCart);
  }

  void updateItemDiscount(String productId, double discount) {
    final updatedCart = state.cart.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(discountAmount: discount.clamp(0.0, double.infinity));
      }
      return item;
    }).toList();

    state = state.copyWith(cart: updatedCart);
  }

  void removeFromCart(String productId) {
    state = state.copyWith(
      cart: state.cart.where((item) => item.product.id != productId).toList(),
    );
  }

  void clearCart() {
    state = state.copyWith(
      cart: const [],
      globalDiscount: 0.0,
      selectedCustomer: () => null,
      errorMessage: () => null,
      lastCompletedSale: () => null,
    );
  }

  void setCustomer(CustomerModel? customer) {
    state = state.copyWith(selectedCustomer: () => customer);
  }

  void setGlobalDiscount(double discount) {
    state = state.copyWith(globalDiscount: discount.clamp(0.0, double.infinity));
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryFilter(String? categoryId) {
    state = state.copyWith(selectedCategoryId: () => categoryId);
  }

  Future<Map<String, dynamic>?> checkout({
    required String paymentMethod,
    double receivedAmount = 0.0,
    String? notes,
  }) async {
    if (state.cart.isEmpty) {
      state = state.copyWith(errorMessage: () => 'El carrito está vacío');
      return null;
    }

    state = state.copyWith(isProcessing: true, errorMessage: () => null);

    try {
      final user = _ref.read(authControllerProvider).user;
      final repo = _ref.read(salesRepositoryProvider);

      final total = state.totalWithDiscount;
      final changeAmount = (receivedAmount - total).clamp(0.0, double.infinity);

      final result = await repo.completeSale(
        customerId: state.selectedCustomer?.id,
        items: state.cart,
        paymentMethod: paymentMethod,
        paymentStatus: paymentMethod == 'credit' ? 'pending' : 'paid',
        globalDiscount: state.globalDiscount,
        notes: notes,
        createdBy: user?.id,
      );

      final completedSaleData = {
        ...result,
        'received_amount': receivedAmount,
        'change_amount': changeAmount,
        'customer_name': state.selectedCustomer?.name ?? 'Consumidor Final',
        'customer_tax_id': state.selectedCustomer?.taxId,
        'payment_method': paymentMethod,
        'items': state.cart.map((e) => {
          'name': e.product.name,
          'quantity': e.quantity,
          'price': e.unitPrice,
          'subtotal': e.netSubtotal,
          'tax': e.taxAmount,
          'total': e.totalAmount,
        }).toList(),
      };

      // Limpiar carrito y guardar venta completada para el ticket
      state = state.copyWith(
        cart: const [],
        globalDiscount: 0.0,
        selectedCustomer: () => null,
        isProcessing: false,
        lastCompletedSale: () => completedSaleData,
      );

      // Invalidar proveedores y recargar inventario, productos y dashboard en tiempo real
      _ref.invalidate(salesListProvider);
      _ref.read(productsControllerProvider.notifier).loadProducts();
      _ref.read(inventoryControllerProvider.notifier).loadData();
      _ref.read(dashboardControllerProvider.notifier).loadMetrics();

      return completedSaleData;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: () => e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  void dismissLastSale() {
    state = state.copyWith(lastCompletedSale: () => null);
  }
}

final posControllerProvider = StateNotifierProvider<PosNotifier, PosState>((ref) {
  return PosNotifier(ref);
});

// --- Proveedor de Filtro de Historial de Ventas ---
class SalesFilterState {
  final String status;
  final String searchQuery;

  const SalesFilterState({this.status = 'all', this.searchQuery = ''});

  SalesFilterState copyWith({String? status, String? searchQuery}) {
    return SalesFilterState(
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final salesFilterProvider = StateProvider<SalesFilterState>((ref) {
  return const SalesFilterState();
});

final salesListProvider = FutureProvider<List<SaleModel>>((ref) async {
  final repo = ref.watch(salesRepositoryProvider);
  final filter = ref.watch(salesFilterProvider);
  return repo.getSales(
    status: filter.status,
    searchQuery: filter.searchQuery,
    limit: 100,
  );
});

final customersListProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final repo = ref.watch(salesRepositoryProvider);
  return repo.getCustomers();
});

final saleDetailsProvider = FutureProvider.family<List<SaleItemModel>, String>((ref, saleId) async {
  final repo = ref.watch(salesRepositoryProvider);
  return repo.getSaleItems(saleId);
});
