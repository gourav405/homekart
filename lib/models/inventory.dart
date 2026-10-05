class Inventory {
  final int? id;
  final int productVariantId;
  final double quantity;
  final double minimumStock;
  final double maximumStock;
  // Joined
  final String? variantSku;
  final String? productName;

  Inventory({this.id, required this.productVariantId, this.quantity = 0, this.minimumStock = 0, this.maximumStock = 0, this.variantSku, this.productName});

  bool get isLowStock => minimumStock > 0 && quantity <= minimumStock;

  factory Inventory.fromMap(Map<String, String?> map) => Inventory(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    productVariantId: map['product_variant_id'] != null ? int.parse(map['product_variant_id']!) : 0,
    quantity: map['quantity'] != null ? double.parse(map['quantity']!) : 0,
    minimumStock: map['minimum_stock'] != null ? double.parse(map['minimum_stock']!) : 0,
    maximumStock: map['maximum_stock'] != null ? double.parse(map['maximum_stock']!) : 0,
    variantSku: map['variant_sku'],
    productName: map['product_name'],
  );
}

class StockMovement {
  final int? id;
  final int productVariantId;
  final String type; // PURCHASE, SALE, RETURN, ADJUSTMENT, DAMAGE
  final double quantity;
  final int? referenceId;
  final String? remarks;
  final DateTime? createdAt;
  // Joined
  final String? variantSku;
  final String? productName;

  StockMovement({this.id, required this.productVariantId, required this.type, required this.quantity, this.referenceId, this.remarks, this.createdAt, this.variantSku, this.productName});

  factory StockMovement.fromMap(Map<String, String?> map) => StockMovement(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    productVariantId: map['product_variant_id'] != null ? int.parse(map['product_variant_id']!) : 0,
    type: map['type'] ?? '',
    quantity: map['quantity'] != null ? double.parse(map['quantity']!) : 0,
    referenceId: map['reference_id'] != null ? int.tryParse(map['reference_id']!) : null,
    remarks: map['remarks'],
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']!) : null,
    variantSku: map['variant_sku'],
    productName: map['product_name'],
  );
}
