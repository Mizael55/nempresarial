import 'purchase_item_model.dart';

class PurchaseModel {
  final String id;
  final String purchaseNumber;
  final String? supplierId;
  final String supplierName;
  final String? supplierTaxId;
  final String branchId;
  final String branchName;
  final String status; // 'received', 'pending', 'cancelled'
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus; // 'paid', 'pending', 'partial'
  final String? notes;
  final String? createdBy;
  final String purchaserName;
  final DateTime createdAt;
  final int itemsCount;
  final List<PurchaseItemModel> items;

  const PurchaseModel({
    required this.id,
    required this.purchaseNumber,
    this.supplierId,
    required this.supplierName,
    this.supplierTaxId,
    required this.branchId,
    required this.branchName,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.notes,
    this.createdBy,
    required this.purchaserName,
    required this.createdAt,
    required this.itemsCount,
    this.items = const [],
  });

  bool get isReceived => status == 'received';
  bool get isCancelled => status == 'cancelled';
  bool get isPendingPayment => paymentStatus == 'pending' || paymentStatus == 'partial';

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as String,
      purchaseNumber: json['purchase_number'] as String? ?? 'COM-0000',
      supplierId: json['supplier_id'] as String?,
      supplierName: json['supplier_name'] as String? ?? 'Proveedor',
      supplierTaxId: json['supplier_tax_id'] as String?,
      branchId: json['branch_id'] as String? ?? '',
      branchName: json['branch_name'] as String? ?? 'Principal',
      status: json['status'] as String? ?? 'received',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'transfer',
      paymentStatus: json['payment_status'] as String? ?? 'paid',
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      purchaserName: json['purchaser_name'] as String? ?? 'Admin',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => PurchaseItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_number': purchaseNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'supplier_tax_id': supplierTaxId,
      'branch_id': branchId,
      'branch_name': branchName,
      'status': status,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'notes': notes,
      'created_by': createdBy,
      'purchaser_name': purchaserName,
      'created_at': createdAt.toIso8601String(),
      'items_count': itemsCount,
    };
  }

  PurchaseModel copyWith({
    String? id,
    String? purchaseNumber,
    String? supplierId,
    String? supplierName,
    String? supplierTaxId,
    String? branchId,
    String? branchName,
    String? status,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? notes,
    String? createdBy,
    String? purchaserName,
    DateTime? createdAt,
    int? itemsCount,
    List<PurchaseItemModel>? items,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierTaxId: supplierTaxId ?? this.supplierTaxId,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      purchaserName: purchaserName ?? this.purchaserName,
      createdAt: createdAt ?? this.createdAt,
      itemsCount: itemsCount ?? this.itemsCount,
      items: items ?? this.items,
    );
  }
}
