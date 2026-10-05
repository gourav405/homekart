import 'package:intl/intl.dart';
import '../models/sale.dart';
import 'database_service.dart';

class LedgerService {
  final DatabaseService _db = DatabaseService();

  Future<List<Map<String, dynamic>>> getCustomerBalances() async {
    final sql = '''
      SELECT 
        c.id, c.name, c.phone,
        COALESCE(SUM(s.total_amount - s.returned_amount - s.amount_paid), 0) as balance_due
      FROM customers c
      JOIN sales s ON c.id = s.customer_id
      WHERE s.status IN ('completed', 'hold') AND s.payment_status IN ('partial', 'unpaid')
      GROUP BY c.id, c.name, c.phone
      HAVING balance_due > 0
      ORDER BY balance_due DESC
    ''';
    final r = await _db.query(sql);
    return r.rows.map((row) => row.assoc()).toList();
  }

  Future<List<Sale>> getCustomerUnpaidInvoices(int customerId) async {
    final sql = '''
      SELECT s.*, c.name as customer_name 
      FROM sales s 
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.customer_id = :cid AND s.payment_status IN ('partial', 'unpaid') 
        AND (s.total_amount - s.returned_amount - s.amount_paid) > 0
      ORDER BY s.sale_date ASC
    ''';
    final r = await _db.query(sql, {'cid': customerId});
    return r.rows.map((row) => Sale.fromMap(row.assoc())).toList();
  }
  
  Future<List<Map<String, dynamic>>> getCustomerPayments(int customerId) async {
    final sql = 'SELECT * FROM customer_payments WHERE customer_id = :cid ORDER BY payment_date DESC';
    final r = await _db.query(sql, {'cid': customerId});
    return r.rows.map((row) => row.assoc()).toList();
  }

  Future<void> receivePayment(int customerId, double amount, String paymentMethod, String notes) async {
    final conn = await _db.connection;
    await conn.execute('START TRANSACTION');
    try {
      final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      
      // 1. Log the payment
      await conn.execute(
        'INSERT INTO customer_payments (customer_id, payment_date, amount, payment_method, notes) VALUES (:cid, :d, :amt, :pm, :n)',
        {'cid': customerId, 'd': now, 'amt': amount, 'pm': paymentMethod, 'n': notes}
      );

      // 2. Fetch unpaid invoices ordered by oldest first
      final r = await conn.execute(
        "SELECT id, total_amount, returned_amount, amount_paid FROM sales WHERE customer_id = :cid AND payment_status IN ('partial', 'unpaid') AND (total_amount - returned_amount - amount_paid) > 0 ORDER BY sale_date ASC",
        {'cid': customerId}
      );

      double remainingToAllocate = amount;

      for (var row in r.rows) {
        if (remainingToAllocate <= 0) break;
        
        final m = row.assoc();
        final int saleId = int.parse(m['id']!);
        final double total = double.parse(m['total_amount']!);
        final double returned = double.parse(m['returned_amount']!);
        final double currentPaid = double.parse(m['amount_paid']!);
        
        final double dueOnThisInvoice = total - returned - currentPaid;
        
        if (dueOnThisInvoice > 0) {
          double allocateToThis = remainingToAllocate >= dueOnThisInvoice ? dueOnThisInvoice : remainingToAllocate;
          double newPaid = currentPaid + allocateToThis;
          String newStatus = (newPaid >= (total - returned)) ? 'paid' : 'partial';
          
          await conn.execute(
            'UPDATE sales SET amount_paid = :paid, payment_status = :ps WHERE id = :id',
            {'paid': newPaid, 'ps': newStatus, 'id': saleId}
          );
          
          remainingToAllocate -= allocateToThis;
        }
      }

      await conn.execute('COMMIT');
    } catch (e) {
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }
}
