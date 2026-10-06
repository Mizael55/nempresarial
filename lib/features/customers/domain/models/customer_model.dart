class CustomerModel {
  final String id;
  final String name;
  final String? taxId;
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? address;
  final double creditLimit;
  final double currentBalance;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;
  final int totalSalesCount;
  final double totalPurchasedAmount;
  final DateTime? lastPurchaseAt;

  const CustomerModel({
    required this.id,
    required this.name,
    this.taxId,
    this.email,
    this.phone,
    this.whatsapp,
    this.address,
    this.creditLimit = 0.0,
    this.currentBalance = 0.0,
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.totalSalesCount = 0,
    this.totalPurchasedAmount = 0.0,
    this.lastPurchaseAt,
  });

  bool get hasDebt => currentBalance > 0.0;
  bool get isOverCreditLimit => creditLimit > 0.0 && currentBalance >= creditLimit;
  double get availableCredit => (creditLimit - currentBalance).clamp(0.0, double.infinity);
  double get creditUtilization => creditLimit > 0 ? ((currentBalance / creditLimit) * 100).clamp(0.0, 999.0) : 0.0;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Sin Nombre',
      taxId: json['tax_id'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      address: json['address'] as String?,
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalSalesCount: (json['total_sales_count'] as num?)?.toInt() ?? 0,
      totalPurchasedAmount: (json['total_purchased_amount'] as num?)?.toDouble() ?? 0.0,
      lastPurchaseAt: json['last_purchase_at'] != null
          ? DateTime.tryParse(json['last_purchase_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tax_id': taxId,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'address': address,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? taxId,
    String? email,
    String? phone,
    String? whatsapp,
    String? address,
    double? creditLimit,
    double? currentBalance,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    int? totalSalesCount,
    double? totalPurchasedAmount,
    DateTime? lastPurchaseAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      taxId: taxId ?? this.taxId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      totalSalesCount: totalSalesCount ?? this.totalSalesCount,
      totalPurchasedAmount: totalPurchasedAmount ?? this.totalPurchasedAmount,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
    );
  }
}
