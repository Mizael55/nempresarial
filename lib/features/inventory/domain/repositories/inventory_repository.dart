import '../models/inventory_item_model.dart';
import '../models/inventory_movement_model.dart';

abstract class InventoryRepository {
  Future<List<InventoryItemModel>> getInventoryOverview({
    String? searchQuery,
    String? categoryId,
    bool? onlyLowStock,
  });

  Future<List<InventoryMovementModel>> getMovements({
    String? productId,
    String? movementType,
    int limit = 50,
  });

  Future<InventoryMovementModel> recordMovement({
    required String productId,
    required String movementType,
    required double quantity,
    double? unitCost,
    String? notes,
    String? branchId,
  });

  Future<Map<String, dynamic>> getInventoryMetrics();
}
