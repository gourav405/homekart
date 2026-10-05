import 'package:flutter/material.dart';
import '../services/supplier_ledger_service.dart';

class SupplierLedgerProvider extends ChangeNotifier {
  final _svc = SupplierLedgerService();

  List<Map<String, dynamic>> _balances = [];
  List<Map<String, dynamic>> get balances => _balances;

  List<Map<String, dynamic>> _unpaidInvoices = [];
  List<Map<String, dynamic>> get unpaidInvoices => _unpaidInvoices;

  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> get payments => _payments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadBalances() async {
    _isLoading = true; notifyListeners();
    _balances = await _svc.getSupplierBalances();
    _isLoading = false; notifyListeners();
  }

  Future<void> loadSupplierDetails(int supplierId) async {
    _unpaidInvoices = await _svc.getUnpaidPurchases(supplierId);
    _payments = await _svc.getPayments(supplierId);
    notifyListeners();
  }

  Future<bool> receivePayment(int supplierId, double amount, String method, String notes) async {
    try {
      await _svc.makePayment(supplierId, amount, method, notes);
      await loadBalances();
      await loadSupplierDetails(supplierId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
