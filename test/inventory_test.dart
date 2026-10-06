import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nempresarial/features/inventory/domain/models/inventory_item_model.dart';
import 'package:nempresarial/features/inventory/domain/models/inventory_movement_model.dart';
import 'package:nempresarial/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:nempresarial/features/inventory/presentation/widgets/stock_movement_dialog.dart';

void main() {
  group('Inventory Domain Models', () {
    test('InventoryItemModel calculates status flags correctly', () {
      const item1 = InventoryItemModel(
        productId: 'prod_1',
        productName: 'Arroz 5lb',
        sku: 'ARR-001',
        currentStock: 0,
        minStock: 10,
        costPrice: 150,
      );

      expect(item1.isOutOfStock, isTrue);
      expect(item1.isLowStock, isFalse);

      const item2 = InventoryItemModel(
        productId: 'prod_2',
        productName: 'Aceite 1L',
        sku: 'ACE-001',
        currentStock: 5,
        minStock: 10,
        costPrice: 200,
      );

      expect(item2.isOutOfStock, isFalse);
      expect(item2.isLowStock, isTrue);
    });

    test('InventoryMovementModel identifies positive operations and labels', () {
      final movementIn = InventoryMovementModel(
        id: 'mov_1',
        productId: 'prod_1',
        movementType: 'adjustment_in',
        quantity: 20,
        previousStock: 0,
        newStock: 20,
        createdAt: DateTime.now(),
      );

      expect(movementIn.isPositive, isTrue);
      expect(movementIn.typeLabel, 'Ajuste de Entrada (+)');

      final movementOut = InventoryMovementModel(
        id: 'mov_2',
        productId: 'prod_1',
        movementType: 'adjustment_out',
        quantity: 5,
        previousStock: 20,
        newStock: 15,
        createdAt: DateTime.now(),
      );

      expect(movementOut.isPositive, isFalse);
      expect(movementOut.typeLabel, 'Ajuste de Salida / Merma (-)');
    });
  });

  group('Inventory UI Widgets', () {
    testWidgets('InventoryScreen renders metrics and action button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InventoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Control de Inventario & Kardex'), findsOneWidget);
      expect(find.text('Registrar Movimiento'), findsOneWidget);
      expect(find.text('Valorización al Costo'), findsOneWidget);
      expect(find.text('Valorización a la Venta'), findsOneWidget);
      expect(find.text('Existencias Actuales'), findsOneWidget);
      expect(find.text('Kardex / Movimientos'), findsOneWidget);
    });

    testWidgets('StockMovementDialog renders form fields without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StockMovementDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Movimiento de Inventario'), findsOneWidget);
      expect(find.text('Producto *'), findsOneWidget);
      expect(find.text('Tipo de Operación'), findsOneWidget);
      expect(find.text('Cantidad *'), findsOneWidget);
      expect(find.text('Guardar Movimiento'), findsOneWidget);
    });
  });
}
