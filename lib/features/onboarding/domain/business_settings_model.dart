class BusinessSettingsModel {
  final String? id;
  final String businessName;
  final String taxId;
  final String businessType;
  final String phone;
  final String email;
  final String address;
  final String currencyCode;
  final String currencySymbol;
  final double taxRate;
  final String taxName;
  final bool onboardingCompleted;

  const BusinessSettingsModel({
    this.id,
    required this.businessName,
    this.taxId = '',
    this.businessType = 'retail',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.currencyCode = 'DOP',
    this.currencySymbol = 'RD\$',
    this.taxRate = 18.0,
    this.taxName = 'ITBIS',
    this.onboardingCompleted = false,
  });

  factory BusinessSettingsModel.fromJson(Map<String, dynamic> json) {
    return BusinessSettingsModel(
      id: json['id'] as String?,
      businessName: json['business_name'] as String? ?? '',
      taxId: json['tax_id'] as String? ?? '',
      businessType: json['business_type'] as String? ?? 'retail',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      currencyCode: json['currency_code'] as String? ?? 'DOP',
      currencySymbol: json['currency_symbol'] as String? ?? 'RD\$',
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 18.0,
      taxName: json['tax_name'] as String? ?? 'ITBIS',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'business_name': businessName,
      'tax_id': taxId,
      'business_type': businessType,
      'phone': phone,
      'email': email,
      'address': address,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'tax_rate': taxRate,
      'tax_name': taxName,
      'onboarding_completed': onboardingCompleted,
    };
  }
}
