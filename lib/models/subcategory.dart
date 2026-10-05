class Subcategory {
  final int? id;
  final String name;
  final int categoryId;
  final String? categoryName;
  final bool isActive;

  Subcategory({this.id, required this.name, required this.categoryId, this.categoryName, this.isActive = true});

  factory Subcategory.fromMap(Map<String, String?> map) => Subcategory(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    name: map['name'] ?? '',
    categoryId: map['category_id'] != null ? int.parse(map['category_id']!) : 0,
    categoryName: map['category_name'],
    isActive: map['is_active'] != '0',
  );
}
