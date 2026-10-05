import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _svc = ExpenseService();
  
  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  Future<void> loadExpenses() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      _expenses = await _svc.getAll();
    } catch (e) { _error = e.toString(); }
    _isLoading = false; notifyListeners();
  }

  Future<bool> addExpense(Expense e) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      await _svc.createExpense(e);
      await loadExpenses();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      await _svc.deleteExpense(id);
      await loadExpenses();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false; notifyListeners();
      return false;
    }
  }
}
