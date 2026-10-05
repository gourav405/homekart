import '../models/inventory.dart';
import 'database_service.dart';

class InventoryService {
  final DatabaseService _db = DatabaseService();

  Future<void> updateStock(int variantId, double quantity, double minStock, double maxStock) async {
    await _db.query('UPDATE inventory SET quantity=:q, minimum_stock=:min, maximum_stock=:max WHERE product_variant_id=:vid', {'vid': variantId, 'q': quantity, 'min': minStock, 'max': maxStock});
  }

  Future<void> updateStockLevels(int variantId, double minStock, double maxStock) async {
    await _db.query('UPDATE inventory SET minimum_stock=:min, maximum_stock=:max WHERE product_variant_id=:vid', {'vid': variantId, 'min': minStock, 'max': maxStock});
  }

  Future<void> addStockMovement(int variantId, String type, double quantity, {int? referenceId, String? remarks}) async {
    await _db.query('INSERT INTO stock_movements (product_variant_id, type, quantity, reference_id, remarks) VALUES (:vid, :type, :qty, :ref, :rem)', {'vid': variantId, 'type': type, 'qty': quantity, 'ref': referenceId, 'rem': remarks ?? ''});
    // Update inventory quantity
    if (type == 'PURCHASE' || type == 'RETURN') {
      await _db.query('UPDATE inventory SET quantity = quantity + :qty WHERE product_variant_id = :vid', {'vid': variantId, 'qty': quantity});
    } else if (type == 'SALE' || type == 'DAMAGE' || type == 'PURCHASE_RETURN') {
      await _db.query('UPDATE inventory SET quantity = quantity - :qty WHERE product_variant_id = :vid', {'vid': variantId, 'qty': quantity});
      
      if (type == 'DAMAGE') {
        final res = await _db.query('''
          SELECT pv.purchase_price, pv.sku, p.name 
          FROM product_variants pv 
          JOIN products p ON pv.product_id = p.id 
          WHERE pv.id = :vid
        ''', {'vid': variantId});
        
        if (res.rows.isNotEmpty) {
          final row = res.rows.first.assoc();
          final cost = double.parse(row['purchase_price']!) * quantity;
          final notes = 'Loss: ${row['name']} (${row['sku']}) | Qty: $quantity | Remarks: ${remarks ?? ''}';
          
          await _db.query(
            'INSERT INTO expenses (expense_date, category, amount, payment_method, notes) VALUES (CURDATE(), :cat, :amt, :pm, :notes)',
            {'cat': 'Damaged Stock', 'amt': cost, 'pm': 'Write-off', 'notes': notes}
          );
        }
      }
    } else if (type == 'ADJUSTMENT') {
      await _db.query('UPDATE inventory SET quantity = :qty WHERE product_variant_id = :vid', {'vid': variantId, 'qty': quantity});
    }
  }

  Future<(List<StockMovement>, int)> getMovements({int? variantId, int? brandId, String? search, String? type, int limit = 20, int offset = 0}) async {
    String countSql = 'SELECT COUNT(*) as total FROM stock_movements sm JOIN product_variants pv ON sm.product_variant_id = pv.id JOIN products p ON pv.product_id = p.id WHERE 1=1';
    String sql = 'SELECT sm.*, pv.sku as variant_sku, p.name as product_name FROM stock_movements sm JOIN product_variants pv ON sm.product_variant_id = pv.id JOIN products p ON pv.product_id = p.id WHERE 1=1';
    String whereClause = '';
    Map<String, dynamic> params = {};
    if (variantId != null) { whereClause += ' AND sm.product_variant_id = :vid'; params['vid'] = variantId; }
    if (brandId != null) { whereClause += ' AND p.brand_id = :bid'; params['bid'] = brandId; }
    if (search != null && search.isNotEmpty) { whereClause += ' AND (p.name LIKE :s OR pv.sku LIKE :s OR pv.variant_name LIKE :s)'; params['s'] = '%$search%'; }
    if (type != null) { whereClause += ' AND sm.type = :type'; params['type'] = type; }
    
    final countR = await _db.query(countSql + whereClause, params);
    final total = int.parse(countR.rows.first.assoc()['total']!);

    sql += whereClause + ' ORDER BY sm.created_at DESC LIMIT :limit OFFSET :offset';
    params['limit'] = limit;
    params['offset'] = offset;
    
    final r = await _db.query(sql, params);
    final movements = r.rows.map((row) => StockMovement.fromMap(row.assoc())).toList();
    return (movements, total);
  }

  Future<List<Inventory>> getLowStock() async {
    final r = await _db.query('SELECT inv.*, pv.sku as variant_sku, p.name as product_name FROM inventory inv JOIN product_variants pv ON inv.product_variant_id = pv.id JOIN products p ON pv.product_id = p.id WHERE inv.minimum_stock > 0 AND inv.quantity <= inv.minimum_stock AND pv.is_active = 1 ORDER BY inv.quantity ASC');
    return r.rows.map((row) => Inventory.fromMap(row.assoc())).toList();
  }
}
