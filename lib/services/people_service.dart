import '../models/customer.dart';
import '../models/supplier.dart';
import 'database_service.dart';

class CustomerService {
  final DatabaseService _db = DatabaseService();

  Future<List<Customer>> getAll({String? search}) async {
    String sql = 'SELECT * FROM customers';
    Map<String, dynamic> params = {};
    if (search != null && search.isNotEmpty) { sql += ' WHERE name LIKE :s OR phone LIKE :s OR email LIKE :s'; params['s'] = '%$search%'; }
    sql += ' ORDER BY name';
    final r = await _db.query(sql, params);
    return r.rows.map((row) => Customer.fromMap(row.assoc())).toList();
  }

  Future<int> create(Customer c) async {
    final r = await _db.query('INSERT INTO customers (name, phone, email, gst_number, address, state) VALUES (:n, :p, :e, :g, :a, :st)', {'n': c.name, 'p': c.phone ?? '', 'e': c.email ?? '', 'g': c.gstNumber ?? '', 'a': c.address ?? '', 'st': c.state ?? ''});
    return r.lastInsertID.toInt();
  }

  Future<void> update(Customer c) async {
    await _db.query('UPDATE customers SET name=:n, phone=:p, email=:e, gst_number=:g, address=:a, state=:st, updated_at=NOW() WHERE id=:id', {'id': c.id, 'n': c.name, 'p': c.phone ?? '', 'e': c.email ?? '', 'g': c.gstNumber ?? '', 'a': c.address ?? '', 'st': c.state ?? ''});
  }

  Future<void> delete(int id) async { await _db.query('DELETE FROM customers WHERE id=:id', {'id': id}); }
}

class SupplierService {
  final DatabaseService _db = DatabaseService();

  Future<List<Supplier>> getAll({String? search}) async {
    String sql = 'SELECT * FROM suppliers WHERE is_active=1';
    Map<String, dynamic> params = {};
    if (search != null && search.isNotEmpty) { sql += ' AND (name LIKE :s OR phone LIKE :s)'; params['s'] = '%$search%'; }
    sql += ' ORDER BY name';
    final r = await _db.query(sql, params);
    return r.rows.map((row) => Supplier.fromMap(row.assoc())).toList();
  }

  Future<int> create(Supplier s) async {
    final r = await _db.query('INSERT INTO suppliers (name, phone, email, gst_number, address) VALUES (:n, :p, :e, :g, :a)', {'n': s.name, 'p': s.phone ?? '', 'e': s.email ?? '', 'g': s.gstNumber ?? '', 'a': s.address ?? ''});
    return r.lastInsertID.toInt();
  }

  Future<void> update(Supplier s) async {
    await _db.query('UPDATE suppliers SET name=:n, phone=:p, email=:e, gst_number=:g, address=:a, updated_at=NOW() WHERE id=:id', {'id': s.id, 'n': s.name, 'p': s.phone ?? '', 'e': s.email ?? '', 'g': s.gstNumber ?? '', 'a': s.address ?? ''});
  }

  Future<void> delete(int id) async { await _db.query('UPDATE suppliers SET is_active=0 WHERE id=:id', {'id': id}); }
}
