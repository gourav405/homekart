class Product {
  final int? id;
  final String name;
  final String sku;
  final String? description;
  final int brandId;
  final int categoryId;
  final int? subcategoryId;
  final int? typeId;
  final bool isActive;
  final bool isTintable;
  final bool isTaxInclusive;
  final bool taxRemittable;
  final String? hsnCode;
  final DateTime? createdAt;
  // Joined fields
  final String? brandName;
  final String? categoryName;
  final String? subcategoryName;
  final String? typeName;
  final int variantCount;

  Product({
    this.id, required this.name, required this.sku, this.description,
    required this.brandId, required this.categoryId, this.subcategoryId, this.typeId,
    this.isActive = true, this.isTintable = false, this.isTaxInclusive = false, this.taxRemittable = true, this.hsnCode, this.createdAt,
    this.brandName, this.categoryName, this.subcategoryName, this.typeName, this.variantCount = 0,
  });

  factory Product.fromMap(Map<String, String?> map) => Product(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    name: map['name'] ?? '',
    sku: map['sku'] ?? '',
    description: map['description'],
    brandId: map['brand_id'] != null ? int.parse(map['brand_id']!) : 0,
    categoryId: map['category_id'] != null ? int.parse(map['category_id']!) : 0,
    subcategoryId: map['subcategory_id'] != null ? int.tryParse(map['subcategory_id']!) : null,
    typeId: map['type_id'] != null ? int.tryParse(map['type_id']!) : null,
    isActive: map['is_active'] != '0',
    isTintable: map['is_tintable'] == '1',
    isTaxInclusive: map['is_tax_inclusive'] == '1',
    taxRemittable: map['tax_remittable'] != '0',
    hsnCode: map['hsn_code'],
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']!) : null,
    brandName: map['brand_name'],
    categoryName: map['category_name'],
    subcategoryName: map['subcategory_name'],
    typeName: map['type_name'],
    variantCount: map['variant_count'] != null ? int.tryParse(map['variant_count']!) ?? 0 : 0,
  );
}
