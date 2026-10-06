import '../../../products/domain/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  final double quantity;
  final double unitPrice;
  final double discountAmount;
  final double taxRate; // percentage e.g. 18.0

  const CartItemModel({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0.0,
    required this.taxRate,
  });

  CartItemModel copyWith({
    ProductModel? product,
    double? quantity,
    double? unitPrice,
    double? discountAmount,
    double? taxRate,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  double get grossSubtotal => quantity * unitPrice;
  double get netSubtotal => grossSubtotal - discountAmount;
  double get taxAmount => product.isTaxable ? (netSubtotal * (taxRate / 100.0)) : 0.0;
  double get totalAmount => netSubtotal + taxAmount;

  Map<String, dynamic> toPosPayload() {
    return {
      'product_id': product.id,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
    };
  }
}
