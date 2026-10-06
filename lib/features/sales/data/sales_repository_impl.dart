import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/storage/local_database_service.dart';
import '../domain/sales_repository.dart';
import '../domain/models/sale_model.dart';
import '../domain/models/sale_item_model.dart';
import '../domain/models/customer_model.dart';
import '../domain/models/cart_item_model.dart';

class SalesRepositoryImpl implements SalesRepository {
  final LocalDatabaseService _localDb;

  SalesRepositoryImpl(this._localDb);

  SupabaseClient? get _client {
    try {
      if (EnvConfig.isSupabaseConfigured) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<SaleModel>> getSales({
    String? status,
    String? searchQuery,
    int limit = 50,
  }) async {
    final mode = await _localDb.getStorageMode();

    if (mode == 'cloud') {
      final client = _client;
      if (client != null) {
        try {
          PostgrestFilterBuilder query = client.from('v_sales_summary').select();

          if (status != null && status.isNotEmpty && status != 'all') {
            query = query.eq('status', status);
          }

          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final q = searchQuery.trim();
            query = query.or('invoice_number.ilike.%$q%,customer_name.ilike.%$q%');
          }

          final response = await query.order('created_at', ascending: false).limit(limit);
          final data = response as List<dynamic>;
          return data.map((json) => SaleModel.fromJson(json as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
    }

    // Local persistent database on PC
    await _localDb.ensureInitialized();
    final rows = await _localDb.query(
      LocalDatabaseService.tableSales,
      orderBy: 'created_at',
      ascending: false,
      limit: limit,
    );

    var sales = rows.map((j) => SaleModel.fromJson(j)).toList();

    if (status != null && status.isNotEmpty && status != 'all') {
      sales = sales.where((s) => s.status == status).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      sales = sales.where((s) =>
          s.invoiceNumber.toLowerCase().contains(q) ||
          s.customerName.toLowerCase().contains(q)).toList();
    }

    return sales;
  }

  @override
  Future<SaleModel?> getSaleById(String saleId) async {
    final mode = await _localDb.getStorageMode();

    if (mode == 'cloud') {
      final client = _client;
      if (client != null) {
        try {
          final res = await client
              .from('sales')
              .select('*, customer:customers(name)')
              .eq('id', saleId)
              .maybeSingle();

          if (res != null) {
            final map = Map<String, dynamic>.from(res);
            if (map['customer'] != null && map['customer']['name'] != null) {
              map['customer_name'] = map['customer']['name'];
            }
            return SaleModel.fromJson(map);
          }
        } catch (_) {}
      }
    }

    await _localDb.ensureInitialized();
    final row = await _localDb.findById(LocalDatabaseService.tableSales, saleId);
    if (row != null) {
      return SaleModel.fromJson(row);
    }
    return null;
  }

  @override
  Future<List<SaleItemModel>> getSaleItems(String saleId) async {
    final mode = await _localDb.getStorageMode();

    if (mode == 'cloud') {
      final client = _client;
      if (client != null) {
        try {
          final res = await client
              .from('sale_items')
              .select('*, product:products(name, sku)')
              .eq('sale_id', saleId);
          return (res as List).map((i) => SaleItemModel.fromJson(i as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
    }

    await _localDb.ensureInitialized();
    final rows = await _localDb.query(
      LocalDatabaseService.tableSaleItems,
      where: {'sale_id': saleId},
    );
    return rows.map((r) => SaleItemModel.fromJson(r)).toList();
  }

  @override
  Future<List<CustomerModel>> getCustomers({String? query}) async {
    final mode = await _localDb.getStorageMode();

    if (mode == 'cloud') {
      final client = _client;
      if (client != null) {
        try {
          PostgrestFilterBuilder q = client
              .from('customers')
              .select()
              .eq('is_active', true);

          if (query != null && query.trim().isNotEmpty) {
            final term = query.trim();
            q = q.or('name.ilike.%$term%,tax_id.ilike.%$term%,phone.ilike.%$term%');
          }

          final res = await q.order('name', ascending: true).limit(50);
          final data = res as List<dynamic>;
          return data.map((j) => CustomerModel.fromJson(j as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
    }

    await _localDb.ensureInitialized();
    final rows = await _localDb.query(LocalDatabaseService.tableCustomers, orderBy: 'name', ascending: true);
    var list = rows.map((j) => CustomerModel.fromJson(j)).toList();

    if (query != null && query.trim().isNotEmpty) {
      final term = query.trim().toLowerCase();
      list = list.where((c) =>
          c.name.toLowerCase().contains(term) ||
          (c.taxId != null && c.taxId!.toLowerCase().contains(term))).toList();
    }
    return list;
  }

  @override
  Future<CustomerModel> createCustomer({
    required String name,
    String? taxId,
    String? phone,
    String? email,
    String? address,
  }) async {
    final payload = {
      'name': name.trim(),
      if (taxId != null && taxId.trim().isNotEmpty) 'tax_id': taxId.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
      'is_active': true,
      'credit_limit': 0.0,
      'current_balance': 0.0,
    };

    final mode = await _localDb.getStorageMode();
    if (mode == 'cloud') {
      final client = _client;
      if (client != null) {
        try {
          final res = await client.from('customers').insert(payload).select().single();
          return CustomerModel.fromJson(res);
        } catch (_) {}
      }
    }

    final inserted = await _localDb.insert(LocalDatabaseService.tableCustomers, payload);
    return CustomerModel.fromJson(inserted);
  }

  @override
  Future<Map<String, dynamic>> completeSale({
    String? branchId,
    String? customerId,
    required List<CartItemModel> items,
    required String paymentMethod,
    String paymentStatus = 'paid',
    double globalDiscount = 0.0,
    String? notes,
    String? createdBy,
    List<Map<String, dynamic>> payments = const [],
  }) async {
    final mode = await _localDb.getStorageMode();

    if (mode == 'cloud') {
      final client = _client;
      if (client != null) {
        try {
          final itemsPayload = items.map((i) => i.toPosPayload()).toList();

          final res = await client.rpc('process_sale', params: {
            'p_branch_id': branchId,
            'p_customer_id': customerId,
            'p_items': itemsPayload,
            'p_payment_method': paymentMethod,
            'p_payment_status': paymentStatus,
            'p_discount_total': globalDiscount,
            'p_notes': notes,
            'p_created_by': createdBy,
            'p_payments': payments,
          });

          return Map<String, dynamic>.from(res as Map);
        } catch (_) {}
      }
    }

    // Local persistent sale creation and automated stock decrement
    await _localDb.ensureInitialized();
    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    double subtotal = 0.0;
    double taxAmount = 0.0;

    for (final item in items) {
      subtotal += item.netSubtotal;
      taxAmount += item.taxAmount;
    }

    final total = max(0.0, subtotal + taxAmount - globalDiscount);

    String? customerName;
    if (customerId != null) {
      final cust = await _localDb.findById(LocalDatabaseService.tableCustomers, customerId);
      if (cust != null) {
        customerName = cust['name'] as String?;
      }
    }

    final saleMap = {
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName ?? 'Consumidor Final',
      'branch_id': branchId ?? 'br_main',
      'branch_name': 'Sucursal Principal',
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': globalDiscount,
      'total_amount': total,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'status': 'completed',
      'cashier_name': 'Administrador',
      'items_count': items.length,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    };

    final savedSale = await _localDb.insert(LocalDatabaseService.tableSales, saleMap);
    final saleId = savedSale['id'] as String;

    // Process each sold item & decrement stock in products table
    for (final item in items) {
      final itemMap = {
        'sale_id': saleId,
        'product_id': item.product.id,
        'product_name': item.product.name,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'subtotal': item.netSubtotal,
        'tax_rate': item.taxRate,
        'tax_amount': item.taxAmount,
        'discount_amount': item.discountAmount,
        'total': item.totalAmount,
      };
      await _localDb.insert(LocalDatabaseService.tableSaleItems, itemMap);

      // Decrement stock in LocalDatabaseService.tableProducts
      final pRow = await _localDb.findById(LocalDatabaseService.tableProducts, item.product.id);
      if (pRow != null) {
        final currentStock = ((pRow['stock_quantity'] ?? pRow['current_stock'] ?? 0) as num).toDouble();
        final updatedStock = max(0.0, currentStock - item.quantity);
        await _localDb.update(LocalDatabaseService.tableProducts, item.product.id, {
          'stock_quantity': updatedStock,
          'current_stock': updatedStock,
        });

        // Record stock movement
        await _localDb.insert(LocalDatabaseService.tableMovements, {
          'product_id': item.product.id,
          'product_name': item.product.name,
          'movement_type': 'sale',
          'quantity': item.quantity,
          'previous_stock': currentStock,
          'new_stock': updatedStock,
          'reference': invoiceNumber,
          'notes': 'Venta POS $invoiceNumber',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    return {
      'sale_id': saleId,
      'invoice_number': invoiceNumber,
      'total': total,
      'status': 'completed',
    };
  }

  @override
  Future<Map<String, dynamic>> voidSale({
    required String saleId,
    required String reason,
    String? userId,
  }) async {
    final mode = await _localDb.getStorageMode();
    if (mode == 'cloud') {
      final client = _client;
      if (client != null) {
        try {
          final res = await client.rpc('void_sale', params: {
            'p_sale_id': saleId,
            'p_reason': reason,
            'p_voided_by': userId,
          });
          return Map<String, dynamic>.from(res as Map);
        } catch (_) {}
      }
    }

    await _localDb.update(LocalDatabaseService.tableSales, saleId, {
      'status': 'cancelled',
      'cancellation_reason': reason,
    });

    return {
      'success': true,
      'message': 'Venta anulada correctamente',
    };
  }
}

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final localDb = ref.watch(localDatabaseServiceProvider);
  return SalesRepositoryImpl(localDb);
});
