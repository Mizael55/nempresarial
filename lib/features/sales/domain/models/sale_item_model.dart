class SaleItemModel {
  final String id;
  final String saleId;
  final String productId;
  final String? variantId;
  final String productName;
  final double quantity;
  final double unitCost;
  final double unitPrice;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;

  const SaleItemModel({
    required this.id,
    required this.saleId,
    required this.productId,
    this.variantId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    required this.unitPrice,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'] as String,
      saleId: json['sale_id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      productName: json['product_name'] as String? ?? 'Producto',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'variant_id': variantId,
      'product_name': productName,
      'quantity': quantity,
      'unit_cost': unitCost,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
    };
  }
}
