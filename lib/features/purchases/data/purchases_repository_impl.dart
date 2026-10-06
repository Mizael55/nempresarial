import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env_config.dart';
import '../domain/purchases_repository.dart';
import '../domain/models/supplier_model.dart';
import '../domain/models/purchase_model.dart';
import '../domain/models/purchase_item_model.dart';
import '../domain/models/supplier_payment_model.dart';

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepositoryImpl();
});

class PurchasesRepositoryImpl implements PurchasesRepository {
  final List<SupplierModel> _localSuppliers = [];
  final List<PurchaseModel> _localPurchases = [];
  final Map<String, List<PurchaseItemModel>> _localPurchaseItems = {};
  final List<SupplierPaymentModel> _localPayments = [];

  SupabaseClient? get _client {
    try {
      if (EnvConfig.isSupabaseConfigured) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  // ==========================================
  // PROVEEDORES
  // ==========================================

  @override
  Future<List<SupplierModel>> getSuppliers({String? query, bool? activeOnly}) async {
    final client = _client;
    if (client != null) {
      try {
        PostgrestFilterBuilder q = client.from('suppliers').select();

        if (activeOnly == true) {
          q = q.eq('is_active', true);
        }

        if (query != null && query.trim().isNotEmpty) {
          final text = query.trim();
          q = q.or('name.ilike.%$text%,tax_id.ilike.%$text%,contact_name.ilike.%$text%');
        }

        final res = await q.order('name', ascending: true);
        final list = (res as List<dynamic>)
            .map((e) => SupplierModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _localSuppliers
          ..clear()
          ..addAll(list);
        return list;
      } catch (_) {}
    }

    var result = List<SupplierModel>.from(_localSuppliers);
    if (activeOnly == true) {
      result = result.where((s) => s.isActive).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final text = query.trim().toLowerCase();
      result = result.where((s) =>
          s.name.toLowerCase().contains(text) ||
          (s.taxId?.toLowerCase().contains(text) ?? false) ||
          (s.contactName?.toLowerCase().contains(text) ?? false)).toList();
    }
    return result;
  }

  @override
  Future<SupplierModel> createSupplier(SupplierModel supplier) async {
    final client = _client;
    if (client != null) {
      try {
        final payload = {
          'name': supplier.name,
          'contact_name': supplier.contactName,
          'tax_id': supplier.taxId,
          'email': supplier.email,
          'phone': supplier.phone,
          'address': supplier.address,
          'current_debt': supplier.currentDebt,
          'is_active': supplier.isActive,
          'notes': supplier.notes,
        };

        final res = await client.from('suppliers').insert(payload).select().single();
        final created = SupplierModel.fromJson(res);
        _localSuppliers.insert(0, created);
        return created;
      } catch (_) {}
    }

    final local = supplier.copyWith(
      id: 'local-supp-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _localSuppliers.insert(0, local);
    return local;
  }

  @override
  Future<SupplierModel> updateSupplier(SupplierModel supplier) async {
    final client = _client;
    if (client != null) {
      try {
        final payload = {
          'name': supplier.name,
          'contact_name': supplier.contactName,
          'tax_id': supplier.taxId,
          'email': supplier.email,
          'phone': supplier.phone,
          'address': supplier.address,
          'is_active': supplier.isActive,
          'notes': supplier.notes,
          'updated_at': DateTime.now().toIso8601String(),
        };

        final res = await client.from('suppliers').update(payload).eq('id', supplier.id).select().single();
        final updated = SupplierModel.fromJson(res);
        final idx = _localSuppliers.indexWhere((s) => s.id == supplier.id);
        if (idx != -1) _localSuppliers[idx] = updated;
        return updated;
      } catch (_) {}
    }

    final idx = _localSuppliers.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) {
      _localSuppliers[idx] = supplier;
    }
    return supplier;
  }

  @override
  Future<void> deleteSupplier(String id) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('suppliers').delete().eq('id', id);
      } catch (_) {
        // En caso de claves foráneas, desactivar
        await client.from('suppliers').update({'is_active': false}).eq('id', id);
      }
    }
    _localSuppliers.removeWhere((s) => s.id == id);
  }

  // ==========================================
  // COMPRAS
  // ==========================================

  @override
  Future<List<PurchaseModel>> getPurchases({String? query, String? status}) async {
    final client = _client;
    if (client != null) {
      try {
        PostgrestFilterBuilder q = client.from('v_purchases_summary').select();

        if (status != null && status.isNotEmpty && status != 'all') {
          q = q.eq('status', status);
        }

        if (query != null && query.trim().isNotEmpty) {
          final text = query.trim();
          q = q.or('purchase_number.ilike.%$text%,supplier_name.ilike.%$text%');
        }

        final res = await q.order('created_at', ascending: false).limit(50);
        final list = (res as List<dynamic>)
            .map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _localPurchases
          ..clear()
          ..addAll(list);
        return list;
      } catch (e) {
        // Fallback a tabla compras directa si fallara la vista
        try {
          final res = await client.from('purchases').select().order('created_at', ascending: false).limit(50);
          final list = (res as List<dynamic>)
              .map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return list;
        } catch (_) {}
      }
    }

    var result = List<PurchaseModel>.from(_localPurchases);
    if (status != null && status.isNotEmpty && status != 'all') {
      result = result.where((p) => p.status == status).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final text = query.trim().toLowerCase();
      result = result.where((p) =>
          p.purchaseNumber.toLowerCase().contains(text) ||
          p.supplierName.toLowerCase().contains(text)).toList();
    }
    return result;
  }

  @override
  Future<PurchaseModel> getPurchaseById(String id) async {
    final client = _client;
    if (client != null) {
      try {
        final purchaseRes = await client.from('v_purchases_summary').select().eq('id', id).single();
        final itemsRes = await client.from('purchase_items').select().eq('purchase_id', id);

        final items = (itemsRes as List<dynamic>)
            .map((e) => PurchaseItemModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final purchase = PurchaseModel.fromJson(purchaseRes).copyWith(items: items);
        return purchase;
      } catch (_) {}
    }

    final local = _localPurchases.firstWhere((p) => p.id == id,
        orElse: () => PurchaseModel(
              id: id,
              purchaseNumber: 'COM-0000',
              supplierName: 'Proveedor',
              branchId: '',
              branchName: 'Principal',
              status: 'received',
              subtotal: 0,
              taxAmount: 0,
              totalAmount: 0,
              paymentMethod: 'cash',
              paymentStatus: 'paid',
              purchaserName: 'Admin',
              createdAt: DateTime.now(),
              itemsCount: 0,
            ));
    final items = _localPurchaseItems[id] ?? [];
    return local.copyWith(items: items);
  }

  @override
  Future<Map<String, dynamic>> createPurchase({
    required String? supplierId,
    required String? branchId,
    required String paymentMethod,
    required String paymentStatus,
    required String? notes,
    required String? customInvoiceNumber,
    required double taxAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        final userId = client.auth.currentUser?.id;

        final response = await client.rpc('process_purchase', params: {
          'p_supplier_id': supplierId,
          'p_branch_id': branchId,
          'p_payment_method': paymentMethod,
          'p_payment_status': paymentStatus,
          'p_notes': notes ?? '',
          'p_custom_invoice_number': customInvoiceNumber ?? '',
          'p_tax_amount': taxAmount,
          'p_items': items,
          'p_user_id': userId,
        });

        final result = response as Map<String, dynamic>;
        return result;
      } catch (e) {
        throw Exception('Error al registrar compra en servidor: $e');
      }
    }

    // Modo local / mock fallback
    final purchaseId = 'pur-${DateTime.now().millisecondsSinceEpoch}';
    final purchaseNum = customInvoiceNumber?.isNotEmpty == true
        ? customInvoiceNumber!
        : 'COM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    double subtotal = 0;
    final purchaseItems = <PurchaseItemModel>[];
    for (final it in items) {
      final q = (it['quantity'] as num).toDouble();
      final c = (it['unit_cost'] as num).toDouble();
      final tot = q * c;
      subtotal += tot;

      purchaseItems.add(PurchaseItemModel(
        id: 'pitem-${DateTime.now().millisecondsSinceEpoch}-${it['product_id']}',
        purchaseId: purchaseId,
        productId: it['product_id'] as String,
        productName: it['product_name'] as String? ?? 'Producto',
        quantity: q,
        unitCost: c,
        totalAmount: tot,
      ));
    }

    final total = subtotal + taxAmount;
    final purchase = PurchaseModel(
      id: purchaseId,
      purchaseNumber: purchaseNum,
      supplierId: supplierId,
      supplierName: 'Proveedor',
      branchId: branchId ?? '',
      branchName: 'Principal',
      status: 'received',
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      notes: notes,
      purchaserName: 'Usuario Local',
      createdAt: DateTime.now(),
      itemsCount: items.length,
      items: purchaseItems,
    );

    _localPurchases.insert(0, purchase);
    _localPurchaseItems[purchaseId] = purchaseItems;

    return {
      'success': true,
      'purchase_id': purchaseId,
      'purchase_number': purchaseNum,
      'total_amount': total,
    };
  }

  @override
  Future<void> voidPurchase(String purchaseId, String reason) async {
    final client = _client;
    if (client != null) {
      try {
        final userId = client.auth.currentUser?.id;
        await client.rpc('void_purchase', params: {
          'p_purchase_id': purchaseId,
          'p_reason': reason,
          'p_user_id': userId,
        });
        return;
      } catch (e) {
        throw Exception('Error al anular compra: $e');
      }
    }

    final idx = _localPurchases.indexWhere((p) => p.id == purchaseId);
    if (idx != -1) {
      final p = _localPurchases[idx];
      _localPurchases[idx] = p.copyWith(
        status: 'cancelled',
        notes: '${p.notes ?? ''} [ANULADA: $reason]',
      );
    }
  }

  // ==========================================
  // PAGOS A PROVEEDORES
  // ==========================================

  @override
  Future<List<SupplierPaymentModel>> getSupplierPayments(String supplierId) async {
    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('supplier_payments')
            .select()
            .eq('supplier_id', supplierId)
            .order('created_at', ascending: false);

        final list = (res as List<dynamic>)
            .map((e) => SupplierPaymentModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return list;
      } catch (_) {}
    }

    return _localPayments.where((p) => p.supplierId == supplierId).toList();
  }

  @override
  Future<void> recordSupplierPayment({
    required String supplierId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        final userId = client.auth.currentUser?.id;
        await client.rpc('register_supplier_payment', params: {
          'p_supplier_id': supplierId,
          'p_amount': amount,
          'p_payment_method': paymentMethod,
          'p_reference': reference ?? '',
          'p_notes': notes ?? '',
          'p_user_id': userId,
        });
        return;
      } catch (e) {
        throw Exception('Error al registrar abono a proveedor: $e');
      }
    }

    final pay = SupplierPaymentModel(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      supplierId: supplierId,
      amount: amount,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
      paidByName: 'Admin',
      createdAt: DateTime.now(),
    );
    _localPayments.insert(0, pay);

    // Ajustar deuda local
    final idx = _localSuppliers.indexWhere((s) => s.id == supplierId);
    if (idx != -1) {
      final s = _localSuppliers[idx];
      _localSuppliers[idx] = s.copyWith(currentDebt: (s.currentDebt - amount).clamp(0, double.infinity));
    }
  }
}
