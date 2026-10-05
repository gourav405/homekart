import '../models/sale.dart';
import '../models/dashboard_data.dart';
import 'database_service.dart';
import 'inventory_service.dart';
import 'package:intl/intl.dart';

class SaleService {
  final DatabaseService _db = DatabaseService();
  final InventoryService _inv = InventoryService();

  Future<List<Sale>> getAll({
    String? search,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    String sql =
        'SELECT s.*, c.name as customer_name FROM sales s LEFT JOIN customers c ON s.customer_id = c.id WHERE 1=1';
    Map<String, dynamic> params = {};
    if (search != null && search.isNotEmpty) {
      sql += ' AND (s.invoice_number LIKE :s OR c.name LIKE :s)';
      params['s'] = '%$search%';
    }
    if (status != null) {
      sql += ' AND s.payment_status = :st';
      params['st'] = status;
    }
    if (from != null) {
      sql += ' AND s.sale_date >= :fr';
      params['fr'] = DateFormat('yyyy-MM-dd').format(from);
    }
    if (to != null) {
      sql += ' AND s.sale_date <= :to';
      params['to'] = DateFormat('yyyy-MM-dd 23:59:59').format(to);
    }
    sql += ' ORDER BY s.created_at DESC';
    final r = await _db.query(sql, params);
    return r.rows.map((row) => Sale.fromMap(row.assoc())).toList();
  }

  Future<Sale?> getById(int id) async {
    final r = await _db.query(
      'SELECT s.*, c.name as customer_name FROM sales s LEFT JOIN customers c ON s.customer_id = c.id WHERE s.id=:id',
      {'id': id},
    );
    if (r.rows.isEmpty) return null;
    final items = await _db.query(
      'SELECT si.*, pv.sku as variant_sku, pv.variant_name, p.name as product_name, u.symbol as unit_symbol, pv.pack_size FROM sale_items si JOIN product_variants pv ON si.product_variant_id = pv.id JOIN products p ON pv.product_id = p.id JOIN units u ON pv.unit_id = u.id WHERE si.sale_id=:id',
      {'id': id},
    );
    final returns = await _db.query(
      'SELECT * FROM sale_returns_log WHERE sale_id=:id ORDER BY return_date ASC',
      {'id': id},
    );

    return Sale.fromMap(
      r.rows.first.assoc(),
      items: items.rows.map((row) => SaleItem.fromMap(row.assoc())).toList(),
      returnLogs: returns.rows
          .map((row) => SaleReturnLog.fromMap(row.assoc()))
          .toList(),
    );
  }

  Future<String> generateInvoiceNumber() async {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    final r = await _db.query(
      'SELECT COUNT(*) as cnt FROM sales WHERE DATE(sale_date) = CURDATE()',
    );
    int cnt = int.parse(r.rows.first.assoc()['cnt'] ?? '0');
    return 'HK-$today-${(cnt + 1).toString().padLeft(3, '0')}';
  }

  Future<int> createSale(Sale sale) async {
    final conn = await _db.connection;
    await conn.execute('START TRANSACTION');
    try {
      final r = await conn.execute(
        'INSERT INTO sales (invoice_number, customer_id, sale_date, subtotal, discount, tax, cgst, sgst, igst, total_amount, amount_paid, status, payment_method, payment_status, is_igst, notes) VALUES (:inv, :cid, :date, :sub, :disc, :tax, :cgst, :sgst, :igst, :total, :paid, :stat, :pm, :ps, :is_igst, :notes)',
        {
          'inv': sale.invoiceNumber,
          'cid': sale.customerId,
          'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(sale.saleDate),
          'sub': sale.subtotal,
          'disc': sale.discount,
          'tax': sale.tax,
          'cgst': sale.cgst,
          'sgst': sale.sgst,
          'igst': sale.igstAmount,
          'total': sale.totalAmount,
          'paid': sale.amountPaid,
          'stat': sale.status,
          'pm': sale.paymentMethod,
          'ps': sale.paymentStatus,
          'is_igst': sale.isIgst ? 1 : 0,
          'notes': sale.notes ?? '',
        },
      );
      int saleId = r.lastInsertID.toInt();
      if (sale.items != null) {
        for (var item in sale.items!) {
          final pvRes = await conn.execute(
            'SELECT purchase_price FROM product_variants WHERE id = :id',
            {'id': item.productVariantId},
          );
          double currentCost = pvRes.rows.isNotEmpty
              ? (double.tryParse(pvRes.rows.first.assoc()['purchase_price']!) ??
                    0.0)
              : 0.0;

          await conn.execute(
            'INSERT INTO sale_items (sale_id, product_variant_id, quantity, price, cost_price, discount, tax, cgst, sgst, igst, amount, shade_code, shade_name, tinting_charge) VALUES (:sid, :vid, :qty, :p, :cp, :d, :t, :cgst, :sgst, :igst, :a, :sc, :sn, :tc)',
            {
              'sid': saleId,
              'vid': item.productVariantId,
              'qty': item.quantity,
              'p': item.price,
              'cp': currentCost,
              'd': item.discount,
              't': item.tax,
              'cgst': item.cgst,
              'sgst': item.sgst,
              'igst': item.igstAmount,
              'a': item.amount,
              'sc': item.shadeCode,
              'sn': item.shadeName,
              'tc': item.tintingCharge,
            },
          );
          await _inv.addStockMovement(
            item.productVariantId,
            'SALE',
            item.quantity,
            referenceId: saleId,
            remarks: 'Sale ${sale.invoiceNumber}',
          );
        }
      }
      await conn.execute('COMMIT');
      return saleId;
    } catch (e) {
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> deleteSale(int id) async {
    final conn = await _db.connection;
    await conn.execute('START TRANSACTION');
    try {
      final items = await conn.execute(
        'SELECT product_variant_id, quantity FROM sale_items WHERE sale_id=:id',
        {'id': id},
      );
      for (var row in items.rows) {
        final m = row.assoc();
        await _inv.addStockMovement(
          int.parse(m['product_variant_id']!),
          'RETURN',
          double.parse(m['quantity']!),
          referenceId: id,
          remarks: 'Sale deleted',
        );
      }
      await conn.execute('DELETE FROM sale_items WHERE sale_id=:id', {
        'id': id,
      });
      await conn.execute('DELETE FROM sales WHERE id=:id', {'id': id});
      await conn.execute('COMMIT');
    } catch (e) {
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<DashboardData> getDashboardData() async {
    final tp = await _db.query('SELECT COUNT(*) as c FROM products');
    final tv = await _db.query('SELECT COUNT(*) as c FROM product_variants');
    final ls = await _db.query(
      'SELECT COUNT(*) as c FROM inventory i JOIN product_variants pv ON i.product_variant_id = pv.id WHERE i.minimum_stock > 0 AND i.quantity <= i.minimum_stock AND pv.is_active = 1',
    );
    final tc = await _db.query('SELECT COUNT(*) as c FROM customers');
    final ts = await _db.query('SELECT COUNT(*) as c FROM suppliers');

    // Revenue aggregates (net revenue = deduct tax for remittable products, keep tax for non-remittable like tinting)
    final s_agg = await _db.query('''SELECT 
      SUM(CASE WHEN DATE(s.sale_date) = CURDATE() THEN
        CASE WHEN p.tax_remittable = 1 THEN ((si.amount - si.tax) / si.quantity) ELSE (si.amount / si.quantity) END * (si.quantity - si.returned_quantity)
      ELSE 0 END) as t_s,
      SUM(CASE WHEN DATE(s.sale_date) = CURDATE() - INTERVAL 1 DAY THEN
        CASE WHEN p.tax_remittable = 1 THEN ((si.amount - si.tax) / si.quantity) ELSE (si.amount / si.quantity) END * (si.quantity - si.returned_quantity)
      ELSE 0 END) as yt_s,
      SUM(CASE WHEN MONTH(s.sale_date) = MONTH(CURDATE()) AND YEAR(s.sale_date) = YEAR(CURDATE()) THEN
        CASE WHEN p.tax_remittable = 1 THEN ((si.amount - si.tax) / si.quantity) ELSE (si.amount / si.quantity) END * (si.quantity - si.returned_quantity)
      ELSE 0 END) as m_s,
      SUM(CASE WHEN MONTH(s.sale_date) = MONTH(CURDATE() - INTERVAL 1 MONTH) AND YEAR(s.sale_date) = YEAR(CURDATE() - INTERVAL 1 MONTH) THEN
        CASE WHEN p.tax_remittable = 1 THEN ((si.amount - si.tax) / si.quantity) ELSE (si.amount / si.quantity) END * (si.quantity - si.returned_quantity)
      ELSE 0 END) as pm_s,
      SUM(CASE WHEN YEAR(s.sale_date - INTERVAL 3 MONTH) = YEAR(CURDATE() - INTERVAL 3 MONTH) THEN
        CASE WHEN p.tax_remittable = 1 THEN ((si.amount - si.tax) / si.quantity) ELSE (si.amount / si.quantity) END * (si.quantity - si.returned_quantity)
      ELSE 0 END) as y_s,
      SUM(CASE WHEN YEAR(s.sale_date - INTERVAL 3 MONTH) = YEAR(CURDATE() - INTERVAL 3 MONTH) - 1 THEN
        CASE WHEN p.tax_remittable = 1 THEN ((si.amount - si.tax) / si.quantity) ELSE (si.amount / si.quantity) END * (si.quantity - si.returned_quantity)
      ELSE 0 END) as py_s,
            SUM(CASE WHEN DATE(s.sale_date) = CURDATE() THEN si.cost_price * (si.quantity - si.returned_quantity) ELSE 0 END) as t_cogs,
      SUM(CASE WHEN DATE(s.sale_date) = CURDATE() - INTERVAL 1 DAY THEN si.cost_price * (si.quantity - si.returned_quantity) ELSE 0 END) as yt_cogs,
      SUM(CASE WHEN MONTH(s.sale_date) = MONTH(CURDATE()) AND YEAR(s.sale_date) = YEAR(CURDATE()) THEN si.cost_price * (si.quantity - si.returned_quantity) ELSE 0 END) as m_cogs,
      SUM(CASE WHEN MONTH(s.sale_date) = MONTH(CURDATE() - INTERVAL 1 MONTH) AND YEAR(s.sale_date) = YEAR(CURDATE() - INTERVAL 1 MONTH) THEN si.cost_price * (si.quantity - si.returned_quantity) ELSE 0 END) as pm_cogs,
      SUM(CASE WHEN YEAR(s.sale_date - INTERVAL 3 MONTH) = YEAR(CURDATE() - INTERVAL 3 MONTH) THEN si.cost_price * (si.quantity - si.returned_quantity) ELSE 0 END) as y_cogs,
      SUM(CASE WHEN YEAR(s.sale_date - INTERVAL 3 MONTH) = YEAR(CURDATE() - INTERVAL 3 MONTH) - 1 THEN si.cost_price * (si.quantity - si.returned_quantity) ELSE 0 END) as py_cogs,
      SUM(si.cost_price * (si.quantity - si.returned_quantity)) as total_cogs,
      SUM(
        CASE WHEN p.tax_remittable = 1 THEN ((si.amount - si.tax) / si.quantity) ELSE (si.amount / si.quantity) END * (si.quantity - si.returned_quantity)
      ) as total
    FROM sale_items si
    JOIN sales s ON si.sale_id = s.id
    JOIN product_variants pv ON si.product_variant_id = pv.id
    JOIN products p ON pv.product_id = p.id''');

    // Purchase aggregates
    final p_agg = await _db.query('''SELECT 
      SUM(CASE WHEN DATE(purchase_date) = CURDATE() THEN total_amount ELSE 0 END) as t_p,
      SUM(CASE WHEN DATE(purchase_date) = CURDATE() - INTERVAL 1 DAY THEN total_amount ELSE 0 END) as yt_p,
      SUM(CASE WHEN MONTH(purchase_date) = MONTH(CURDATE()) AND YEAR(purchase_date) = YEAR(CURDATE()) THEN total_amount ELSE 0 END) as m_p,
      SUM(CASE WHEN MONTH(purchase_date) = MONTH(CURDATE() - INTERVAL 1 MONTH) AND YEAR(purchase_date) = YEAR(CURDATE() - INTERVAL 1 MONTH) THEN total_amount ELSE 0 END) as pm_p,
      SUM(CASE WHEN YEAR(purchase_date - INTERVAL 3 MONTH) = YEAR(CURDATE() - INTERVAL 3 MONTH) THEN total_amount ELSE 0 END) as y_p,
      SUM(CASE WHEN YEAR(purchase_date - INTERVAL 3 MONTH) = YEAR(CURDATE() - INTERVAL 3 MONTH) - 1 THEN total_amount ELSE 0 END) as py_p,
      SUM(total_amount) as total
    FROM purchases''');

    // Expense aggregates
    final e_agg = await _db.query('''SELECT 
      SUM(CASE WHEN expense_date = CURDATE() THEN amount ELSE 0 END) as t_e,
      SUM(CASE WHEN expense_date = CURDATE() - INTERVAL 1 DAY THEN amount ELSE 0 END) as yt_e,
      SUM(CASE WHEN MONTH(expense_date) = MONTH(CURDATE()) AND YEAR(expense_date) = YEAR(CURDATE()) THEN amount ELSE 0 END) as m_e,
      SUM(CASE WHEN MONTH(expense_date) = MONTH(CURDATE() - INTERVAL 1 MONTH) AND YEAR(expense_date) = YEAR(CURDATE() - INTERVAL 1 MONTH) THEN amount ELSE 0 END) as pm_e,
      SUM(CASE WHEN YEAR(expense_date - INTERVAL 3 MONTH) = YEAR(CURDATE() - INTERVAL 3 MONTH) THEN amount ELSE 0 END) as y_e,
      SUM(CASE WHEN YEAR(expense_date - INTERVAL 3 MONTH) = YEAR(CURDATE() - INTERVAL 3 MONTH) - 1 THEN amount ELSE 0 END) as py_e,
      SUM(amount) as total
    FROM expenses''');

    final tsc = await _db.query(
      'SELECT COUNT(*) as c FROM sales WHERE DATE(sale_date)=CURDATE()',
    );
    final ysc = await _db.query(
      'SELECT COUNT(*) as c FROM sales WHERE DATE(sale_date)=CURDATE() - INTERVAL 1 DAY',
    );
    final ppc = await _db.query(
      "SELECT COUNT(*) as c FROM purchases WHERE payment_status != 'paid'",
    );
    final nct = await _db.query(
      'SELECT COUNT(*) as c FROM customers WHERE DATE(created_at)=CURDATE()',
    );
    final pmc = await _db.query(
      'SELECT COUNT(*) as c FROM customers WHERE created_at < DATE_SUB(CURDATE(), INTERVAL 1 MONTH)',
    );

    final topRes = await _db.query(
      "SELECT CONCAT(p.name,' ',pv.pack_size,u.symbol) as name, CAST(SUM(si.quantity - si.returned_quantity) AS UNSIGNED) as quantity_sold, SUM((si.amount / si.quantity) * (si.quantity - si.returned_quantity)) as revenue FROM sale_items si JOIN product_variants pv ON si.product_variant_id=pv.id JOIN products p ON pv.product_id=p.id JOIN units u ON pv.unit_id=u.id JOIN sales s ON si.sale_id=s.id WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) GROUP BY pv.id HAVING quantity_sold > 0 ORDER BY quantity_sold DESC LIMIT 5",
    );
    final mRes = await _db.query(
      "SELECT DATE_FORMAT(s.sale_date,'%Y-%m') as month, SUM(CASE WHEN p.tax_remittable = 1 THEN ((si.amount - si.tax) / si.quantity) ELSE (si.amount / si.quantity) END * (si.quantity - si.returned_quantity)) as amount FROM sale_items si JOIN sales s ON si.sale_id = s.id JOIN product_variants pv ON si.product_variant_id = pv.id JOIN products p ON pv.product_id = p.id WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) GROUP BY month ORDER BY month",
    );
    final dRes = await _db.query(
      "SELECT DATE(s.sale_date) as day, SUM(CASE WHEN p.tax_remittable = 1 THEN ((si.amount - si.tax) / si.quantity) ELSE (si.amount / si.quantity) END * (si.quantity - si.returned_quantity)) as amount FROM sale_items si JOIN sales s ON si.sale_id = s.id JOIN product_variants pv ON si.product_variant_id = pv.id JOIN products p ON pv.product_id = p.id WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) GROUP BY day ORDER BY day",
    );
    final catRes = await _db.query(
      "SELECT COALESCE(c.name, 'Others') as name, SUM(CASE WHEN p.tax_remittable = 1 THEN ((si.amount - si.tax) / si.quantity) ELSE (si.amount / si.quantity) END * (si.quantity - si.returned_quantity)) as revenue FROM sale_items si JOIN sales s ON si.sale_id = s.id JOIN product_variants pv ON si.product_variant_id = pv.id JOIN products p ON pv.product_id = p.id LEFT JOIN categories c ON p.category_id = c.id WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) GROUP BY c.id, c.name HAVING revenue > 0 ORDER BY revenue DESC LIMIT 6",
    );
    final invRes = await _db.query(
      'SELECT p.name as product_name, i.quantity, i.minimum_stock FROM inventory i JOIN product_variants pv ON i.product_variant_id = pv.id JOIN products p ON pv.product_id = p.id WHERE i.minimum_stock > 0 AND pv.is_active = 1 ORDER BY (i.quantity <= i.minimum_stock) DESC, i.quantity ASC LIMIT 8',
    );
    final rRes = await _db.query(
      'SELECT s.*, c.name as customer_name FROM sales s LEFT JOIN customers c ON s.customer_id=c.id ORDER BY s.created_at DESC LIMIT 10',
    );

    final s_row = s_agg.rows.isNotEmpty ? s_agg.rows.first.assoc() : {};
    final p_row = p_agg.rows.isNotEmpty ? p_agg.rows.first.assoc() : {};
    final e_row = e_agg.rows.isNotEmpty ? e_agg.rows.first.assoc() : {};

    double parseD(Map<dynamic, dynamic> m, String k) =>
        m[k] != null ? (double.tryParse(m[k].toString()) ?? 0.0) : 0.0;

    return DashboardData(
      totalProducts: int.parse(tp.rows.first.assoc()['c'] ?? '0'),
      totalVariants: int.parse(tv.rows.first.assoc()['c'] ?? '0'),
      lowStockCount: int.parse(ls.rows.first.assoc()['c'] ?? '0'),
      totalCustomers: int.parse(tc.rows.first.assoc()['c'] ?? '0'),
      totalSuppliers: int.parse(ts.rows.first.assoc()['c'] ?? '0'),

      todaySales: parseD(s_row, 't_s'),
      yesterdaySales: parseD(s_row, 'yt_s'),
      monthlySales: parseD(s_row, 'm_s'),
      prevMonthSales: parseD(s_row, 'pm_s'),
      yearlySales: parseD(s_row, 'y_s'),
      prevYearSales: parseD(s_row, 'py_s'),
      totalRevenue: parseD(s_row, 'total'),

      todayCogs: parseD(s_row, 't_cogs'),
      yesterdayCogs: parseD(s_row, 'yt_cogs'),
      monthlyCogs: parseD(s_row, 'm_cogs'),
      prevMonthCogs: parseD(s_row, 'pm_cogs'),
      yearlyCogs: parseD(s_row, 'y_cogs'),
      prevYearCogs: parseD(s_row, 'py_cogs'),
      totalCogs: parseD(s_row, 'total_cogs'),
      todayPurchases: parseD(p_row, 't_p'),
      yesterdayPurchases: parseD(p_row, 'yt_p'),
      monthlyPurchases: parseD(p_row, 'm_p'),
      prevMonthPurchases: parseD(p_row, 'pm_p'),
      yearlyPurchases: parseD(p_row, 'y_p'),
      prevYearPurchases: parseD(p_row, 'py_p'),
      totalPurchases: parseD(p_row, 'total'),

      todayExpenses: parseD(e_row, 't_e'),
      yesterdayExpenses: parseD(e_row, 'yt_e'),
      monthlyExpenses: parseD(e_row, 'm_e'),
      prevMonthExpenses: parseD(e_row, 'pm_e'),
      yearlyExpenses: parseD(e_row, 'y_e'),
      prevYearExpenses: parseD(e_row, 'py_e'),
      totalExpenses: parseD(e_row, 'total'),

      todaySaleCount: int.parse(tsc.rows.first.assoc()['c'] ?? '0'),
      yesterdaySaleCount: int.parse(ysc.rows.first.assoc()['c'] ?? '0'),
      pendingPurchasesCount: int.parse(ppc.rows.first.assoc()['c'] ?? '0'),
      newCustomersToday: int.parse(nct.rows.first.assoc()['c'] ?? '0'),
      prevMonthCustomerCount: int.parse(pmc.rows.first.assoc()['c'] ?? '0'),
      topVariants: topRes.rows
          .map((r) => TopVariant.fromMap(r.assoc()))
          .toList(),
      monthlySalesData: mRes.rows
          .map((r) => MonthlySale.fromMap(r.assoc()))
          .toList(),
      dailySalesData: dRes.rows
          .map((r) => DailySale.fromMap(r.assoc()))
          .toList(),
      categorySales: catRes.rows
          .map((r) => CategorySale.fromMap(r.assoc()))
          .toList(),
      inventoryOverview: invRes.rows
          .map((r) => InventoryOverviewItem.fromMap(r.assoc()))
          .toList(),
      recentSales: rRes.rows.map((r) => Sale.fromMap(r.assoc())).toList(),
    );
  }

  Future<void> processReturn(
    int saleId,
    Map<int, double> returnedQuantities, {
    String refundMethod = 'Ledger Adjustment',
  }) async {
    // Fetch sale info to account for overall discount
    final saleR = await _db.query(
      'SELECT total_amount, discount, returned_amount FROM sales WHERE id = :sid',
      {'sid': saleId},
    );
    if (saleR.rows.isEmpty) return;
    final saleData = saleR.rows.first.assoc();
    final saleTotal = double.parse(saleData['total_amount']!);
    final saleDiscount = double.parse(saleData['discount']!);
    final currentReturned = double.parse(saleData['returned_amount']!);

    final grossTotal = saleTotal + saleDiscount;
    final multiplier = grossTotal > 0 ? (saleTotal / grossTotal) : 1.0;

    // returnedQuantities maps sale_item.id to the quantity being returned
    double totalRefund = 0;

    for (final entry in returnedQuantities.entries) {
      final itemId = entry.key;
      final returnQty = entry.value;
      if (returnQty <= 0) continue;

      // Get item details
      final itemR = await _db.query('SELECT * FROM sale_items WHERE id = :id', {
        'id': itemId,
      });
      if (itemR.rows.isEmpty) continue;

      final item = itemR.rows.first.assoc();
      final qty = double.parse(item['quantity']!);
      final amount = double.parse(item['amount']!);
      final tintCharge = item['tinting_charge'] != null
          ? double.parse(item['tinting_charge']!)
          : 0;
      final discount = item['discount'] != null
          ? double.parse(item['discount']!)
          : 0;

      // Calculate original value of the item, then scale down by the overall bill discount
      final perUnitAmount = (amount + tintCharge - discount) / qty;
      final refundAmount = (perUnitAmount * multiplier) * returnQty;
      totalRefund += refundAmount;

      // Update sale item
      await _db.query(
        'UPDATE sale_items SET returned_quantity = returned_quantity + :rq WHERE id = :id',
        {'rq': returnQty, 'id': itemId},
      );

      // Log the return in timeline
      await _db.query(
        'INSERT INTO sale_returns_log (sale_id, sale_item_id, quantity, refund_amount) VALUES (:sid, :siid, :rq, :ramt)',
        {'sid': saleId, 'siid': itemId, 'rq': returnQty, 'ramt': refundAmount},
      );

      // Stock adjustment
      final variantId = int.parse(item['product_variant_id']!);
      await _db.query(
        'INSERT INTO stock_movements (product_variant_id, type, quantity, remarks) VALUES (:vid, "RETURN", :q, :rem)',
        {
          'vid': variantId,
          'q': returnQty,
          'rem': 'Sale Return for Invoice ID $saleId',
        },
      );
      await _db.query(
        'UPDATE inventory SET quantity = quantity + :q WHERE product_variant_id = :vid',
        {'q': returnQty, 'vid': variantId},
      );

      // Auto-reactivate the variant and its parent product if they were discontinued
      await _db.query(
        '''
        UPDATE products p
        JOIN product_variants pv ON p.id = pv.product_id
        SET p.is_active = 1, pv.is_active = 1
        WHERE pv.id = :vid
      ''',
        {'vid': variantId},
      );
    }

    if (totalRefund > 0) {
      double newReturned = currentReturned + totalRefund;
      // Safety cap: Never refund more than the total amount of the sale
      if (newReturned > saleTotal) {
        newReturned = saleTotal;
      }

      // Update sale
      await _db.query(
        'UPDATE sales SET returned_amount = :ra WHERE id = :sid',
        {'ra': newReturned, 'sid': saleId},
      );

      // Update status
      if (newReturned >= saleTotal) {
        await _db.query(
          'UPDATE sales SET payment_status = "refunded" WHERE id = :sid',
          {'sid': saleId},
        );
      } else {
        await _db.query(
          'UPDATE sales SET payment_status = "partial_refund" WHERE id = :sid',
          {'sid': saleId},
        );
      }

      if (refundMethod != 'Ledger Adjustment') {
        await _db.query(
          'INSERT INTO refunds (reference_id, type, amount, payment_method, refund_date) VALUES (:id, "customer_refund", :amt, :meth, CURDATE())',
          {'id': saleId, 'amt': totalRefund, 'meth': refundMethod},
        );
      }
    }
  }
}
