class ExpenseModel {
  final String id;
  final String? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final String branchId;
  final String concept;
  final double amount;
  final String paymentMethod;
  final String? reference;
  final String? receiptUrl;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    required this.branchId,
    required this.concept,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    this.receiptUrl,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'cash':
        return 'Efectivo';
      case 'credit_card':
        return 'Tarjeta Crédito';
      case 'debit_card':
        return 'Tarjeta Débito';
      case 'transfer':
        return 'Transferencia';
      case 'credit':
        return 'Crédito';
      default:
        return 'Efectivo';
    }
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    String? catName;
    String? catColor;

    if (json['category'] != null && json['category'] is Map) {
      catName = json['category']['name'] as String?;
      catColor = json['category']['color'] as String?;
    } else if (json['expense_categories'] != null && json['expense_categories'] is Map) {
      catName = json['expense_categories']['name'] as String?;
      catColor = json['expense_categories']['color'] as String?;
    }

    return ExpenseModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: catName ?? json['category_name'] as String?,
      categoryColor: catColor ?? json['category_color'] as String?,
      branchId: json['branch_id'] as String? ?? 'a0000000-0000-0000-0000-000000000001',
      concept: json['concept'] as String? ?? 'Gasto sin concepto',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      reference: json['reference'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (categoryId != null && categoryId!.isNotEmpty) 'category_id': categoryId,
      'branch_id': branchId,
      'concept': concept,
      'amount': amount,
      'payment_method': paymentMethod,
      if (reference != null && reference!.isNotEmpty) 'reference': reference,
      if (receiptUrl != null && receiptUrl!.isNotEmpty) 'receipt_url': receiptUrl,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (createdBy != null && createdBy!.isNotEmpty) 'created_by': createdBy,
    };
  }
}
