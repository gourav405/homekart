import 'package:intl/intl.dart';
import '../models/expense.dart';
import 'database_service.dart';

class ExpenseService {
  final DatabaseService _db = DatabaseService();

  Future<List<Expense>> getAll() async {
    final r = await _db.query('SELECT * FROM expenses ORDER BY expense_date DESC, created_at DESC');
    return r.rows.map((row) => Expense.fromMap(row.assoc())).toList();
  }

  Future<int> createExpense(Expense e) async {
    final d = DateFormat('yyyy-MM-dd').format(e.expenseDate);
    final r = await _db.query(
      'INSERT INTO expenses (expense_date, category, amount, payment_method, notes) VALUES (:d, :c, :a, :p, :n)',
      {'d': d, 'c': e.category, 'a': e.amount, 'p': e.paymentMethod, 'n': e.notes ?? ''}
    );
    return r.lastInsertID.toInt();
  }

  Future<void> deleteExpense(int id) async {
    await _db.query('DELETE FROM expenses WHERE id = :id', {'id': id});
  }
}
