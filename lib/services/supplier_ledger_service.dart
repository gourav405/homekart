import 'database_service.dart';

class SupplierLedgerService {
  final DatabaseService _db = DatabaseService();

  Future<List<Map<String, dynamic>>> getSupplierBalances() async {
    final r = await _db.query('''
      SELECT s.id, s.name, s.phone,
        COALESCE(SUM((p.total_amount - p.returned_amount) - p.amount_paid), 0) as total_debt
      FROM suppliers s
      LEFT JOIN purchases p ON s.id = p.supplier_id AND p.payment_status IN ('unpaid', 'partial')
      GROUP BY s.id
      ORDER BY total_debt DESC, s.name ASC
    ''');
    return r.rows.map((row) => row.assoc()).toList();
  }

  Future<List<Map<String, dynamic>>> getUnpaidPurchases(int supplierId) async {
    final r = await _db.query('''
      SELECT id, invoice_number, purchase_date, total_amount, amount_paid, payment_status
      FROM purchases
      WHERE supplier_id = :sid AND payment_status IN ('unpaid', 'partial')
      ORDER BY purchase_date ASC
    ''', {'sid': supplierId});
    return r.rows.map((row) => row.assoc()).toList();
  }

  Future<void> makePayment(int supplierId, double amount, String method, String notes) async {
    final conn = await _db.connection;
    await conn.execute('START TRANSACTION');
    try {
      // 1. Record payment
      await conn.execute(
        'INSERT INTO supplier_payments (supplier_id, payment_date, amount, payment_method, notes) VALUES (:sid, CURDATE(), :amt, :meth, :not)',
        {'sid': supplierId, 'amt': amount, 'meth': method, 'not': notes}
      );

      // 2. FIFO Allocation
      final unpaid = await conn.execute(
        'SELECT id, total_amount, returned_amount, amount_paid FROM purchases WHERE supplier_id = :sid AND payment_status IN ("unpaid", "partial") ORDER BY purchase_date ASC',
        {'sid': supplierId}
      );

      double remainingPayment = amount;
      for (var row in unpaid.rows) {
        if (remainingPayment <= 0) break;
        var map = row.assoc();
        int pid = int.parse(map['id']!);
        double total = double.parse(map['total_amount']!);
        double returned = double.parse(map['returned_amount']!);
        double paid = double.parse(map['amount_paid']!);
        double trueTotal = total - returned;
        double due = trueTotal - paid;

        if (due <= 0) {
          await conn.execute('UPDATE purchases SET payment_status = "paid" WHERE id = :id', {'id': pid});
          continue;
        }

        double allocation = remainingPayment >= due ? due : remainingPayment;
        double newPaid = paid + allocation;
        String newStatus = newPaid >= trueTotal ? 'paid' : 'partial';

        await conn.execute(
          'UPDATE purchases SET amount_paid = :paid, payment_status = :stat WHERE id = :id',
          {'paid': newPaid, 'stat': newStatus, 'id': pid}
        );
        remainingPayment -= allocation;
      }
      
      await conn.execute('COMMIT');
    } catch (e) {
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPayments(int supplierId) async {
    final r = await _db.query('''
      SELECT id, payment_date, amount, payment_method, notes
      FROM supplier_payments
      WHERE supplier_id = :sid
      ORDER BY payment_date DESC, created_at DESC
    ''', {'sid': supplierId});
    return r.rows.map((row) => row.assoc()).toList();
  }
}
