import 'lib/services/database_service.dart';
void main() async {
  final db = DatabaseService();
  final r = await db.query('SELECT pv.* FROM product_variants pv LIMIT 1');
  print(r.rows.first.assoc());
}
