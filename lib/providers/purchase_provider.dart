import 'package:flutter/material.dart';
import '../models/purchase.dart';
import '../services/purchase_service.dart';

import '../models/product_variant.dart';

class PurchaseProvider extends ChangeNotifier {
  final PurchaseService _svc = PurchaseService();
  
  List<Purchase> _purchases = [];
  List<Purchase> get purchases => _purchases;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  int? _supplierId;
  String? _supplierName;
  String _invoiceNumber = '';
  String? _notes;
  List<PurchaseItem> _currentItems = [];

  String _paymentStatus = 'paid';
  String _paymentMethod = 'Cash';
  double _amountPaid = 0.0;
  
  int? get supplierId => _supplierId;
  String? get supplierName => _supplierName;
  String get invoiceNumber => _invoiceNumber;
  String? get notes => _notes;
  List<PurchaseItem> get currentItems => _currentItems;
  double get total => _currentItems.fold(0, (s, i) => s + i.amount);

  String get paymentStatus => _paymentStatus;
  double get amountPaid => _amountPaid;
  String get paymentMethod => _paymentMethod;

  void setSupplier(int id, String name) { _supplierId = id; _supplierName = name; notifyListeners(); }
  void setInvoiceNumber(String n) { _invoiceNumber = n; notifyListeners(); }
  void setNotes(String n) { _notes = n; notifyListeners(); }
  
  void setPaymentStatus(String s) { _paymentStatus = s; notifyListeners(); }
  void setAmountPaid(double a) { _amountPaid = a; notifyListeners(); }
  void setPaymentMethod(String m) { _paymentMethod = m; notifyListeners(); }

  Future<void> loadPurchases({String? search}) async {
    _isLoading = true; _error = null; notifyListeners();
    try { _purchases = await _svc.getAll(search: search); } catch (e) { _error = e.toString(); }
    _isLoading = false; notifyListeners();
  }

  void addItem(ProductVariant v, double qty, double price) { 
    _currentItems.add(PurchaseItem(
      productVariantId: v.id!,
      variantSku: v.sku,
      productName: v.productName,
      unitSymbol: v.unitSymbol,
      packSize: v.packSize,
      quantity: qty,
      purchasePrice: price,
      amount: qty * price,
    ));
    notifyListeners(); 
  }
  void removeItem(int idx) { if (idx >= 0 && idx < _currentItems.length) { _currentItems.removeAt(idx); notifyListeners(); } }

  void clearPurchase() { _currentItems = []; _supplierId = null; _supplierName = null; _invoiceNumber = ''; _notes = ''; _error = null; _paymentStatus = 'paid'; _paymentMethod = 'Cash'; _amountPaid = 0.0; notifyListeners(); }

  Future<bool> createPurchase() async {
    if (_currentItems.isEmpty || _supplierId == null || _invoiceNumber.isEmpty) { _error = 'Fill all fields'; notifyListeners(); return false; }
    _isLoading = true; notifyListeners();
    try {
      await _svc.createPurchase(Purchase(invoiceNumber: _invoiceNumber, supplierId: _supplierId!, purchaseDate: DateTime.now(), totalAmount: total, notes: _notes, paymentStatus: _paymentStatus, amountPaid: _paymentStatus == 'paid' ? total : _amountPaid, paymentMethod: _paymentMethod, items: _currentItems));
      clearPurchase(); await loadPurchases(); return true;
    } catch (e) { _error = e.toString(); _isLoading = false; notifyListeners(); return false; }
  }

  Future<Purchase?> getDetails(int id) async { try { return await _svc.getById(id); } catch (e) { _error = e.toString(); notifyListeners(); return null; } }
  Future<bool> processReturn(int purchaseId, int purchaseItemId, double qty, double amount, String method) async { try { await _svc.processReturn(purchaseId, purchaseItemId, qty, amount, refundMethod: method); await loadPurchases(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> deletePurchase(int id) async { try { await _svc.deletePurchase(id); await loadPurchases(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
}
