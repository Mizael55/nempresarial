class ProductVariantModel {
  final String id;
  final String productId;
  final String variantName;
  final String? sku;
  final String? barcode;
  final double costPrice;
  final double salePrice;
  final double currentStock;
  final Map<String, dynamic> attributes;

  const ProductVariantModel({
    required this.id,
    required this.productId,
    required this.variantName,
    this.sku,
    this.barcode,
    this.costPrice = 0.0,
    this.salePrice = 0.0,
    this.currentStock = 0.0,
    this.attributes = const {},
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] as String,
      productId: json['product_id'] as String? ?? '',
      variantName: json['variant_name'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0.0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'variant_name': variantName,
      'sku': sku,
      'barcode': barcode,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'attributes': attributes,
    };
  }
}
