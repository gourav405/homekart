import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _svc = SettingsService();
  Map<String, String> _settings = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  String get businessName => _settings['business_name'] ?? 'Kewal Hardware Store';
  String get businessAddress => _settings['business_address'] ?? '';
  String get businessPhone => _settings['business_phone'] ?? '';
  String get businessEmail => _settings['business_email'] ?? '';
  String get gstin => _settings['business_gstin'] ?? '';
  String get businessLogo => _settings['business_logo'] ?? '';
  String get upiId => _settings['business_upi_id'] ?? '';
  String get businessState => _settings['business_state'] ?? '';

  Future<void> load() async { _isLoading = true; notifyListeners(); _settings = await _svc.getAll(); _isLoading = false; notifyListeners(); }
  Future<bool> updateSetting(String k, String v) async { final ok = await _svc.update(k, v); if (ok) { _settings[k] = v; notifyListeners(); } return ok; }
  Future<bool> updateBusinessInfo(Map<String, String> info) async { for (var e in info.entries) { await _svc.update(e.key, e.value); _settings[e.key] = e.value; } notifyListeners(); return true; }
}
