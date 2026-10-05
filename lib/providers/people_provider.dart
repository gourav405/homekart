import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../services/people_service.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerService _svc = CustomerService();
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async { _isLoading = true; notifyListeners(); try { _customers = await _svc.getAll(); } catch (e) { _error = e.toString(); } _isLoading = false; notifyListeners(); }
  void search(String q) async { try { _customers = await _svc.getAll(search: q.isNotEmpty ? q : null); notifyListeners(); } catch (e) { _error = e.toString(); notifyListeners(); } }
  Future<bool> add(Customer c) async { try { await _svc.create(c); await load(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> update(Customer c) async { try { await _svc.update(c); await load(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> delete(int id) async { try { await _svc.delete(id); await load(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
}

class SupplierProvider extends ChangeNotifier {
  final SupplierService _svc = SupplierService();
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _error;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async { _isLoading = true; notifyListeners(); try { _suppliers = await _svc.getAll(); } catch (e) { _error = e.toString(); } _isLoading = false; notifyListeners(); }
  void search(String q) async { try { _suppliers = await _svc.getAll(search: q.isNotEmpty ? q : null); notifyListeners(); } catch (e) { _error = e.toString(); notifyListeners(); } }
  Future<bool> add(Supplier s) async { try { await _svc.create(s); await load(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> update(Supplier s) async { try { await _svc.update(s); await load(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> delete(int id) async { try { await _svc.delete(id); await load(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
}
