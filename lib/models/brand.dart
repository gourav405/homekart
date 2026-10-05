class Brand {
  final int? id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Brand({this.id, required this.name, this.description, this.isActive = true, this.createdAt, this.updatedAt});

  factory Brand.fromMap(Map<String, String?> map) => Brand(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    name: map['name'] ?? '',
    description: map['description'],
    isActive: map['is_active'] != '0',
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']!) : null,
    updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']!) : null,
  );
}
