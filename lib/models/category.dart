class Category {
  final int? id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;

  Category({this.id, required this.name, this.description, this.isActive = true, this.createdAt});

  factory Category.fromMap(Map<String, String?> map) => Category(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    name: map['name'] ?? '',
    description: map['description'],
    isActive: map['is_active'] != '0',
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']!) : null,
  );
}
