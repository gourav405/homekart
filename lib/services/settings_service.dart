import 'database_service.dart';

class SettingsService {
  final DatabaseService _db = DatabaseService();

  Future<Map<String, String>> getAll() async {
    final r = await _db.query('SELECT setting_key, setting_value FROM settings');
    Map<String, String> settings = {};
    for (var row in r.rows) { var m = row.assoc(); if (m['setting_key'] != null) settings[m['setting_key']!] = m['setting_value'] ?? ''; }
    return settings;
  }

  Future<bool> update(String key, String value) async {
    try {
      await _db.query('INSERT INTO settings (setting_key, setting_value) VALUES (:k, :v) ON DUPLICATE KEY UPDATE setting_value=:v2, updated_at=NOW()', {'k': key, 'v': value, 'v2': value});
      return true;
    } catch (_) { return false; }
  }
}
