class Sale {
  final int? id;
  final String invoiceNumber;
  final int? customerId;
  final DateTime saleDate;
  final double subtotal;
  final double discount;
  final double tax;
  final double cgst;
  final double sgst;
  final double igstAmount;
  final double totalAmount;
  final double returnedAmount;
  final double amountPaid;
  final String status; // 'completed', 'hold'
  final String paymentMethod;
  final String paymentStatus;
  final bool isIgst;
  final String? notes;
  final DateTime? createdAt;
  // Joined
  final String? customerName;
  final List<SaleItem>? items;
  final List<SaleReturnLog>? returnLogs;

  Sale({this.id, required this.invoiceNumber, this.customerId, required this.saleDate, required this.subtotal, this.discount = 0, this.tax = 0, this.cgst = 0, this.sgst = 0, this.igstAmount = 0, required this.totalAmount, this.returnedAmount = 0, this.amountPaid = 0, this.status = 'completed', this.paymentMethod = 'Cash', this.paymentStatus = 'paid', this.isIgst = false, this.notes, this.createdAt, this.customerName, this.items, this.returnLogs});

  factory Sale.fromMap(Map<String, String?> map, {List<SaleItem>? items, List<SaleReturnLog>? returnLogs}) => Sale(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    invoiceNumber: map['invoice_number'] ?? '',
    customerId: map['customer_id'] != null ? int.tryParse(map['customer_id']!) : null,
    saleDate: map['sale_date'] != null ? DateTime.parse(map['sale_date']!) : DateTime.now(),
    subtotal: map['subtotal'] != null ? double.parse(map['subtotal']!) : 0,
    discount: map['discount'] != null ? double.parse(map['discount']!) : 0,
    tax: map['tax'] != null ? double.parse(map['tax']!) : 0,
    cgst: map['cgst'] != null ? double.parse(map['cgst']!) : 0,
    sgst: map['sgst'] != null ? double.parse(map['sgst']!) : 0,
    igstAmount: map['igst'] != null ? double.parse(map['igst']!) : 0,
    totalAmount: map['total_amount'] != null ? double.parse(map['total_amount']!) : 0,
    returnedAmount: map['returned_amount'] != null ? double.parse(map['returned_amount']!) : 0,
    amountPaid: map['amount_paid'] != null ? double.parse(map['amount_paid']!) : 0,
    status: map['status'] ?? 'completed',
    paymentMethod: map['payment_method'] ?? 'Cash',
    paymentStatus: map['payment_status'] ?? 'paid',
    isIgst: map['is_igst'] == '1',
    notes: map['notes'],
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']!) : null,
    customerName: map['customer_name'],
    items: items, returnLogs: returnLogs,
  );
}

class SaleItem {
  final int? id;
  final int? saleId;
  final int productVariantId;
  final double quantity;
  final double returnedQuantity;
  final double price;
  final double costPrice;
  final double discount;
  final double tax;
  final double cgst;
  final double sgst;
  final double igstAmount;
  final double amount;
  // Tinting
  final String? shadeCode;
  final String? shadeName;
  final double tintingCharge;
  // Joined
  final String? variantSku;
  final String? productName;
  final String? variantName;
  final String? unitSymbol;
  final double? packSize;
  final double? availableStock;

  bool get isTinted => shadeCode != null && shadeCode!.isNotEmpty;
  double get totalWithTinting => amount + tintingCharge;
  double get effectivePricePerUnit => (amount / quantity) + (tintingCharge / quantity);
  double get profit => amount - (costPrice * quantity) - discount; // Approximate basic profit

  SaleItem({this.id, this.saleId, required this.productVariantId, required this.quantity, this.returnedQuantity = 0, required this.price, this.costPrice = 0, this.discount = 0, this.tax = 0, this.cgst = 0, this.sgst = 0, this.igstAmount = 0, required this.amount, this.shadeCode, this.shadeName, this.tintingCharge = 0, this.variantSku, this.productName, this.variantName, this.unitSymbol, this.packSize, this.availableStock});

  factory SaleItem.fromMap(Map<String, String?> map) => SaleItem(
    id: map['id'] != null ? int.tryParse(map['id']!) : null,
    saleId: map['sale_id'] != null ? int.tryParse(map['sale_id']!) : null,
    productVariantId: map['product_variant_id'] != null ? int.parse(map['product_variant_id']!) : 0,
    quantity: map['quantity'] != null ? double.parse(map['quantity']!) : 0,
    returnedQuantity: map['returned_quantity'] != null ? double.parse(map['returned_quantity']!) : 0,
    price: map['price'] != null ? double.parse(map['price']!) : 0,
    costPrice: map['cost_price'] != null ? double.parse(map['cost_price']!) : 0,
    discount: map['discount'] != null ? double.parse(map['discount']!) : 0,
    tax: map['tax'] != null ? double.parse(map['tax']!) : 0,
    cgst: map['cgst'] != null ? double.parse(map['cgst']!) : 0,
    sgst: map['sgst'] != null ? double.parse(map['sgst']!) : 0,
    igstAmount: map['igst'] != null ? double.parse(map['igst']!) : 0,
    amount: map['amount'] != null ? double.parse(map['amount']!) : 0,
    shadeCode: map['shade_code'],
    shadeName: map['shade_name'],
    tintingCharge: map['tinting_charge'] != null ? double.parse(map['tinting_charge']!) : 0,
    variantSku: map['variant_sku'] ?? map['sku'],
    productName: map['product_name'],
    variantName: map['variant_name'],
    unitSymbol: map['unit_symbol'],
    packSize: map['pack_size'] != null ? double.tryParse(map['pack_size']!) : null,
  );
}

class SaleReturnLog {
  final int id;
  final int saleId;
  final int saleItemId;
  final double quantity;
  final double refundAmount;
  final DateTime returnDate;

  SaleReturnLog({required this.id, required this.saleId, required this.saleItemId, required this.quantity, required this.refundAmount, required this.returnDate});

  factory SaleReturnLog.fromMap(Map<String, String?> map) => SaleReturnLog(
    id: int.parse(map['id']!),
    saleId: int.parse(map['sale_id']!),
    saleItemId: int.parse(map['sale_item_id']!),
    quantity: double.parse(map['quantity']!),
    refundAmount: double.parse(map['refund_amount']!),
    returnDate: DateTime.parse(map['return_date']!),
  );
}
