import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nempresarial/main.dart';

void main() {
  testWidgets('Nubiko app smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: NubikoApp(),
      ),
    );

    // Initial pump
    await tester.pump();
    expect(find.byType(NubikoApp), findsOneWidget);
  });
}
