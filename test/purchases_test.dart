import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nempresarial/features/products/domain/models/product_model.dart';
import 'package:nempresarial/features/purchases/domain/models/supplier_model.dart';
import 'package:nempresarial/features/purchases/domain/models/purchase_model.dart';
import 'package:nempresarial/features/purchases/domain/models/purchase_item_model.dart';
import 'package:nempresarial/features/purchases/presentation/controllers/purchases_controller.dart';
import 'package:nempresarial/features/purchases/presentation/screens/purchases_screen.dart';

void main() {
  group('Purchases & Suppliers Unit Tests', () {
    final testProduct = ProductModel(
      id: 'prod-001',
      name: 'Aceite de Oliva 1L',
      sku: 'ACE-001',
      salePrice: 450.0,
      costPrice: 300.0,
      minStock: 10.0,
      currentStock: 5.0,
      isTaxable: true,
      taxRate: 18.0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    test('NewPurchaseNotifier order calculation and item adjustments', () {
      final container = ProviderContainer();
      final notifier = container.read(newPurchaseControllerProvider.notifier);

      expect(container.read(newPurchaseControllerProvider).items, isEmpty);

      // 1. Agregar producto a la compra
      notifier.addProduct(testProduct, quantity: 10, cost: 300.0);
      var state = container.read(newPurchaseControllerProvider);
      expect(state.items.length, 1);
      expect(state.items.first.quantity, 10.0);
      expect(state.items.first.unitCost, 300.0);
      expect(state.subtotal, 3000.0);
      expect(state.taxAmount, 540.0); // 18% de 3000
      expect(state.totalAmount, 3540.0);

      // 2. Modificar costo unitario a $280
      notifier.updateCost(testProduct.id, 280.0);
      state = container.read(newPurchaseControllerProvider);
      expect(state.subtotal, 2800.0);
      expect(state.taxAmount, 504.0);
      expect(state.totalAmount, 3304.0);

      // 3. Desactivar impuesto
      notifier.toggleApplyTax(false);
      state = container.read(newPurchaseControllerProvider);
      expect(state.taxAmount, 0.0);
      expect(state.totalAmount, 2800.0);

      // 4. Vaciar borrador
      notifier.clear();
      state = container.read(newPurchaseControllerProvider);
      expect(state.items, isEmpty);
      expect(state.totalAmount, 0.0);
    });

    test('SupplierModel fromJson & toJson serialize correctly', () {
      final json = {
        'id': 'supp-001',
        'name': 'Distribuidora Global S.R.L.',
        'contact_name': 'Roberto Gómez',
        'tax_id': '1-31-99999-9',
        'email': 'contacto@global.com',
        'phone': '809-555-4321',
        'address': 'Zona Industrial Herrera',
        'current_debt': 15000.0,
        'is_active': true,
        'notes': 'Crédito a 45 días',
        'created_at': DateTime.now().toIso8601String(),
      };

      final model = SupplierModel.fromJson(json);
      expect(model.id, 'supp-001');
      expect(model.name, 'Distribuidora Global S.R.L.');
      expect(model.currentDebt, 15000.0);
      expect(model.isActive, isTrue);

      final map = model.toJson();
      expect(map['name'], 'Distribuidora Global S.R.L.');
      expect(map['current_debt'], 15000.0);
    });

    test('PurchaseModel fromJson deserializes correctly', () {
      final json = {
        'id': 'pur-001',
        'purchase_number': 'COM-000001',
        'supplier_id': 'supp-001',
        'supplier_name': 'Distribuidora Global S.R.L.',
        'supplier_tax_id': '1-31-99999-9',
        'branch_id': 'b-001',
        'branch_name': 'Principal',
        'status': 'received',
        'subtotal': 10000.0,
        'tax_amount': 1800.0,
        'total_amount': 11800.0,
        'payment_method': 'transfer',
        'payment_status': 'paid',
        'notes': 'Mercancía en excelente estado',
        'purchaser_name': 'Admin',
        'created_at': DateTime.now().toIso8601String(),
        'items_count': 5,
      };

      final model = PurchaseModel.fromJson(json);
      expect(model.id, 'pur-001');
      expect(model.purchaseNumber, 'COM-000001');
      expect(model.totalAmount, 11800.0);
      expect(model.isReceived, isTrue);
      expect(model.isCancelled, isFalse);
    });

    test('PurchaseItemModel fromJson deserializes correctly', () {
      final json = {
        'id': 'pi-001',
        'purchase_id': 'pur-001',
        'product_id': 'prod-001',
        'product_name': 'Aceite de Oliva 1L',
        'quantity': 20.0,
        'unit_cost': 280.0,
        'total_amount': 5600.0,
      };

      final item = PurchaseItemModel.fromJson(json);
      expect(item.id, 'pi-001');
      expect(item.quantity, 20.0);
      expect(item.totalAmount, 5600.0);
    });
  });

  group('Purchases UI Widget Tests', () {
    testWidgets('PurchasesScreen renders header and all 3 tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PurchasesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar Título principal
      expect(find.text('Compras & Proveedores'), findsOneWidget);

      // Verificar pestañas
      expect(find.text('Órdenes de Compra'), findsOneWidget);
      expect(find.text('Registrar Compra'), findsOneWidget);
      expect(find.text('Proveedores & CXP'), findsOneWidget);
    });
  });
}
