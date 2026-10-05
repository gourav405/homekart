class ProductVariant {
  final int? id;
  final int productId;
  final int unitId;
  final double packSize;
  final String sku;
  final String? variantName;
  final String? barcode;
  final double purchasePrice;
  final double sellingPrice;
  final double? mrp;
  final int? colorId;
  final int? taxRateId;
  final int? purchaseUnitId;
  final double? conversionFactor;
  final bool isActive;
  final DateTime? createdAt;
  // Joined fields
  final bool isTintable;
  final bool isTaxInclusive;
  final String? productName;
  final int? brandId;
  final String? brandName;
  final String? unitSymbol;
  final String? purchaseUnitSymbol;
  final String? colorName;
  final String? colorHex;
  final String? taxName;
  final double? taxPercentage;
  final double? stockQty;
  final double? minStock;
  final double? maxStock;

  ProductVariant({
    this.id, required this.productId, required this.unitId, required this.packSize,
    required this.sku, this.variantName, this.barcode, required this.purchasePrice, required this.sellingPrice,
    this.mrp, this.colorId, this.taxRateId, this.purchaseUnitId, this.conversionFactor,
    this.isActive = true, this.isTintable = false, this.isTaxInclusive = false, this.createdAt,
    this.productName, this.brandId, this.brandName, this.unitSymbol, this.purchaseUnitSymbol,
    this.colorName, this.colorHex,
    this.taxName, this.taxPercentage, this.stockQty, this.minStock, this.maxStock,
  });

  bool get isLowStock => (minStock ?? 0) > 0 && (stockQty ?? 0) <= (minStock ?? 0);
  String get displayName {
    String name = '${productName ?? ''} ${packSize.toStringAsFixed(packSize == packSize.roundToDouble() ? 0 : 1)}${unitSymbol ?? ''}';
    if (variantName != null && variantName!.isNotEmpty) name += ' ($variantName)';
    if (colorName != null && colorName != 'N/A') name += ' $colorName';
    if (isTintable) name += ' 🎨';
    return name.trim();
  }

  factory ProductVariant.fromMap(Map<String, String?> map) => ProductVariant(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    productId: map['product_id'] != null ? int.parse(map['product_id']!) : 0,
    unitId: map['unit_id'] != null ? int.parse(map['unit_id']!) : 0,
    packSize: map['pack_size'] != null ? double.parse(map['pack_size']!) : 0,
    sku: map['sku'] ?? '',
    variantName: map['variant_name'],
    barcode: map['barcode'],
    purchasePrice: map['purchase_price'] != null ? double.parse(map['purchase_price']!) : 0,
    sellingPrice: map['selling_price'] != null ? double.parse(map['selling_price']!) : 0,
    mrp: map['mrp'] != null ? double.tryParse(map['mrp']!) : null,
    colorId: map['color_id'] != null ? int.tryParse(map['color_id']!) : null,
    taxRateId: map['tax_rate_id'] != null ? int.tryParse(map['tax_rate_id']!) : null,
    purchaseUnitId: map['purchase_unit_id'] != null ? int.tryParse(map['purchase_unit_id']!) : null,
    conversionFactor: map['conversion_factor'] != null ? double.tryParse(map['conversion_factor']!) : null,
    isActive: map['is_active'] != '0',
    isTintable: map['is_tintable'] == '1',
    isTaxInclusive: map['is_tax_inclusive'] == '1',
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']!) : null,
    productName: map['product_name'],
    brandId: map['brand_id'] != null ? int.tryParse(map['brand_id']!) : null,
    brandName: map['brand_name'],
    unitSymbol: map['unit_symbol'],
    purchaseUnitSymbol: map['purchase_unit_symbol'],
    colorName: map['color_name'],
    colorHex: map['color_hex'],
    taxName: map['tax_name'],
    taxPercentage: map['tax_percentage'] != null ? double.tryParse(map['tax_percentage']!) : null,
    stockQty: map['stock_qty'] != null ? double.tryParse(map['stock_qty']!) : null,
    minStock: map['min_stock'] != null ? double.tryParse(map['min_stock']!) : null,
    maxStock: map['max_stock'] != null ? double.tryParse(map['max_stock']!) : null,
  );
}
