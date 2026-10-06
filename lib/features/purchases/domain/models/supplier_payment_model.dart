class SupplierPaymentModel {
  final String id;
  final String supplierId;
  final double amount;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final String? paidByName;
  final DateTime createdAt;

  const SupplierPaymentModel({
    required this.id,
    required this.supplierId,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    this.notes,
    this.paidByName,
    required this.createdAt,
  });

  factory SupplierPaymentModel.fromJson(Map<String, dynamic> json) {
    return SupplierPaymentModel(
      id: json['id'] as String,
      supplierId: json['supplier_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'transfer',
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      paidByName: json['paid_by_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'amount': amount,
      'payment_method': paymentMethod,
      'reference': reference,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
