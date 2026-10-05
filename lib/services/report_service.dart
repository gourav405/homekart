import 'database_service.dart';

class MarginReportRow {
  final String label;
  final double netRevenue;
  final double totalCost;
  final double grossProfit;

  MarginReportRow(
    this.label,
    this.netRevenue,
    this.totalCost,
    this.grossProfit,
  );
  double get marginPercent =>
      netRevenue > 0 ? (grossProfit / netRevenue) * 100 : 0.0;
}

class MarginReport {
  final double netRevenue;
  final double totalCost;
  final double grossProfit;
  final List<MarginReportRow> rows;

  MarginReport(this.netRevenue, this.totalCost, this.grossProfit, this.rows);
  double get marginPercent =>
      netRevenue > 0 ? (grossProfit / netRevenue) * 100 : 0.0;
}

class ReportService {
  Future<Map<String, dynamic>> getDayBook(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final conn = await _db.connection;

    // Inflows
    final salesRes = await conn.execute(
      "SELECT payment_method, SUM(amount_paid) as total FROM sales WHERE DATE(sale_date) = :date AND status != 'cancelled' GROUP BY payment_method",
      {'date': dateStr},
    );
    final custPaymentsRes = await conn.execute(
      "SELECT payment_method, SUM(amount) as total FROM customer_payments WHERE DATE(payment_date) = :date GROUP BY payment_method",
      {'date': dateStr},
    );
    final supplierRefundsRes = await conn.execute(
      "SELECT payment_method, SUM(amount) as total FROM refunds WHERE refund_date = :date AND type = 'supplier_refund' GROUP BY payment_method",
      {'date': dateStr},
    );

    // Outflows
    final purchasesRes = await conn.execute(
      "SELECT payment_method, SUM(amount_paid) as total FROM purchases WHERE DATE(purchase_date) = :date GROUP BY payment_method",
      {'date': dateStr},
    );
    final suppPaymentsRes = await conn.execute(
      "SELECT payment_method, SUM(amount) as total FROM supplier_payments WHERE DATE(payment_date) = :date GROUP BY payment_method",
      {'date': dateStr},
    );
    final expensesRes = await conn.execute(
      "SELECT payment_method, SUM(amount) as total FROM expenses WHERE DATE(expense_date) = :date GROUP BY payment_method",
      {'date': dateStr},
    );
    final customerRefundsRes = await conn.execute(
      "SELECT payment_method, SUM(amount) as total FROM refunds WHERE refund_date = :date AND type = 'customer_refund' GROUP BY payment_method",
      {'date': dateStr},
    );

    Map<String, double> inflows = {
      'Cash': 0,
      'UPI': 0,
      'Card': 0,
      'Bank Transfer': 0,
    };
    Map<String, double> outflows = {
      'Cash': 0,
      'UPI': 0,
      'Card': 0,
      'Bank Transfer': 0,
    };

    void add(Map<String, double> map, var res) {
      for (var row in res.rows) {
        final m = row.assoc();
        final method = m['payment_method'] ?? 'Cash';
        final val = double.parse(m['total'] ?? '0');
        map[method] = (map[method] ?? 0) + val;
      }
    }

    add(inflows, salesRes);
    add(inflows, custPaymentsRes);
    add(inflows, supplierRefundsRes);

    add(outflows, purchasesRes);
    add(outflows, suppPaymentsRes);
    add(outflows, expensesRes);
    add(outflows, customerRefundsRes);

    return {'inflows': inflows, 'outflows': outflows};
  }

  final DatabaseService _db = DatabaseService();

  Future<MarginReport> getMarginReport({
    DateTime? startDate,
    DateTime? endDate,
    String? invoiceNumber,
    String groupByMode = 'date',
  }) async {
    String filterClause = "s.status = 'completed'";
    String groupBy = '';
    String selectLabel = '';
    Map<String, dynamic> params = {};

    if (invoiceNumber != null && invoiceNumber.trim().isNotEmpty) {
      filterClause += " AND s.invoice_number = :inv";
      params['inv'] = invoiceNumber.trim();
      groupBy = "pv.id";
      selectLabel = "CONCAT(p.name, ' - ', pv.pack_size, u.symbol)";
    } else {
      if (startDate != null && endDate != null) {
        filterClause +=
            " AND DATE(s.sale_date) >= :start AND DATE(s.sale_date) <= :end";
        params['start'] =
            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
        params['end'] =
            "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

        final days = endDate.difference(startDate).inDays;
        if (groupByMode == 'product') {
          groupBy = "pv.id";
          selectLabel = "CONCAT(p.name, ' - ', pv.pack_size, u.symbol)";
        } else if (groupByMode == 'invoice') {
          groupBy = "s.id";
          selectLabel =
              "CONCAT(s.invoice_number, ' - ', COALESCE(c.name, 'Unknown'))";
        } else if (days <= 60) {
          groupBy = 'DATE(s.sale_date)';
          selectLabel = 'DATE_FORMAT(MIN(s.sale_date), "%d %b %Y")';
        } else {
          groupBy = 'DATE_FORMAT(s.sale_date, "%Y-%m")';
          selectLabel = 'DATE_FORMAT(MIN(s.sale_date), "%b %Y")';
        }
      } else {
        filterClause +=
            " AND MONTH(s.sale_date) = MONTH(CURDATE()) AND YEAR(s.sale_date) = YEAR(CURDATE())";
        if (groupByMode == 'product') {
          groupBy = "pv.id";
          selectLabel = "CONCAT(p.name, ' - ', pv.pack_size, u.symbol)";
        } else if (groupByMode == 'invoice') {
          groupBy = "s.id";
          selectLabel =
              "CONCAT(s.invoice_number, ' - ', COALESCE(c.name, 'Unknown'))";
        } else {
          groupBy = 'DATE(s.sale_date)';
          selectLabel = 'DATE_FORMAT(MIN(s.sale_date), "%d %b %Y")';
        }
      }
    }

    final query =
        '''
      SELECT 
        $selectLabel as label,
        SUM(
          CASE WHEN p.tax_remittable = 1
            THEN ((si.amount - si.tax) / si.quantity) * (si.quantity - si.returned_quantity)
            ELSE (si.amount / si.quantity) * (si.quantity - si.returned_quantity)
          END
        ) as net_revenue,
        SUM(si.cost_price * (si.quantity - si.returned_quantity)) as total_cost,
        SUM(
          CASE WHEN p.tax_remittable = 1
            THEN ((si.amount - si.tax) / si.quantity) * (si.quantity - si.returned_quantity)
            ELSE (si.amount / si.quantity) * (si.quantity - si.returned_quantity)
          END
        ) - SUM(si.cost_price * (si.quantity - si.returned_quantity)) as gross_profit
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN product_variants pv ON si.product_variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      JOIN units u ON pv.unit_id = u.id
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE $filterClause
      GROUP BY $groupBy
      ORDER BY MIN(s.sale_date) DESC
    ''';

    final res = await _db.query(query, params);

    double totalNetRev = 0;
    double totalCost = 0;
    double totalProfit = 0;
    List<MarginReportRow> rows = [];

    for (var row in res.rows) {
      final map = row.assoc();
      final nr = double.tryParse(map['net_revenue'] ?? '0') ?? 0.0;
      final tc = double.tryParse(map['total_cost'] ?? '0') ?? 0.0;
      final gp = double.tryParse(map['gross_profit'] ?? '0') ?? 0.0;

      totalNetRev += nr;
      totalCost += tc;
      totalProfit += gp;

      rows.add(MarginReportRow(map['label'] ?? '', nr, tc, gp));
    }

    return MarginReport(totalNetRev, totalCost, totalProfit, rows);
  }

  Future<Map<String, List<List<dynamic>>>> getGstReportData(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    String saleFilter = "s.status = 'completed'";
    String purFilter = "1=1"; // pu doesn't have status, wait, let's check
    Map<String, dynamic> params = {};

    if (startDate != null && endDate != null) {
      saleFilter +=
          " AND DATE(s.sale_date) >= :start AND DATE(s.sale_date) <= :end";
      purFilter +=
          " AND DATE(p.purchase_date) >= :start AND DATE(p.purchase_date) <= :end";
      params['start'] =
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      params['end'] =
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
    }

    final salesQuery =
        '''
      SELECT 
        DATE_FORMAT(s.sale_date, "%Y-%m-%d") as date,
        s.invoice_number as invoice_number,
        c.name as customer_name,
        c.gst_number as gstin,
        s.subtotal as taxable_value,
        s.tax as tax_amount,
        s.total_amount as total_amount,
        s.is_igst as is_igst
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE $saleFilter
      ORDER BY s.sale_date ASC
    ''';

    final purchaseQuery =
        '''
      SELECT 
        DATE_FORMAT(p.purchase_date, "%Y-%m-%d") as date,
        p.invoice_number as invoice_number,
        su.name as supplier_name,
        su.gst_number as gstin,
        p.total_amount as taxable_value,
        0 as tax_amount,
        p.total_amount as total_amount
      FROM purchases p
      LEFT JOIN suppliers su ON p.supplier_id = su.id
      WHERE $purFilter
      ORDER BY p.purchase_date ASC
    ''';

    final saleRes = await _db.query(salesQuery, params);
    final purchaseRes = await _db.query(purchaseQuery, params);

    List<List<dynamic>> salesCsv = [
      [
        'Date',
        'Invoice Number',
        'Customer Name',
        'GSTIN',
        'B2B/B2C',
        'Taxable Value',
        'Tax Amount',
        'Total Amount',
        'IGST Flag',
      ],
    ];

    for (var r in saleRes.rows) {
      final row = r.assoc();
      final gstin = row['gstin'] ?? '';
      final b2b = gstin.trim().isEmpty ? 'B2C' : 'B2B';
      salesCsv.add([
        row['date'],
        row['invoice_number'],
        row['customer_name'] ?? 'Walk-in',
        gstin,
        b2b,
        row['taxable_value'],
        row['tax_amount'],
        row['total_amount'],
        row['is_igst'] == '1' ? '1' : '0',
      ]);
    }

    List<List<dynamic>> purchasesCsv = [
      [
        'Date',
        'Invoice Number',
        'Supplier Name',
        'Supplier GSTIN',
        'Taxable Value',
        'Tax Amount',
        'Total Amount',
      ],
    ];

    for (var r in purchaseRes.rows) {
      final row = r.assoc();
      purchasesCsv.add([
        row['date'],
        row['invoice_number'],
        row['supplier_name'] ?? '',
        row['gstin'] ?? '',
        row['taxable_value'],
        row['tax_amount'],
        row['total_amount'],
      ]);
    }

    return {'sales': salesCsv, 'purchases': purchasesCsv};
  }
}
