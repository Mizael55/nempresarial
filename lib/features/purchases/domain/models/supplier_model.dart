class SupplierModel {
  final String id;
  final String name;
  final String? contactName;
  final String? taxId;
  final String? email;
  final String? phone;
  final String? address;
  final double currentDebt;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  const SupplierModel({
    required this.id,
    required this.name,
    this.contactName,
    this.taxId,
    this.email,
    this.phone,
    this.address,
    this.currentDebt = 0.0,
    this.isActive = true,
    this.notes,
    required this.createdAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Sin Nombre',
      contactName: json['contact_name'] as String?,
      taxId: json['tax_id'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      currentDebt: (json['current_debt'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_name': contactName,
      'tax_id': taxId,
      'email': email,
      'phone': phone,
      'address': address,
      'current_debt': currentDebt,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? contactName,
    String? taxId,
    String? email,
    String? phone,
    String? address,
    double? currentDebt,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      taxId: taxId ?? this.taxId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currentDebt: currentDebt ?? this.currentDebt,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
