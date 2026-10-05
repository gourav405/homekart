import '../models/purchase.dart';
import 'database_service.dart';
import "audit_service.dart";
import 'inventory_service.dart';

class PurchaseService {
  final DatabaseService _db = DatabaseService();
  final InventoryService _inv = InventoryService();

  Future<List<Purchase>> getAll({String? search}) async {
    String sql =
        'SELECT pu.*, s.name as supplier_name FROM purchases pu JOIN suppliers s ON pu.supplier_id = s.id';
    Map<String, dynamic> params = {};
    if (search != null && search.isNotEmpty) {
      sql += ' WHERE pu.invoice_number LIKE :s OR s.name LIKE :s';
      params['s'] = '%$search%';
    }
    sql += ' ORDER BY pu.purchase_date DESC';
    final r = await _db.query(sql, params);
    return r.rows.map((row) => Purchase.fromMap(row.assoc())).toList();
  }

  Future<Purchase?> getById(int id) async {
    final r = await _db.query(
      'SELECT pu.*, s.name as supplier_name FROM purchases pu JOIN suppliers s ON pu.supplier_id = s.id WHERE pu.id=:id',
      {'id': id},
    );
    if (r.rows.isEmpty) return null;
    final items = await _db.query(
      'SELECT pi.*, pv.sku as variant_sku, p.name as product_name, u.symbol as unit_symbol, pv.pack_size FROM purchase_items pi JOIN product_variants pv ON pi.product_variant_id = pv.id JOIN products p ON pv.product_id = p.id JOIN units u ON pv.unit_id = u.id WHERE pi.purchase_id=:id',
      {'id': id},
    );
    return Purchase.fromMap(
      r.rows.first.assoc(),
      items: items.rows
          .map((row) => PurchaseItem.fromMap(row.assoc()))
          .toList(),
    );
  }

  Future<int> createPurchase(Purchase purchase) async {
    final conn = await _db.connection;
    await conn.execute('START TRANSACTION');
    try {
      final r = await conn.execute(
        'INSERT INTO purchases (invoice_number, supplier_id, purchase_date, total_amount, notes, payment_status, amount_paid, payment_method) VALUES (:inv, :sid, :date, :total, :notes, :pstat, :apaid, :pmeth)',
        {
          'inv': purchase.invoiceNumber,
          'sid': purchase.supplierId,
          'date': purchase.purchaseDate.toIso8601String().substring(0, 10),
          'total': purchase.totalAmount,
          'notes': purchase.notes ?? '',
          'pstat': purchase.paymentStatus,
          'apaid': purchase.amountPaid,
          'pmeth': purchase.paymentMethod,
        },
      );
      int purchaseId = r.lastInsertID.toInt();
      if (purchase.items != null) {
        for (var item in purchase.items!) {
          await conn.execute(
            'INSERT INTO purchase_items (purchase_id, product_variant_id, quantity, purchase_price, amount) VALUES (:pid, :vid, :qty, :pp, :amt)',
            {
              'pid': purchaseId,
              'vid': item.productVariantId,
              'qty': item.quantity,
              'pp': item.purchasePrice,
              'amt': item.amount,
            },
          );

          // Do NOT automatically update master purchase price (strict batch tracking)

          await _inv.addStockMovement(
            item.productVariantId,
            'PURCHASE',
            item.quantity,
            referenceId: purchaseId,
            remarks: 'Purchase ${purchase.invoiceNumber}',
          );
        }
      }
      await AuditService().log(
        action: 'CREATE',
        entityType: 'purchase',
        entityId: purchaseId,
        description: 'Purchase created: INV# ${purchase.invoiceNumber}, Total: ₹${purchase.totalAmount}',
      );
      await conn.execute('COMMIT');
      return purchaseId;
    } catch (e) {
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> processReturn(
    int purchaseId,
    int purchaseItemId,
    double qtyToReturn,
    double returnAmount, {
    String refundMethod = 'Ledger Adjustment',
  }) async {
    final conn = await _db.connection;
    await conn.execute('START TRANSACTION');
    try {
      final itemsRes = await conn.execute(
        'SELECT product_variant_id FROM purchase_items WHERE id=:id',
        {'id': purchaseItemId},
      );
      if (itemsRes.rows.isEmpty) throw Exception('Item not found');
      final vid = int.parse(itemsRes.rows.first.assoc()['product_variant_id']!);

      await conn.execute(
        'UPDATE purchase_items SET returned_quantity = returned_quantity + :qty WHERE id=:id',
        {'qty': qtyToReturn, 'id': purchaseItemId},
      );
      await conn.execute(
        'UPDATE purchases SET returned_amount = returned_amount + :amt WHERE id=:id',
        {'amt': returnAmount, 'id': purchaseId},
      );

      final pRes = await conn.execute(
        'SELECT total_amount, returned_amount, amount_paid FROM purchases WHERE id=:id',
        {'id': purchaseId},
      );
      if (pRes.rows.isNotEmpty) {
        final p = pRes.rows.first.assoc();
        double trueTotal =
            double.parse(p['total_amount']!) -
            double.parse(p['returned_amount']!);
        double paid = double.parse(p['amount_paid']!);
        if (paid >= trueTotal) {
          await conn.execute(
            'UPDATE purchases SET payment_status = "paid" WHERE id=:id',
            {'id': purchaseId},
          );
        }
      }

      if (refundMethod != 'Ledger Adjustment') {
        await conn.execute(
          'INSERT INTO refunds (reference_id, type, amount, payment_method, refund_date) VALUES (:id, "supplier_refund", :amt, :meth, CURDATE())',
          {'id': purchaseId, 'amt': returnAmount, 'meth': refundMethod},
        );
      }

      await _inv.addStockMovement(
        vid,
        'PURCHASE_RETURN',
        qtyToReturn,
        referenceId: purchaseId,
        remarks: 'Return to Supplier',
      );

      await conn.execute('COMMIT');
    } catch (e) {
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> deletePurchase(int id) async {
    final conn = await _db.connection;
    await conn.execute('START TRANSACTION');
    try {
      final items = await conn.execute(
        'SELECT product_variant_id, quantity FROM purchase_items WHERE purchase_id=:id',
        {'id': id},
      );
      for (var row in items.rows) {
        final m = row.assoc();
        int vid = int.parse(m['product_variant_id']!);
        double qty = double.parse(m['quantity']!);
        await conn.execute(
          'UPDATE inventory SET quantity = quantity - :qty WHERE product_variant_id = :vid',
          {'qty': qty, 'vid': vid},
        );
        await conn.execute(
          'INSERT INTO stock_movements (product_variant_id, type, quantity, remarks) VALUES (:vid, :t, :qty, :rem)',
          {
            'vid': vid,
            't': 'ADJUSTMENT',
            'qty': -qty,
            'rem': 'Purchase deleted',
          },
        );
      }
      await conn.execute('DELETE FROM purchase_items WHERE purchase_id=:id', {
        'id': id,
      });
      await conn.execute('DELETE FROM purchases WHERE id=:id', {'id': id});
      await conn.execute('COMMIT');
    } catch (e) {
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }
}
