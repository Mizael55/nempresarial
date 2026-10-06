class SaleModel {
  final String id;
  final String invoiceNumber;
  final String branchId;
  final String branchName;
  final String? customerId;
  final String customerName;
  final String? customerTaxId;
  final String status; // 'completed', 'cancelled', 'draft'
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double costAmount;
  final String paymentMethod; // 'cash', 'credit_card', 'debit_card', 'transfer', 'credit', 'mixed'
  final String paymentStatus; // 'paid', 'pending', 'partial'
  final String? notes;
  final String? createdBy;
  final String cashierName;
  final DateTime createdAt;
  final int itemsCount;

  const SaleModel({
    required this.id,
    required this.invoiceNumber,
    required this.branchId,
    required this.branchName,
    this.customerId,
    required this.customerName,
    this.customerTaxId,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.costAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.notes,
    this.createdBy,
    required this.cashierName,
    required this.createdAt,
    required this.itemsCount,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String? ?? 'N/A',
      branchId: json['branch_id'] as String? ?? '',
      branchName: json['branch_name'] as String? ?? 'Sucursal Principal',
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String? ?? 'Consumidor Final',
      customerTaxId: json['customer_tax_id'] as String?,
      status: json['status'] as String? ?? 'completed',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      costAmount: (json['cost_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      paymentStatus: json['payment_status'] as String? ?? 'paid',
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      cashierName: json['cashier_name'] as String? ?? 'Sistema',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'branch_id': branchId,
      'customer_id': customerId,
      'status': status,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'cost_amount': costAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
