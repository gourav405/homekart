import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../models/product_variant.dart';
import '../models/customer.dart';
import '../services/sale_service.dart';

class SaleProvider extends ChangeNotifier {
  final SaleService _svc = SaleService();
  List<Sale> _sales = [];
  List<SaleItem> _currentItems = [];
  int? _customerId;
  String? _customerName;
  String _invoiceNumber = '';
  double _discount = 0;
  bool _isDiscountPercent = false;
  String _paymentMethod = 'Cash';
  String _paymentStatus = 'paid';
  bool _isIgst = false;
  String _notes = '';
  bool _applyTax = true;
  bool _isLoading = false;
  String? _error;
  String? _statusFilter;

  List<Sale> get sales => _sales;
  List<SaleItem> get currentItems => _currentItems;
  int? get customerId => _customerId;
  String? get customerName => _customerName;
  String get invoiceNumber => _invoiceNumber;
  double get discount => _discount;
  bool get isDiscountPercent => _isDiscountPercent;
  String get paymentMethod => _paymentMethod;
  String get paymentStatus => _paymentStatus;
  bool get isIgst => _isIgst;
  bool get applyTax => _applyTax;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;

  double get subtotal =>
      _currentItems.fold(0, (s, i) => s + i.price * i.quantity);
  double get totalTax =>
      _applyTax ? _currentItems.fold(0, (s, i) => s + i.tax) : 0;
  double get totalTinting =>
      _currentItems.fold(0, (s, i) => s + i.tintingCharge);
  double get totalItemDiscount =>
      _currentItems.fold(0, (s, i) => s + i.discount);

  double get totalCgst => _isIgst ? 0 : totalTax / 2;
  double get totalSgst => _isIgst ? 0 : totalTax / 2;
  double get totalIgst => _isIgst ? totalTax : 0;

  double get calculatedDiscount => _isDiscountPercent
      ? ((subtotal + totalTax + totalTinting - totalItemDiscount) *
            _discount /
            100)
      : _discount;
  double get grandTotal =>
      subtotal +
      totalTax +
      totalTinting -
      totalItemDiscount -
      calculatedDiscount;

  void toggleApplyTax(bool v) {
    _applyTax = v;
    notifyListeners();
  }

  Future<void> loadSales() async {
    _isLoading = true;
    notifyListeners();
    try {
      _sales = await _svc.getAll(status: _statusFilter);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void setStatusFilter(String? s) {
    _statusFilter = s;
    loadSales();
  }

  void setSearchQuery(String q) async {
    try {
      _sales = await _svc.getAll(
        search: q.isNotEmpty ? q : null,
        status: _statusFilter,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> initNewSale() async {
    _currentItems = [];
    _customerId = null;
    _customerName = null;
    _discount = 0;
    _isDiscountPercent = false;
    _paymentMethod = 'Cash';
    _paymentStatus = 'paid';
    _isIgst = false;
    _notes = '';
    _error = null;
    _applyTax = true;
    try {
      _invoiceNumber = await _svc.generateInvoiceNumber();
    } catch (_) {
      _invoiceNumber = 'HK-ERROR';
    }
    notifyListeners();
  }

  Future<void> initSale() async {
    _invoiceNumber = await _svc.generateInvoiceNumber();
    notifyListeners();
  }

  Customer? _customer;
  Customer? get customer => _customer;

  void setCustomer(Customer c, {String businessState = ''}) {
    _customerId = c.id;
    _customerName = c.name;
    _customer = c;
    
    if (c.state != null && c.state!.isNotEmpty && businessState.isNotEmpty) {
      _isIgst = (c.state != businessState);
    } else {
      _isIgst = false;
    }
    
    notifyListeners();
  }

  void setDiscount(double d) {
    _discount = d;
    notifyListeners();
  }

  void setDiscountType(bool isPercent) {
    _isDiscountPercent = isPercent;
    notifyListeners();
  }

  void setPaymentMethod(String m) {
    _paymentMethod = m;
    notifyListeners();
  }

  void setPaymentStatus(String s) {
    _paymentStatus = s;
    notifyListeners();
  }

  void setIsIgst(bool v) {
    _isIgst = v;
    notifyListeners();
  }

  void setNotes(String n) {
    _notes = n;
    notifyListeners();
  }

  void addItem(
    ProductVariant v,
    double qty, {
    String? shadeCode,
    String? shadeName,
    double tintingCharge = 0,
  }) {
    _error = null;
    if (v.id == null) return;

    if (qty > (v.stockQty ?? 0)) {
      _error = 'Not enough stock available (${v.stockQty} left)';
      notifyListeners();
      return;
    }

    double taxPct = v.taxPercentage ?? 18;
    double basePrice = v.isTaxInclusive
        ? v.sellingPrice / (1 + taxPct / 100)
        : v.sellingPrice;

    if (shadeCode == null || shadeCode.isEmpty) {
      final idx = _currentItems.indexWhere(
        (i) => i.productVariantId == v.id && !i.isTinted,
      );
      if (idx != -1) {
        final old = _currentItems[idx];
        double newQty = old.quantity + qty;
        if (newQty > (v.stockQty ?? 0)) {
          _error = 'Not enough stock available (${v.stockQty} left)';
          notifyListeners();
          return;
        }
        double base = basePrice * newQty;
        double tax = base * taxPct / 100;
        double cgst = _isIgst ? 0 : tax / 2;
        double sgst = _isIgst ? 0 : tax / 2;
        double igstAmount = _isIgst ? tax : 0;
        _currentItems[idx] = SaleItem(
          productVariantId: v.id!,
          quantity: newQty,
          price: basePrice,
          tax: tax,
          cgst: cgst,
          sgst: sgst,
          igstAmount: igstAmount,
          amount: base + tax,
          variantSku: v.sku,
          productName: v.displayName,
          availableStock: v.stockQty,
        );
        notifyListeners();
        return;
      }
    }
    double basePaint = basePrice * qty;
    double grossTinting = tintingCharge * qty;
    double baseTinting = grossTinting / (1 + taxPct / 100);
    double totalBase = basePaint + baseTinting;
    double tax = totalBase * taxPct / 100;
    double cgst = _isIgst ? 0 : tax / 2;
    double sgst = _isIgst ? 0 : tax / 2;
    double igstAmount = _isIgst ? tax : 0;

    String displayName = v.displayName;
    if (shadeCode != null && shadeCode.isNotEmpty) {
      displayName =
          '${v.productName ?? ''} ${v.packSize.toStringAsFixed(v.packSize == v.packSize.roundToDouble() ? 0 : 1)}${v.unitSymbol ?? ''}';
    }
    _currentItems.add(
      SaleItem(
        productVariantId: v.id!,
        quantity: qty,
        price: basePrice,
        tax: tax,
        cgst: cgst,
        sgst: sgst,
        igstAmount: igstAmount,
        amount: basePaint + tax,
        shadeCode: shadeCode,
        shadeName: shadeName,
        tintingCharge: baseTinting,
        variantSku: v.sku,
        productName: displayName,
        availableStock: v.stockQty,
      ),
    );
    notifyListeners();
  }

  void removeItem(int idx) {
    if (idx >= 0 && idx < _currentItems.length) {
      _currentItems.removeAt(idx);
      notifyListeners();
    }
  }

  void updateQty(int idx, double qty) {
    if (idx >= 0 && idx < _currentItems.length && qty > 0) {
      final i = _currentItems[idx];
      if (i.availableStock != null && qty > i.availableStock!) {
        _error = 'Not enough stock available (${i.availableStock} left)';
        notifyListeners();
        return;
      }
      double currentNetBase =
          (i.price * i.quantity) + i.tintingCharge - i.discount;
      double taxPct = currentNetBase > 0 ? (i.tax / currentNetBase * 100) : 0;

      double perUnitTinting = i.quantity > 0
          ? (i.tintingCharge / i.quantity)
          : 0;
      double newBaseTinting = perUnitTinting * qty;
      double newBasePaint = i.price * qty;
      double newTotalBase = newBasePaint + newBaseTinting;

      double newDiscount = i.discount > newTotalBase
          ? newTotalBase
          : i.discount;
      double newNetBase = newTotalBase - newDiscount;
      double newTax = newNetBase * taxPct / 100;
      double cgst = _isIgst ? 0 : newTax / 2;
      double sgst = _isIgst ? 0 : newTax / 2;
      double igstAmount = _isIgst ? newTax : 0;

      _currentItems[idx] = SaleItem(
        productVariantId: i.productVariantId,
        quantity: qty,
        price: i.price,
        tax: newTax,
        cgst: cgst,
        sgst: sgst,
        igstAmount: igstAmount,
        amount: newBasePaint + newTax,
        shadeCode: i.shadeCode,
        shadeName: i.shadeName,
        tintingCharge: newBaseTinting,
        discount: newDiscount,
        variantSku: i.variantSku,
        productName: i.productName,
        availableStock: i.availableStock,
      );
      notifyListeners();
    }
  }

  void updatePrice(int idx, double newPrice) {
    if (idx >= 0 && idx < _currentItems.length && newPrice >= 0) {
      final i = _currentItems[idx];
      double currentNetBase =
          (i.price * i.quantity) + i.tintingCharge - i.discount;
      double taxPct = currentNetBase > 0 ? (i.tax / currentNetBase * 100) : 0;

      double newBasePaint = newPrice * i.quantity;
      double newTotalBase = newBasePaint + i.tintingCharge;

      double newDiscount = i.discount > newTotalBase
          ? newTotalBase
          : i.discount;
      double newNetBase = newTotalBase - newDiscount;
      double newTax = newNetBase * taxPct / 100;
      double cgst = _isIgst ? 0 : newTax / 2;
      double sgst = _isIgst ? 0 : newTax / 2;
      double igstAmount = _isIgst ? newTax : 0;

      _currentItems[idx] = SaleItem(
        productVariantId: i.productVariantId,
        quantity: i.quantity,
        price: newPrice,
        tax: newTax,
        cgst: cgst,
        sgst: sgst,
        igstAmount: igstAmount,
        amount: newBasePaint + newTax,
        shadeCode: i.shadeCode,
        shadeName: i.shadeName,
        tintingCharge: i.tintingCharge,
        discount: newDiscount,
        variantSku: i.variantSku,
        productName: i.productName,
        availableStock: i.availableStock,
      );
      notifyListeners();
    }
  }

  void updateItemDiscount(int idx, double newDiscount) {
    if (idx >= 0 && idx < _currentItems.length && newDiscount >= 0) {
      final i = _currentItems[idx];
      double currentNetBase =
          (i.price * i.quantity) + i.tintingCharge - i.discount;
      double taxPct = currentNetBase > 0 ? (i.tax / currentNetBase * 100) : 0;

      double totalBase = (i.price * i.quantity) + i.tintingCharge;
      double boundedDiscount = newDiscount > totalBase
          ? totalBase
          : newDiscount;
      double newNetBase = totalBase - boundedDiscount;
      double newTax = newNetBase * taxPct / 100;
      double cgst = _isIgst ? 0 : newTax / 2;
      double sgst = _isIgst ? 0 : newTax / 2;
      double igstAmount = _isIgst ? newTax : 0;

      _currentItems[idx] = SaleItem(
        productVariantId: i.productVariantId,
        quantity: i.quantity,
        price: i.price,
        tax: newTax,
        cgst: cgst,
        sgst: sgst,
        igstAmount: igstAmount,
        amount: (i.price * i.quantity) + newTax,
        shadeCode: i.shadeCode,
        shadeName: i.shadeName,
        tintingCharge: i.tintingCharge,
        discount: boundedDiscount,
        variantSku: i.variantSku,
        productName: i.productName,
        availableStock: i.availableStock,
      );
      notifyListeners();
    }
  }

  Future<bool> processReturn(
    int saleId,
    Map<int, double> returnQtys, {
    String refundMethod = 'Ledger Adjustment',
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _svc.processReturn(saleId, returnQtys, refundMethod: refundMethod);
      await loadSales();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearSale() {
    _currentItems = [];
    _customerId = null;
    _customerName = null;
    _invoiceNumber = '';
    _discount = 0;
    _isDiscountPercent = false;
    _error = null;
    _applyTax = true;
    notifyListeners();
  }

  Future<bool> createSale({
    String status = 'completed',
    double? amountPaid,
  }) async {
    if (_currentItems.isEmpty) {
      _error = 'No items';
      notifyListeners();
      return false;
    }
    if (_customerId == null) {
      _error = 'Customer is required for all sales (even hold).';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final double paid =
          amountPaid ?? (_paymentStatus == 'unpaid' ? 0.0 : grandTotal);
      final itemsToSave = _applyTax
          ? _currentItems
          : _currentItems
                .map(
                  (i) => SaleItem(
                    id: i.id,
                    saleId: i.saleId,
                    productVariantId: i.productVariantId,
                    quantity: i.quantity,
                    returnedQuantity: i.returnedQuantity,
                    price: i.price,
                    costPrice: i.costPrice,
                    discount: i.discount,
                    tax: 0,
                    cgst: 0,
                    sgst: 0,
                    igstAmount: 0,
                    amount: (i.price * i.quantity),
                    shadeCode: i.shadeCode,
                    shadeName: i.shadeName,
                    tintingCharge: i.tintingCharge,
                    variantSku: i.variantSku,
                    productName: i.productName,
                    variantName: i.variantName,
                    unitSymbol: i.unitSymbol,
                    packSize: i.packSize,
                    availableStock: i.availableStock,
                  ),
                )
                .toList();
      await _svc.createSale(
        Sale(
          invoiceNumber: _invoiceNumber,
          customerId: _customerId,
          saleDate: DateTime.now(),
          subtotal: subtotal,
          discount: calculatedDiscount,
          tax: totalTax,
          cgst: totalCgst,
          sgst: totalSgst,
          igstAmount: totalIgst,
          totalAmount: grandTotal,
          amountPaid: paid,
          status: status,
          paymentMethod: _paymentMethod,
          paymentStatus: _paymentStatus,
          isIgst: _isIgst,
          notes: _notes,
          items: itemsToSave,
        ),
      );
      clearSale();
      await loadSales();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> resumeHoldOrder(Sale sale) async {
    _currentItems = sale.items ?? [];
    _customerId = sale.customerId;
    _customerName = sale.customerName;
    _discount = sale.discount;
    _isDiscountPercent = false;
    _isIgst = sale.isIgst;
    _notes = sale.notes ?? '';
    _invoiceNumber = await _svc.generateInvoiceNumber();
    notifyListeners();
    if (sale.id != null) {
      await deleteSale(sale.id!);
    }
  }

  Future<Sale?> getSaleDetails(int id) async {
    try {
      return await _svc.getById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteSale(int id) async {
    try {
      await _svc.deleteSale(id);
      await loadSales();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
