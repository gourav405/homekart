import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/sale_service.dart';

class DashboardProvider extends ChangeNotifier {
  final SaleService _svc = SaleService();
  DashboardData? _data;
  bool _isLoading = false;
  String? _error;

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _data = null;
    notifyListeners();
    try {
      _data = await _svc.getDashboardData();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
