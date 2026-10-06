import 'product_variant_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String sku;
  final String? barcode;
  final String? imageUrl;
  final String unit; // 'unit', 'kg', 'lb', 'box', 'pack'
  final double costPrice;
  final double salePrice;
  final double minStock;
  final double currentStock;
  final bool isTaxable;
  final double taxRate;
  final bool isActive;
  final bool hasVariants;
  final List<ProductVariantModel> variants;
  final DateTime? createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.sku,
    this.barcode,
    this.imageUrl,
    this.unit = 'unit',
    this.costPrice = 0.0,
    this.salePrice = 0.0,
    this.minStock = 5.0,
    this.currentStock = 0.0,
    this.isTaxable = true,
    this.taxRate = 18.0,
    this.isActive = true,
    this.hasVariants = false,
    this.variants = const [],
    this.createdAt,
  });

  // Financial and stock indicators
  double get profitMargin => salePrice - costPrice;
  double get profitPerUnit => salePrice - costPrice;
  double get profitMarginPercentage =>
      costPrice > 0 ? ((salePrice - costPrice) / costPrice) * 100 : 0.0;
  double get inventoryValue => costPrice * currentStock;
  double get totalInvested => costPrice * currentStock;
  double get totalExpectedRevenue => salePrice * currentStock;
  double get totalExpectedProfit => (salePrice - costPrice) * currentStock;
  bool get isOutOfStock => currentStock <= 0;
  bool get isLowStock => currentStock > 0 && currentStock <= minStock;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category'] != null
          ? (json['category'] as Map<String, dynamic>)['name'] as String?
          : null,
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String?,
      imageUrl: json['image_url'] as String?,
      unit: json['unit'] as String? ?? 'unit',
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0.0,
      minStock: (json['min_stock'] as num?)?.toDouble() ?? 5.0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      isTaxable: json['is_taxable'] as bool? ?? true,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 18.0,
      isActive: json['is_active'] as bool? ?? true,
      hasVariants: json['has_variants'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'sku': sku,
      'barcode': barcode,
      'image_url': imageUrl,
      'unit': unit,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'min_stock': minStock,
      'is_taxable': isTaxable,
      'tax_rate': taxRate,
      'is_active': isActive,
      'has_variants': hasVariants,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    String? sku,
    String? barcode,
    String? imageUrl,
    String? unit,
    double? costPrice,
    double? salePrice,
    double? minStock,
    double? currentStock,
    bool? isTaxable,
    double? taxRate,
    bool? isActive,
    bool? hasVariants,
    List<ProductVariantModel>? variants,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      minStock: minStock ?? this.minStock,
      currentStock: currentStock ?? this.currentStock,
      isTaxable: isTaxable ?? this.isTaxable,
      taxRate: taxRate ?? this.taxRate,
      isActive: isActive ?? this.isActive,
      hasVariants: hasVariants ?? this.hasVariants,
      variants: variants ?? this.variants,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
