import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/storage/local_database_service.dart';
import '../domain/models/inventory_item_model.dart';
import '../domain/models/inventory_movement_model.dart';
import '../domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final LocalDatabaseService _localDb;

  InventoryRepositoryImpl(this._localDb);

  @override
  Future<List<InventoryItemModel>> getInventoryOverview({
    String? searchQuery,
    String? categoryId,
    bool? onlyLowStock,
  }) async {
    try {
      final mode = await _localDb.getStorageMode();

      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          var query = Supabase.instance.client.from('v_inventory_overview').select();

          if (categoryId != null && categoryId.isNotEmpty) {
            query = query.eq('category_id', categoryId);
          }

          if (onlyLowStock == true) {
            query = query.or('stock_status.eq.low_stock,stock_status.eq.out_of_stock');
          }

          if (searchQuery != null && searchQuery.isNotEmpty) {
            query = query.or('product_name.ilike.%$searchQuery%,sku.ilike.%$searchQuery%,barcode.ilike.%$searchQuery%');
          }

          final data = await query.order('product_name', ascending: true);
          return (data as List).map((i) => InventoryItemModel.fromJson(i)).toList();
        } catch (_) {}
      }

      // Local persistent database on PC
      await _localDb.ensureInitialized();
      final products = await _localDb.query(LocalDatabaseService.tableProducts);
      final categories = await _localDb.query(LocalDatabaseService.tableCategories);
      final catMap = {for (var c in categories) (c['id'] as String? ?? ''): (c['name'] as String? ?? '')};

      List<InventoryItemModel> items = products.map((p) {
        final cStock = ((p['stock_quantity'] ?? p['current_stock'] ?? 0) as num).toDouble();
        final mStock = ((p['min_stock_alert'] ?? 5) as num).toDouble();
        final cPrice = ((p['cost_price'] ?? 0.0) as num).toDouble();
        final sPrice = ((p['sale_price'] ?? 0.0) as num).toDouble();
        final catId = p['category_id'] as String?;

        String status = 'normal';
        if (cStock <= 0) {
          status = 'out_of_stock';
        } else if (cStock <= mStock) {
          status = 'low_stock';
        }

        return InventoryItemModel(
          productId: p['id'] as String? ?? '',
          productName: p['name'] as String? ?? 'Producto',
          sku: p['sku'] as String? ?? '',
          barcode: p['barcode'] as String?,
          categoryId: catId,
          categoryName: catId != null ? (catMap[catId] ?? 'General') : 'General',
          currentStock: cStock,
          reservedStock: 0.0,
          minStock: mStock,
          costPrice: cPrice,
          salePrice: sPrice,
          totalCostValue: cStock * cPrice,
          totalSaleValue: cStock * sPrice,
          stockStatus: status,
        );
      }).toList();

      if (categoryId != null && categoryId.isNotEmpty) {
        items = items.where((i) => i.categoryId == categoryId).toList();
      }
      if (onlyLowStock == true) {
        items = items.where((i) => i.isLowStock || i.isOutOfStock).toList();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        items = items.where((i) =>
            i.productName.toLowerCase().contains(q) ||
            i.sku.toLowerCase().contains(q)).toList();
      }

      return items;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<InventoryMovementModel>> getMovements({
    String? productId,
    String? movementType,
    int limit = 50,
  }) async {
    try {
      final mode = await _localDb.getStorageMode();

      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          var query = Supabase.instance.client
              .from('inventory_movements')
              .select('*, product:products(name, sku)');

          if (productId != null && productId.isNotEmpty) {
            query = query.eq('product_id', productId);
          }

          if (movementType != null && movementType.isNotEmpty) {
            query = query.eq('movement_type', movementType);
          }

          final data = await query
              .order('created_at', ascending: false)
              .limit(limit);
          return (data as List).map((m) => InventoryMovementModel.fromJson(m)).toList();
        } catch (_) {}
      }

      await _localDb.ensureInitialized();
      final rows = await _localDb.query(
        LocalDatabaseService.tableMovements,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      var movements = rows.map((r) => InventoryMovementModel.fromJson(r)).toList();
      if (productId != null && productId.isNotEmpty) {
        movements = movements.where((m) => m.productId == productId).toList();
      }
      if (movementType != null && movementType.isNotEmpty) {
        movements = movements.where((m) => m.movementType == movementType).toList();
      }
      return movements;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<InventoryMovementModel> recordMovement({
    required String productId,
    required String movementType,
    required double quantity,
    double? unitCost,
    String? notes,
    String? branchId,
  }) async {
    try {
      final mode = await _localDb.getStorageMode();

      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;

          final res = await Supabase.instance.client.rpc(
            'record_inventory_movement',
            params: {
              'p_product_id': productId,
              'p_movement_type': movementType,
              'p_quantity': quantity,
              'p_unit_cost': unitCost,
              'p_notes': notes,
              'p_branch_id': branchId,
              'p_created_by': currentUserId,
            },
          );

          return InventoryMovementModel.fromJson(Map<String, dynamic>.from(res as Map));
        } catch (_) {}
      }

      // Local persistent stock update on PC
      await _localDb.ensureInitialized();
      final product = await _localDb.findById(LocalDatabaseService.tableProducts, productId);
      double currentStock = 0.0;
      if (product != null) {
        currentStock = ((product['stock_quantity'] ?? product['current_stock'] ?? 0) as num).toDouble();
      }

      double newStock = currentStock;
      if (movementType == 'in' || movementType == 'initial') {
        newStock += quantity;
      } else if (movementType == 'out') {
        newStock = max(0.0, currentStock - quantity);
      } else if (movementType == 'adjustment') {
        newStock = quantity;
      }

      if (product != null) {
        await _localDb.update(LocalDatabaseService.tableProducts, productId, {
          'stock_quantity': newStock,
          'current_stock': newStock,
        });
      }

      final movementData = {
        'product_id': productId,
        'product_name': product != null ? product['name'] : 'Producto',
        'movement_type': movementType,
        'quantity': quantity,
        'previous_stock': currentStock,
        'new_stock': newStock,
        'unit_cost': unitCost ?? (product != null ? product['cost_price'] : 0.0),
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      };

      final inserted = await _localDb.insert(LocalDatabaseService.tableMovements, movementData);
      return InventoryMovementModel.fromJson(inserted);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getInventoryMetrics() async {
    try {
      final items = await getInventoryOverview();

      double totalCostValuation = 0.0;
      double totalSaleValuation = 0.0;
      double totalUnits = 0.0;
      int lowStockCount = 0;
      int outOfStockCount = 0;

      for (final item in items) {
        totalCostValuation += item.totalCostValue;
        totalSaleValuation += item.totalSaleValue;
        totalUnits += item.currentStock;
        if (item.isOutOfStock) {
          outOfStockCount++;
        } else if (item.isLowStock) {
          lowStockCount++;
        }
      }

      return {
        'total_cost_valuation': totalCostValuation,
        'total_sale_valuation': totalSaleValuation,
        'total_units': totalUnits,
        'total_items_count': items.length,
        'low_stock_count': lowStockCount,
        'out_of_stock_count': outOfStockCount,
      };
    } catch (e) {
      return {
        'total_cost_valuation': 0.0,
        'total_sale_valuation': 0.0,
        'total_units': 0.0,
        'total_items_count': 0,
        'low_stock_count': 0,
        'out_of_stock_count': 0,
      };
    }
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final localDb = ref.watch(localDatabaseServiceProvider);
  return InventoryRepositoryImpl(localDb);
});
