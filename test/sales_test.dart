import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nempresarial/features/products/domain/models/product_model.dart';
import 'package:nempresarial/features/sales/domain/models/sale_model.dart';
import 'package:nempresarial/features/sales/domain/models/sale_item_model.dart';
import 'package:nempresarial/features/sales/presentation/controllers/sales_controller.dart';
import 'package:nempresarial/features/sales/presentation/screens/sales_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('POS & Sales Unit Tests', () {
    final testProduct = ProductModel(
      id: 'prod-001',
      name: 'Refresco Cola 2L',
      sku: 'BEB-001',
      salePrice: 100.0,
      costPrice: 65.0,
      minStock: 5.0,
      currentStock: 25.0,
      isTaxable: true,
      taxRate: 18.0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    test('PosNotifier cart additions and calculations', () {
      final container = ProviderContainer();
      final notifier = container.read(posControllerProvider.notifier);

      expect(container.read(posControllerProvider).cart, isEmpty);

      // 1. Agregar producto al carrito
      notifier.addToCart(testProduct);
      var state = container.read(posControllerProvider);
      expect(state.cart.length, 1);
      expect(state.cart.first.quantity, 1.0);
      expect(state.subtotal, 100.0);
      expect(state.totalTax, 18.0);
      expect(state.totalWithDiscount, 118.0);

      // 2. Incrementar cantidad (+1)
      notifier.addToCart(testProduct);
      state = container.read(posControllerProvider);
      expect(state.cart.first.quantity, 2.0);
      expect(state.subtotal, 200.0);
      expect(state.totalTax, 36.0);
      expect(state.totalWithDiscount, 236.0);

      // 3. Aplicar descuento global de $36
      notifier.setGlobalDiscount(36.0);
      state = container.read(posControllerProvider);
      expect(state.totalWithDiscount, 200.0);

      // 4. Vaciar carrito
      notifier.clearCart();
      state = container.read(posControllerProvider);
      expect(state.cart, isEmpty);
      expect(state.totalWithDiscount, 0.0);
    });

    test('SaleModel fromJson deserializes correctly', () {
      final json = {
        'id': 'sale-123',
        'invoice_number': 'FAC-000001',
        'branch_id': 'branch-001',
        'branch_name': 'Sucursal Principal',
        'customer_name': 'Cliente VIP',
        'customer_tax_id': '131-00000-0',
        'status': 'completed',
        'subtotal': 500.0,
        'discount_amount': 0.0,
        'tax_amount': 90.0,
        'total_amount': 590.0,
        'cost_amount': 300.0,
        'payment_method': 'cash',
        'payment_status': 'paid',
        'cashier_name': 'Juan Cajero',
        'created_at': DateTime.now().toIso8601String(),
        'items_count': 3,
      };

      final model = SaleModel.fromJson(json);
      expect(model.id, 'sale-123');
      expect(model.invoiceNumber, 'FAC-000001');
      expect(model.totalAmount, 590.0);
      expect(model.isCompleted, isTrue);
      expect(model.isCancelled, isFalse);
    });

    test('SaleItemModel fromJson deserializes correctly', () {
      final json = {
        'id': 'item-123',
        'sale_id': 'sale-123',
        'product_id': 'prod-001',
        'product_name': 'Arroz Premium 10lb',
        'quantity': 2.0,
        'unit_cost': 250.0,
        'unit_price': 350.0,
        'discount_amount': 0.0,
        'tax_amount': 0.0,
        'total_amount': 700.0,
      };

      final item = SaleItemModel.fromJson(json);
      expect(item.id, 'item-123');
      expect(item.productName, 'Arroz Premium 10lb');
      expect(item.quantity, 2.0);
      expect(item.totalAmount, 700.0);
    });
  });

  group('Sales UI Widget Tests', () {
    testWidgets('SalesScreen renders POS and History Tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SalesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar Título principal
      expect(find.text('Ventas & POS'), findsOneWidget);

      // Verificar pestañas
      expect(find.text('Punto de Venta (POS)'), findsOneWidget);
      expect(find.text('Historial de Facturas'), findsOneWidget);

      // Verificar panel de carrito
      expect(find.text('Detalle de Venta'), findsOneWidget);
      expect(find.text('Carrito Vacío'), findsOneWidget);
    });
  });
}
