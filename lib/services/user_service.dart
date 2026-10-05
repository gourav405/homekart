import 'database_service.dart';
import '../models/user.dart';

class UserService {
  final DatabaseService _db = DatabaseService();

  Future<List<User>> getAllUsers() async {
    final res = await _db.query('SELECT id, username, role FROM users ORDER BY role ASC, username ASC');
    return res.rows.map((r) => User.fromMap(r.assoc())).toList();
  }

  Future<void> addUser(String username, String password, String role) async {
    await _db.query(
      'INSERT INTO users (username, password, role) VALUES (:u, :p, :r)',
      {'u': username, 'p': password, 'r': role}
    );
  }

  Future<void> updatePassword(int id, String newPassword) async {
    await _db.query(
      'UPDATE users SET password = :p WHERE id = :id',
      {'p': newPassword, 'id': id}
    );
  }

  Future<void> deleteUser(int id) async {
    await _db.query('DELETE FROM users WHERE id = :id', {'id': id});
  }
}
