import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../services/ledger_service.dart';

class LedgerProvider extends ChangeNotifier {
  final LedgerService _svc = LedgerService();

  List<Map<String, dynamic>> _balances = [];
  List<Map<String, dynamic>> get balances => _balances;

  List<Sale> _unpaidInvoices = [];
  List<Sale> get unpaidInvoices => _unpaidInvoices;
  
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> get payments => _payments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  Future<void> loadBalances() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      _balances = await _svc.getCustomerBalances();
    } catch (e) { _error = e.toString(); }
    _isLoading = false; notifyListeners();
  }

  Future<void> loadCustomerDetails(int customerId) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      _unpaidInvoices = await _svc.getCustomerUnpaidInvoices(customerId);
      _payments = await _svc.getCustomerPayments(customerId);
    } catch (e) { _error = e.toString(); }
    _isLoading = false; notifyListeners();
  }

  Future<bool> receivePayment(int customerId, double amount, String method, String notes) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      await _svc.receivePayment(customerId, amount, method, notes);
      await loadCustomerDetails(customerId);
      await loadBalances();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false; notifyListeners();
      return false;
    }
  }
}
