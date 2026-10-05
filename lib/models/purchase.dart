class Purchase {
  final int? id;
  final String invoiceNumber;
  final int supplierId;
  final DateTime purchaseDate;
  final double totalAmount;
  final double returnedAmount;
  final String? notes;
  final DateTime? createdAt;
  final String paymentStatus;
  final String paymentMethod;
  final double amountPaid;
  // Joined
  final String? supplierName;
  final List<PurchaseItem>? items;

  Purchase({this.id, required this.invoiceNumber, required this.supplierId, required this.purchaseDate, required this.totalAmount, this.returnedAmount = 0.0, this.notes, this.createdAt, this.paymentStatus = 'paid', this.paymentMethod = 'Cash', this.amountPaid = 0.0, this.supplierName, this.items});

  factory Purchase.fromMap(Map<String, String?> map, {List<PurchaseItem>? items}) => Purchase(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    invoiceNumber: map['invoice_number'] ?? '',
    supplierId: map['supplier_id'] != null ? int.parse(map['supplier_id']!) : 0,
    purchaseDate: map['purchase_date'] != null ? DateTime.parse(map['purchase_date']!) : DateTime.now(),
    totalAmount: map['total_amount'] != null ? double.parse(map['total_amount']!) : 0,
    returnedAmount: map['returned_amount'] != null ? double.parse(map['returned_amount']!) : 0,
    notes: map['notes'],
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']!) : null,
    paymentStatus: map['payment_status'] ?? 'paid',
    paymentMethod: map['payment_method'] ?? 'Cash',
    amountPaid: map['amount_paid'] != null ? double.parse(map['amount_paid']!) : 0,
    supplierName: map['supplier_name'],
    items: items,
  );
}

class PurchaseItem {
  final int? id;
  final int? purchaseId;
  final int productVariantId;
  final double quantity;
  final double returnedQuantity;
  final double purchasePrice;
  final double amount;
  // Joined
  final String? variantSku;
  final String? productName;
  final String? unitSymbol;
  final double? packSize;

  PurchaseItem({this.id, this.purchaseId, required this.productVariantId, required this.quantity, this.returnedQuantity = 0.0, required this.purchasePrice, required this.amount, this.variantSku, this.productName, this.unitSymbol, this.packSize});

  factory PurchaseItem.fromMap(Map<String, String?> map) => PurchaseItem(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    purchaseId: map['purchase_id'] != null ? int.tryParse(map['purchase_id']!) : null,
    productVariantId: map['product_variant_id'] != null ? int.parse(map['product_variant_id']!) : 0,
    quantity: map['quantity'] != null ? double.parse(map['quantity']!) : 0,
    returnedQuantity: map['returned_quantity'] != null ? double.parse(map['returned_quantity']!) : 0,
    purchasePrice: map['purchase_price'] != null ? double.parse(map['purchase_price']!) : 0,
    amount: map['amount'] != null ? double.parse(map['amount']!) : 0,
    variantSku: map['variant_sku'] ?? map['sku'],
    productName: map['product_name'],
    unitSymbol: map['unit_symbol'],
    packSize: map['pack_size'] != null ? double.tryParse(map['pack_size']!) : null,
  );
}
