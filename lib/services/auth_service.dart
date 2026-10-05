import 'database_service.dart';

class User {
  final int id;
  final String username;
  final String role;

  User({required this.id, required this.username, required this.role});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: int.parse(map['id'].toString()),
      username: map['username'],
      role: map['role'],
    );
  }
}

class AuthService {
  final DatabaseService _db = DatabaseService();

  Future<User?> login(String username, String password) async {
    final r = await _db.query(
      'SELECT id, username, role FROM users WHERE username = :u AND password = :p',
      {'u': username, 'p': password}
    );
    if (r.rows.isNotEmpty) {
      return User.fromMap(r.rows.first.assoc());
    }
    return null;
  }
}
