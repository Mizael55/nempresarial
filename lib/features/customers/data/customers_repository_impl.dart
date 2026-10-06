import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env_config.dart';
import '../domain/customers_repository.dart';
import '../domain/models/customer_model.dart';
import '../domain/models/customer_payment_model.dart';
import '../domain/models/customer_statement_entry.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepositoryImpl();
});

class CustomersRepositoryImpl implements CustomersRepository {
  final List<CustomerModel> _localCustomers = [];
  final List<CustomerPaymentModel> _localPayments = [];

  SupabaseClient? get _client {
    try {
      if (EnvConfig.isSupabaseConfigured) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<CustomerModel>> getCustomers({String? query, bool? withDebtOnly}) async {
    final client = _client;
    if (client != null) {
      try {
        PostgrestFilterBuilder q = client.from('v_customers_summary').select();

        if (withDebtOnly == true) {
          q = q.gt('current_balance', 0);
        }

        if (query != null && query.trim().isNotEmpty) {
          final text = query.trim();
          q = q.or('name.ilike.%$text%,tax_id.ilike.%$text%,phone.ilike.%$text%');
        }

        final res = await q.order('name', ascending: true);
        final list = (res as List<dynamic>)
            .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _localCustomers
          ..clear()
          ..addAll(list);
        return list;
      } catch (e) {
        // Fallback a tabla customers directa si la vista estuviese en proceso
        try {
          PostgrestFilterBuilder fb = client.from('customers').select();
          if (withDebtOnly == true) {
            fb = fb.gt('current_balance', 0);
          }
          if (query != null && query.trim().isNotEmpty) {
            final text = query.trim();
            fb = fb.or('name.ilike.%$text%,tax_id.ilike.%$text%,phone.ilike.%$text%');
          }
          final res = await fb.order('name', ascending: true);
          final list = (res as List<dynamic>)
              .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return list;
        } catch (_) {}
      }
    }

    var result = List<CustomerModel>.from(_localCustomers);
    if (withDebtOnly == true) {
      result = result.where((c) => c.currentBalance > 0).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final text = query.trim().toLowerCase();
      result = result.where((c) =>
          c.name.toLowerCase().contains(text) ||
          (c.taxId?.toLowerCase().contains(text) ?? false) ||
          (c.phone?.toLowerCase().contains(text) ?? false)).toList();
    }
    return result;
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    final client = _client;
    if (client != null) {
      try {
        final res = await client.from('v_customers_summary').select().eq('id', id).single();
        return CustomerModel.fromJson(res);
      } catch (_) {}
    }

    return _localCustomers.firstWhere(
      (c) => c.id == id,
      orElse: () => CustomerModel(
        id: id,
        name: 'Cliente',
        creditLimit: 0,
        currentBalance: 0,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final client = _client;
    if (client != null) {
      try {
        final payload = {
          'name': customer.name,
          'tax_id': customer.taxId,
          'email': customer.email,
          'phone': customer.phone,
          'whatsapp': customer.whatsapp,
          'address': customer.address,
          'credit_limit': customer.creditLimit,
          'current_balance': customer.currentBalance,
          'is_active': customer.isActive,
          'notes': customer.notes,
        };

        final res = await client.from('customers').insert(payload).select().single();
        final created = CustomerModel.fromJson(res);
        _localCustomers.insert(0, created);
        return created;
      } catch (e) {
        throw Exception('Error al registrar cliente: $e');
      }
    }

    final local = customer.copyWith(
      id: 'local-cust-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _localCustomers.insert(0, local);
    return local;
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final client = _client;
    if (client != null) {
      try {
        final payload = {
          'name': customer.name,
          'tax_id': customer.taxId,
          'email': customer.email,
          'phone': customer.phone,
          'whatsapp': customer.whatsapp,
          'address': customer.address,
          'credit_limit': customer.creditLimit,
          'is_active': customer.isActive,
          'notes': customer.notes,
          'updated_at': DateTime.now().toIso8601String(),
        };

        final res = await client.from('customers').update(payload).eq('id', customer.id).select().single();
        final updated = CustomerModel.fromJson(res);
        final idx = _localCustomers.indexWhere((c) => c.id == customer.id);
        if (idx != -1) _localCustomers[idx] = updated;
        return updated;
      } catch (e) {
        throw Exception('Error al actualizar cliente: $e');
      }
    }

    final idx = _localCustomers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      _localCustomers[idx] = customer;
    }
    return customer;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('customers').delete().eq('id', id);
      } catch (_) {
        // En caso de facturas asociadas, desactivar lógicamente
        await client.from('customers').update({'is_active': false}).eq('id', id);
      }
    }
    _localCustomers.removeWhere((c) => c.id == id);
  }

  @override
  Future<Map<String, dynamic>> registerPayment({
    required String customerId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        final userId = client.auth.currentUser?.id;
        final response = await client.rpc('register_customer_payment', params: {
          'p_customer_id': customerId,
          'p_amount': amount,
          'p_payment_method': paymentMethod,
          'p_reference': reference ?? '',
          'p_notes': notes ?? '',
          'p_received_by': userId,
        });

        final result = response as Map<String, dynamic>;
        return result;
      } catch (e) {
        throw Exception('Error al registrar abono del cliente: $e');
      }
    }

    // Modo local
    final payment = CustomerPaymentModel(
      id: 'cpay-${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      amount: amount,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
      receivedByName: 'Admin',
      createdAt: DateTime.now(),
    );
    _localPayments.insert(0, payment);

    final idx = _localCustomers.indexWhere((c) => c.id == customerId);
    double newBal = 0;
    if (idx != -1) {
      final c = _localCustomers[idx];
      newBal = (c.currentBalance - amount).clamp(0, double.infinity);
      _localCustomers[idx] = c.copyWith(currentBalance: newBal);
    }

    return {
      'success': true,
      'payment_id': payment.id,
      'amount': amount,
      'new_balance': newBal,
    };
  }

  @override
  Future<List<CustomerPaymentModel>> getCustomerPayments(String customerId) async {
    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('customer_payments')
            .select()
            .eq('customer_id', customerId)
            .order('created_at', ascending: false);

        final list = (res as List<dynamic>)
            .map((e) => CustomerPaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return list;
      } catch (_) {}
    }

    return _localPayments.where((p) => p.customerId == customerId).toList();
  }

  @override
  Future<List<CustomerStatementEntry>> getCustomerStatement(String customerId) async {
    final entries = <CustomerStatementEntry>[];
    final client = _client;

    if (client != null) {
      try {
        // 1. Obtener ventas del cliente
        final salesRes = await client
            .from('sales')
            .select('invoice_number, total_amount, payment_method, status, created_at')
            .eq('customer_id', customerId)
            .neq('status', 'cancelled')
            .order('created_at', ascending: true);

        // 2. Obtener abonos del cliente
        final paymentsRes = await client
            .from('customer_payments')
            .select('id, amount, payment_method, reference, created_at')
            .eq('customer_id', customerId)
            .order('created_at', ascending: true);

        // Combinar transacciones
        final transactions = <Map<String, dynamic>>[];

        for (final s in (salesRes as List<dynamic>)) {
          transactions.add({
            'date': DateTime.tryParse(s['created_at'].toString()) ?? DateTime.now(),
            'type': 'sale',
            'doc': s['invoice_number'] as String? ?? 'FAC-0000',
            'desc': 'Factura de Venta (${(s['payment_method'] ?? 'cash').toString().toUpperCase()})',
            'amount': (s['total_amount'] as num?)?.toDouble() ?? 0.0,
            'is_credit': s['payment_method'] == 'credit',
          });
        }

        for (final p in (paymentsRes as List<dynamic>)) {
          transactions.add({
            'date': DateTime.tryParse(p['created_at'].toString()) ?? DateTime.now(),
            'type': 'payment',
            'doc': 'ABONO-${(p['id'] as String).substring(0, 6).toUpperCase()}',
            'desc': 'Abono recibido (${(p['payment_method'] ?? 'cash').toString().toUpperCase()})',
            'amount': (p['amount'] as num?)?.toDouble() ?? 0.0,
            'is_credit': false,
          });
        }

        // Ordenar cronológicamente
        transactions.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

        double balance = 0.0;
        for (final t in transactions) {
          final isSale = t['type'] == 'sale';
          final isCreditSale = t['is_credit'] == true;
          final amount = t['amount'] as double;

          double debit = 0.0;
          double credit = 0.0;

          if (isSale && isCreditSale) {
            debit = amount;
            balance += debit;
          } else if (!isSale) {
            credit = amount;
            balance = (balance - credit).clamp(0, double.infinity);
          }

          entries.add(CustomerStatementEntry(
            date: t['date'] as DateTime,
            type: t['type'] as String,
            documentNumber: t['doc'] as String,
            description: t['desc'] as String,
            debit: debit,
            credit: credit,
            runningBalance: balance,
          ));
        }

        return entries.reversed.toList();
      } catch (_) {}
    }

    return entries;
  }
}
