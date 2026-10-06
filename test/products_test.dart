import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nempresarial/features/products/presentation/screens/products_screen.dart';
import 'package:nempresarial/features/products/presentation/widgets/product_form_dialog.dart';
import 'package:nempresarial/features/products/presentation/widgets/category_form_dialog.dart';

void main() {
  testWidgets('ProductsScreen builds and displays key elements', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProductsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Catálogo de Productos'), findsOneWidget);
    expect(find.text('Nuevo Producto'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Total de Productos'), findsOneWidget);
  });

  testWidgets('ProductFormDialog renders inputs without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProductFormDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Crear Nuevo Producto'), findsOneWidget);
    expect(find.text('Nombre del Producto *'), findsOneWidget);
    expect(find.text('Precio de Costo *'), findsOneWidget);
    expect(find.text('Precio de Venta *'), findsOneWidget);
  });

  testWidgets('CategoryFormDialog renders inputs and preset colors', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CategoryFormDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Nueva Categoría'), findsOneWidget);
    expect(find.text('Nombre de la categoría'), findsOneWidget);
    expect(find.text('Color de Identificación'), findsOneWidget);
  });
}
