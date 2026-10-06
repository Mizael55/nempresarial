class InventoryMovementModel {
  final String id;
  final String productId;
  final String? productName;
  final String? productSku;
  final String? branchId;
  final String movementType; // 'initial', 'purchase', 'sale', 'adjustment_in', 'adjustment_out', 'transfer_in', 'transfer_out', 'return'
  final double quantity;
  final double previousStock;
  final double newStock;
  final double? unitCost;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const InventoryMovementModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productSku,
    this.branchId,
    required this.movementType,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.unitCost,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  bool get isPositive =>
      movementType == 'initial' ||
      movementType == 'purchase' ||
      movementType == 'adjustment_in' ||
      movementType == 'transfer_in' ||
      movementType == 'return';

  String get typeLabel {
    switch (movementType) {
      case 'initial':
        return 'Inventario Inicial';
      case 'purchase':
        return 'Entrada por Compra';
      case 'sale':
        return 'Salida por Venta';
      case 'adjustment_in':
        return 'Ajuste de Entrada (+)';
      case 'adjustment_out':
        return 'Ajuste de Salida / Merma (-)';
      case 'transfer_in':
        return 'Transferencia Recibida';
      case 'transfer_out':
        return 'Transferencia Enviada';
      case 'return':
        return 'Devolución';
      default:
        return movementType;
    }
  }

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) {
    String? pName;
    String? pSku;
    if (json['product'] is Map) {
      final pMap = json['product'] as Map<String, dynamic>;
      pName = pMap['name'] as String?;
      pSku = pMap['sku'] as String?;
    } else {
      pName = json['product_name'] as String?;
      pSku = json['product_sku'] as String?;
    }

    return InventoryMovementModel(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: pName,
      productSku: pSku,
      branchId: json['branch_id'] as String?,
      movementType: json['movement_type'] as String? ?? 'adjustment_in',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      previousStock: (json['previous_stock'] as num?)?.toDouble() ?? 0.0,
      newStock: (json['new_stock'] as num?)?.toDouble() ?? 0.0,
      unitCost: (json['unit_cost'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'branch_id': branchId,
      'movement_type': movementType,
      'quantity': quantity,
      'previous_stock': previousStock,
      'new_stock': newStock,
      'unit_cost': unitCost,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
