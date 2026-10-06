class CustomerPaymentModel {
  final String id;
  final String customerId;
  final double amount;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final String? receivedByName;
  final DateTime createdAt;

  const CustomerPaymentModel({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    this.notes,
    this.receivedByName,
    required this.createdAt,
  });

  factory CustomerPaymentModel.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      receivedByName: json['received_by_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'payment_method': paymentMethod,
      'reference': reference,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
