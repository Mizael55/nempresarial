import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nempresarial/features/customers/domain/models/customer_model.dart';
import 'package:nempresarial/features/customers/domain/models/customer_payment_model.dart';
import 'package:nempresarial/features/customers/domain/models/customer_statement_entry.dart';
import 'package:nempresarial/features/customers/presentation/controllers/customers_controller.dart';
import 'package:nempresarial/features/customers/presentation/screens/customers_screen.dart';

void main() {
  group('Customers & Accounts Receivable (CXC) Unit Tests', () {
    test('CustomerModel serialization and credit calculations', () {
      final customer = CustomerModel(
        id: 'cust-001',
        name: 'Supermercado Los Prados SRL',
        taxId: '131-98765-4',
        email: 'compras@losprados.com',
        phone: '809-555-1234',
        address: 'Av. Las Palmas #45',
        creditLimit: 50000.0,
        currentBalance: 15000.0,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Verify computed properties
      expect(customer.hasDebt, isTrue);
      expect(customer.availableCredit, 35000.0);
      expect(customer.creditUtilization, 30.0);
      expect(customer.isOverCreditLimit, isFalse);

      // Serialization to JSON
      final json = customer.toJson();
      expect(json['name'], 'Supermercado Los Prados SRL');
      expect(json['credit_limit'], 50000.0);
      expect(json['current_balance'], 15000.0);

      // Deserialization from JSON
      final deserialized = CustomerModel.fromJson(json);
      expect(deserialized.id, 'cust-001');
      expect(deserialized.name, customer.name);
      expect(deserialized.availableCredit, 35000.0);
    });

    test('CustomerModel over credit limit check', () {
      final customerExceeded = CustomerModel(
        id: 'cust-002',
        name: 'Farmacia Sol',
        creditLimit: 10000.0,
        currentBalance: 12500.0,
        createdAt: DateTime.now(),
      );

      expect(customerExceeded.hasDebt, isTrue);
      expect(customerExceeded.availableCredit, 0.0); // Clamped at 0
      expect(customerExceeded.isOverCreditLimit, isTrue);
      expect(customerExceeded.creditUtilization, 125.0);
    });

    test('CustomerPaymentModel serialization and validation', () {
      final now = DateTime.now();
      final payment = CustomerPaymentModel(
        id: 'pay-001',
        customerId: 'cust-001',
        amount: 5000.0,
        paymentMethod: 'transfer',
        reference: 'TX-998822',
        notes: 'Abono factura FAC-0012',
        receivedByName: 'Cajero Principal',
        createdAt: now,
      );

      expect(payment.amount, 5000.0);
      expect(payment.paymentMethod, 'transfer');

      final json = payment.toJson();
      expect(json['customer_id'], 'cust-001');
      expect(json['amount'], 5000.0);
      expect(json['payment_method'], 'transfer');

      final fromJson = CustomerPaymentModel.fromJson(json);
      expect(fromJson.id, 'pay-001');
      expect(fromJson.reference, 'TX-998822');
      expect(fromJson.amount, 5000.0);
    });

    test('CustomerStatementEntry parses debits and credits correctly', () {
      final now = DateTime.now();
      final debitEntry = CustomerStatementEntry(
        date: now,
        type: 'sale',
        documentNumber: 'FAC-000101',
        description: 'Venta a Crédito',
        debit: 12000.0,
        credit: 0.0,
        runningBalance: 12000.0,
      );

      expect(debitEntry.isSale, isTrue);
      expect(debitEntry.isPayment, isFalse);
      expect(debitEntry.debit, 12000.0);
      expect(debitEntry.credit, 0.0);

      final creditEntry = CustomerStatementEntry(
        date: now.add(const Duration(days: 2)),
        type: 'payment',
        documentNumber: 'TX-998822',
        description: 'Abono a Cuenta',
        debit: 0.0,
        credit: 5000.0,
        runningBalance: 7000.0,
      );

      expect(creditEntry.isSale, isFalse);
      expect(creditEntry.isPayment, isTrue);
      expect(creditEntry.debit, 0.0);
      expect(creditEntry.credit, 5000.0);
      expect(creditEntry.runningBalance, 7000.0);
    });
  });

  group('Customers Screen Widget Tests', () {
    testWidgets('Renders CustomersScreen with header, KPI cards and list view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      final testCustomers = [
        CustomerModel(
          id: 'c-1',
          name: 'Comercial Dominicana SRL',
          taxId: '101-23456-7',
          phone: '809-555-0101',
          creditLimit: 100000.0,
          currentBalance: 25000.0,
          createdAt: DateTime.now(),
        ),
        CustomerModel(
          id: 'c-2',
          name: 'Colmado San Juan',
          taxId: '402-1234567-8',
          phone: '809-555-0102',
          creditLimit: 15000.0,
          currentBalance: 0.0,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customersListProvider.overrideWith(
              () => _MockCustomersNotifier(testCustomers),
            ),
          ],
          child: const MaterialApp(
            home: CustomersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar Título del Módulo
      expect(find.text('Clientes & Cuentas por Cobrar (CXC)'), findsOneWidget);
      expect(find.text('Nuevo Cliente'), findsOneWidget);

      // Verificar KPI Cards
      expect(find.text('Total Clientes'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 clientes
      expect(find.text('Clientes con Deuda'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2)); // En StatCard y en el badge del filtro
      expect(find.text('Cartera por Cobrar'), findsOneWidget);

      // Verificar clientes en la lista
      expect(find.text('Comercial Dominicana SRL'), findsOneWidget);
      expect(find.text('Colmado San Juan'), findsOneWidget);

      // Verificar botones de acción
      expect(find.byIcon(LucideIcons.handCoins), findsOneWidget); // Solo el cliente con deuda
      expect(find.byIcon(LucideIcons.fileSpreadsheet), findsNWidgets(2)); // Ambos clientes
      expect(find.byIcon(LucideIcons.pencil), findsNWidgets(2)); // Ambos clientes
    });
  });
}

class _MockCustomersNotifier extends CustomersNotifier {
  final List<CustomerModel> _initialCustomers;

  _MockCustomersNotifier(this._initialCustomers);

  @override
  Future<List<CustomerModel>> build() async {
    return _initialCustomers;
  }
}
