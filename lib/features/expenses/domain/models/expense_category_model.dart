class ExpenseCategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final bool isActive;

  const ExpenseCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.isActive = true,
  });

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'General',
      description: json['description'] as String?,
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'is_active': isActive,
    };
  }
}
