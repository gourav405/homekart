import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import "../services/audit_service.dart";

class AuthProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  User? _currentUser;
  User? get currentUser => _currentUser;
  
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String get role => _currentUser?.role ?? '';
  
  String? _error;
  String? get error => _error;

  Future<bool> login(String username, String password) async {
    _error = null;
    notifyListeners();
    
    try {
      final res = await _db.query(
        'SELECT id, username, role FROM users WHERE username = :u AND password = :p', 
        {'u': username, 'p': password}
      );
      
      if (res.rows.isNotEmpty) {
        _currentUser = User.fromMap(res.rows.first.assoc());
        await AuditService().log(
          action: 'LOGIN',
          entityType: 'user',
          userId: _currentUser!.id,
          username: _currentUser!.username,
          description: 'User logged in',
        );
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid username or password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Database error: $e';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    if (_currentUser != null) {
      AuditService().log(
        action: 'LOGOUT',
        entityType: 'user',
        userId: _currentUser!.id,
        username: _currentUser!.username,
        description: 'User logged out',
      );
    }
    _currentUser = null;
    notifyListeners();
  }
}
