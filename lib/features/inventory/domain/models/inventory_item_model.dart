class InventoryItemModel {
  final String productId;
  final String productName;
  final String sku;
  final String? barcode;
  final String unit;
  final String? categoryId;
  final String? categoryName;
  final double costPrice;
  final double salePrice;
  final double minStock;
  final double currentStock;
  final double reservedStock;
  final double totalCostValue;
  final double totalSaleValue;
  final String stockStatus; // 'in_stock', 'low_stock', 'out_of_stock'
  final DateTime? lastStockUpdate;

  const InventoryItemModel({
    required this.productId,
    required this.productName,
    required this.sku,
    this.barcode,
    this.unit = 'unidad',
    this.categoryId,
    this.categoryName,
    this.costPrice = 0.0,
    this.salePrice = 0.0,
    this.minStock = 0.0,
    this.currentStock = 0.0,
    this.reservedStock = 0.0,
    this.totalCostValue = 0.0,
    this.totalSaleValue = 0.0,
    this.stockStatus = 'in_stock',
    this.lastStockUpdate,
  });

  bool get isLowStock => currentStock <= minStock && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;
  double get profitPerUnit => salePrice - costPrice;
  double get totalExpectedProfit => totalSaleValue - totalCostValue;
  double get profitMarginPercentage =>
      costPrice > 0 ? ((salePrice - costPrice) / costPrice) * 100 : 0.0;

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      productId: json['product_id'] as String? ?? json['id'] as String? ?? '',
      productName: json['product_name'] as String? ?? json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String?,
      unit: json['unit'] as String? ?? 'unidad',
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0.0,
      minStock: (json['min_stock'] as num?)?.toDouble() ?? 0.0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      reservedStock: (json['reserved_stock'] as num?)?.toDouble() ?? 0.0,
      totalCostValue: (json['total_cost_value'] as num?)?.toDouble() ?? 0.0,
      totalSaleValue: (json['total_sale_value'] as num?)?.toDouble() ?? 0.0,
      stockStatus: json['stock_status'] as String? ?? 'in_stock',
      lastStockUpdate: json['last_stock_update'] != null
          ? DateTime.tryParse(json['last_stock_update'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'sku': sku,
      'barcode': barcode,
      'unit': unit,
      'category_id': categoryId,
      'category_name': categoryName,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'min_stock': minStock,
      'current_stock': currentStock,
      'reserved_stock': reservedStock,
      'total_cost_value': totalCostValue,
      'total_sale_value': totalSaleValue,
      'stock_status': stockStatus,
      'last_stock_update': lastStockUpdate?.toIso8601String(),
    };
  }
}
