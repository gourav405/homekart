import '../models/product.dart';
import '../models/product_variant.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/masters.dart';
import 'database_service.dart';

class ProductService {
  final DatabaseService _db = DatabaseService();

  // ── Products ──
  Future<(List<Product>, int)> getAllProducts({String? search, int? brandId, int? categoryId, int limit = 20, int offset = 0}) async {
    String countSql = 'SELECT COUNT(*) as total FROM products p WHERE 1=1';
    String sql = 'SELECT p.*, p.hsn_code as hsn_code, b.name as brand_name, c.name as category_name, sc.name as subcategory_name, pt.name as type_name, (SELECT COUNT(*) FROM product_variants pv WHERE pv.product_id = p.id) as variant_count FROM products p LEFT JOIN brands b ON p.brand_id = b.id LEFT JOIN categories c ON p.category_id = c.id LEFT JOIN subcategories sc ON p.subcategory_id = sc.id LEFT JOIN product_types pt ON p.type_id = pt.id WHERE 1=1';
    String whereClause = '';
    Map<String, dynamic> params = {};
    if (search != null && search.isNotEmpty) { whereClause += ' AND (p.name LIKE :s OR p.sku LIKE :s OR EXISTS (SELECT 1 FROM product_variants pv WHERE pv.product_id = p.id AND (pv.sku LIKE :s OR pv.variant_name LIKE :s)))'; params['s'] = '%$search%'; }
    if (brandId != null) { whereClause += ' AND p.brand_id = :bid'; params['bid'] = brandId; }
    if (categoryId != null) { whereClause += ' AND p.category_id = :cid'; params['cid'] = categoryId; }
    
    final countR = await _db.query(countSql + whereClause, params);
    final total = int.parse(countR.rows.first.assoc()['total']!);

    sql += whereClause + ' ORDER BY p.name LIMIT :limit OFFSET :offset';
    params['limit'] = limit;
    params['offset'] = offset;
    
    final r = await _db.query(sql, params);
    final products = r.rows.map((row) => Product.fromMap(row.assoc())).toList();
    return (products, total);
  }

  Future<int> createProduct(Product p) async {
    final r = await _db.query('INSERT INTO products (name, sku, description, brand_id, category_id, subcategory_id, type_id, is_tintable, is_tax_inclusive, tax_remittable, hsn_code, is_active) VALUES (:name, :sku, :desc, :bid, :cid, :sid, :tid, :tint, :tax, :taxr, :hsn, :act)', {'name': p.name, 'sku': p.sku, 'desc': p.description ?? '', 'bid': p.brandId, 'cid': p.categoryId, 'sid': p.subcategoryId, 'tid': p.typeId, 'tint': p.isTintable ? 1 : 0, 'tax': p.isTaxInclusive ? 1 : 0, 'taxr': p.taxRemittable ? 1 : 0, 'hsn': p.hsnCode, 'act': p.isActive ? 1 : 0});
    return r.lastInsertID.toInt();
  }

  Future<void> updateProduct(Product p) async {
    await _db.query('UPDATE products SET name=:name, sku=:sku, description=:desc, brand_id=:bid, category_id=:cid, subcategory_id=:sid, type_id=:tid, is_tintable=:tint, is_tax_inclusive=:tax, tax_remittable=:taxr, hsn_code=:hsn, is_active=:act, updated_at=NOW() WHERE id=:id', {'id': p.id, 'name': p.name, 'sku': p.sku, 'desc': p.description ?? '', 'bid': p.brandId, 'cid': p.categoryId, 'sid': p.subcategoryId, 'tid': p.typeId, 'tint': p.isTintable ? 1 : 0, 'tax': p.isTaxInclusive ? 1 : 0, 'taxr': p.taxRemittable ? 1 : 0, 'hsn': p.hsnCode, 'act': p.isActive ? 1 : 0});
  }
  
  Future<double> getProductTotalStock(int productId) async {
    final r = await _db.query('SELECT SUM(quantity) as t FROM inventory JOIN product_variants ON inventory.product_variant_id = product_variants.id WHERE product_variants.product_id = :pid', {'pid': productId});
    if (r.rows.isEmpty || r.rows.first.assoc()['t'] == null) return 0.0;
    return double.tryParse(r.rows.first.assoc()['t']!) ?? 0.0;
  }

  Future<void> deleteProduct(int id) async { await _db.query('DELETE FROM products WHERE id=:id', {'id': id}); }

  // ── Variants ──
  Future<(List<ProductVariant>, int)> getVariants({int? productId, int? brandId, int? categoryId, String? search, bool? isActive, int limit = 20, int offset = 0}) async {
    String countSql = 'SELECT COUNT(DISTINCT pv.sku) as total FROM product_variants pv JOIN products p ON pv.product_id = p.id WHERE 1=1';
    String whereClause = '';
    Map<String, dynamic> params = {};
    if (productId != null) { whereClause += ' AND pv.product_id = :pid'; params['pid'] = productId; }
    if (brandId != null) { whereClause += ' AND p.brand_id = :bid'; params['bid'] = brandId; }
    if (categoryId != null) { whereClause += ' AND p.category_id = :cid'; params['cid'] = categoryId; }
    if (isActive != null) { whereClause += ' AND pv.is_active = :act AND p.is_active = :act'; params['act'] = isActive ? 1 : 0; }
    if (search != null && search.isNotEmpty) { whereClause += ' AND (pv.sku LIKE :s OR p.name LIKE :s OR pv.variant_name LIKE :s)'; params['s'] = '%$search%'; }
    
    final countR = await _db.query(countSql + whereClause, params);
    final total = int.parse(countR.rows.first.assoc()['total']!);

    // First get the paginated unique SKUs
    String skuSql = 'SELECT pv.sku FROM product_variants pv JOIN products p ON pv.product_id = p.id WHERE 1=1' + whereClause + ' GROUP BY pv.sku, p.name, pv.pack_size ORDER BY p.name, pv.pack_size LIMIT :limit OFFSET :offset';
    params['limit'] = limit;
    params['offset'] = offset;
    final skuR = await _db.query(skuSql, params);
    
    if (skuR.rows.isEmpty) return (<ProductVariant>[], total);
    
    List<String> skus = skuR.rows.map((row) => row.assoc()['sku']!).toList();
    
    // Now fetch all batches (variants) for these SKUs
    String inClause = skus.map((s) => "'$s'").join(',');
    String sql = 'SELECT pv.*, p.name as product_name, p.brand_id as brand_id, p.is_tintable as is_tintable, p.is_tax_inclusive as is_tax_inclusive, b.name as brand_name, u.symbol as unit_symbol, pu.symbol as purchase_unit_symbol, co.name as color_name, co.hex_code as color_hex, tr.name as tax_name, tr.percentage as tax_percentage, COALESCE(inv.quantity, 0) as stock_qty, COALESCE(inv.minimum_stock, 0) as min_stock, COALESCE(inv.maximum_stock, 0) as max_stock FROM product_variants pv JOIN products p ON pv.product_id = p.id LEFT JOIN brands b ON p.brand_id = b.id JOIN units u ON pv.unit_id = u.id LEFT JOIN units pu ON pv.purchase_unit_id = pu.id LEFT JOIN colors co ON pv.color_id = co.id LEFT JOIN tax_rates tr ON pv.tax_rate_id = tr.id LEFT JOIN inventory inv ON inv.product_variant_id = pv.id WHERE pv.sku IN ($inClause) ORDER BY p.name, pv.pack_size';
    
    final r = await _db.query(sql, {});
    final variants = r.rows.map((row) => ProductVariant.fromMap(row.assoc())).toList();
    return (variants, total);
  }

  Future<int> createVariant(ProductVariant v) async {
    final r = await _db.query('INSERT INTO product_variants (product_id, unit_id, pack_size, sku, variant_name, barcode, purchase_price, selling_price, mrp, color_id, tax_rate_id, purchase_unit_id, conversion_factor, is_active) VALUES (:pid, :uid, :ps, :sku, :vname, :bar, :pp, :sp, :mrp, :cid, :tid, :puid, :cf, :act)', {'pid': v.productId, 'uid': v.unitId, 'ps': v.packSize, 'sku': v.sku, 'vname': v.variantName, 'bar': v.barcode, 'pp': v.purchasePrice, 'sp': v.sellingPrice, 'mrp': v.mrp, 'cid': v.colorId, 'tid': v.taxRateId, 'puid': v.purchaseUnitId, 'cf': v.conversionFactor, 'act': v.isActive ? 1 : 0});
    int variantId = r.lastInsertID.toInt();
    await _db.query('INSERT INTO inventory (product_variant_id, quantity, minimum_stock, maximum_stock) VALUES (:vid, 0, :min, :max)', {'vid': variantId, 'min': v.minStock ?? 0, 'max': v.maxStock ?? 0});
    return variantId;
  }

  Future<void> updateVariant(ProductVariant v) async {
    await _db.query('UPDATE product_variants SET unit_id=:uid, pack_size=:ps, sku=:sku, variant_name=:vname, barcode=:bar, purchase_price=:pp, selling_price=:sp, mrp=:mrp, color_id=:cid, tax_rate_id=:tid, purchase_unit_id=:puid, conversion_factor=:cf, is_active=:act, updated_at=NOW() WHERE id=:id', {'id': v.id, 'uid': v.unitId, 'ps': v.packSize, 'sku': v.sku, 'vname': v.variantName, 'bar': v.barcode, 'pp': v.purchasePrice, 'sp': v.sellingPrice, 'mrp': v.mrp, 'cid': v.colorId, 'tid': v.taxRateId, 'puid': v.purchaseUnitId, 'cf': v.conversionFactor, 'act': v.isActive ? 1 : 0});
    await _db.query('UPDATE inventory SET minimum_stock=:min, maximum_stock=:max WHERE product_variant_id=:id', {'id': v.id, 'min': v.minStock ?? 0, 'max': v.maxStock ?? 0});
  }

  Future<void> updateStockLimits(int variantId, double min, double max) async {
    await _db.query('UPDATE inventory SET minimum_stock=:min, maximum_stock=:max WHERE product_variant_id=:id', {'id': variantId, 'min': min, 'max': max});
  }

  Future<void> updateStockLimitsBySku(String sku, double min, double max) async {
    await _db.query(
      'UPDATE inventory inv JOIN product_variants pv ON inv.product_variant_id = pv.id '
      'SET minimum_stock=:min, maximum_stock=:max '
      'WHERE pv.sku=:sku', 
      {'sku': sku, 'min': min, 'max': max}
    );
  }

  Future<void> toggleVariantSkuStatus(String sku, bool isActive) async {
    await _db.query(
      'UPDATE product_variants SET is_active = :act, updated_at = NOW() WHERE sku = :sku',
      {'sku': sku, 'act': isActive ? 1 : 0}
    );
  }

  Future<void> deleteVariant(int id) async {
    await _db.query('DELETE FROM inventory WHERE product_variant_id=:id', {'id': id});
    await _db.query('DELETE FROM product_variants WHERE id=:id', {'id': id});
  }

  // ── Master data ──
  Future<List<Brand>> getBrands() async { final r = await _db.query('SELECT * FROM brands WHERE is_active=1 ORDER BY name'); return r.rows.map((row) => Brand.fromMap(row.assoc())).toList(); }
  Future<int> createBrand(String name, String? desc) async { final r = await _db.query('INSERT INTO brands (name, description) VALUES (:n, :d)', {'n': name, 'd': desc ?? ''}); return r.lastInsertID.toInt(); }

  Future<List<Category>> getCategories() async { final r = await _db.query('SELECT * FROM categories WHERE is_active=1 ORDER BY name'); return r.rows.map((row) => Category.fromMap(row.assoc())).toList(); }
  Future<int> createCategory(String name, String? desc) async { final r = await _db.query('INSERT INTO categories (name, description) VALUES (:n, :d)', {'n': name, 'd': desc ?? ''}); return r.lastInsertID.toInt(); }

  Future<List<Subcategory>> getSubcategories({int? categoryId}) async {
    String sql = 'SELECT s.*, c.name as category_name FROM subcategories s JOIN categories c ON s.category_id = c.id WHERE s.is_active=1';
    Map<String, dynamic> params = {};
    if (categoryId != null) { sql += ' AND s.category_id = :cid'; params['cid'] = categoryId; }
    sql += ' ORDER BY s.name';
    final r = await _db.query(sql, params);
    return r.rows.map((row) => Subcategory.fromMap(row.assoc())).toList();
  }
  Future<int> createSubcategory(String name, int categoryId) async { final r = await _db.query('INSERT INTO subcategories (name, category_id) VALUES (:n, :cid)', {'n': name, 'cid': categoryId}); return r.lastInsertID.toInt(); }

  Future<List<ProductType>> getProductTypes({int? subcategoryId}) async { 
    String sql = 'SELECT * FROM product_types WHERE is_active=1';
    Map<String, dynamic> params = {};
    if (subcategoryId != null) { sql += ' AND (subcategory_id = :sid OR subcategory_id IS NULL)'; params['sid'] = subcategoryId; }
    sql += ' ORDER BY name';
    final r = await _db.query(sql, params); 
    return r.rows.map((row) => ProductType.fromMap(row.assoc())).toList(); 
  }
  Future<int> createProductType(String name, {int? subcategoryId}) async { final r = await _db.query('INSERT INTO product_types (name, subcategory_id) VALUES (:n, :sid)', {'n': name, 'sid': subcategoryId}); return r.lastInsertID.toInt(); }

  Future<List<Unit>> getUnits() async { final r = await _db.query('SELECT * FROM units ORDER BY name'); return r.rows.map((row) => Unit.fromMap(row.assoc())).toList(); }
  Future<int> createUnit(String name, String symbol) async { final r = await _db.query('INSERT INTO units (name, symbol) VALUES (:n, :s)', {'n': name, 's': symbol}); return r.lastInsertID.toInt(); }

  Future<List<PaintColor>> getColors() async { final r = await _db.query('SELECT * FROM colors WHERE is_active=1 ORDER BY name'); return r.rows.map((row) => PaintColor.fromMap(row.assoc())).toList(); }
  Future<int> createColor(String name, String? code, String? hex) async { final r = await _db.query('INSERT INTO colors (name, code, hex_code) VALUES (:n, :c, :h)', {'n': name, 'c': code ?? '', 'h': hex}); return r.lastInsertID.toInt(); }

  Future<List<TaxRate>> getTaxRates() async { final r = await _db.query('SELECT * FROM tax_rates WHERE is_active=1 ORDER BY percentage'); return r.rows.map((row) => TaxRate.fromMap(row.assoc())).toList(); }
  Future<int> createTaxRate(String name, double pct) async { final r = await _db.query('INSERT INTO tax_rates (name, percentage) VALUES (:n, :p)', {'n': name, 'p': pct}); return r.lastInsertID.toInt(); }

  // ── Shade Prices ──
  Future<Map<String, dynamic>?> getShadePrice(int brandId, String shadeCode, double packSize) async {
    final r = await _db.query('SELECT * FROM shade_prices WHERE brand_id = :bid AND shade_code = :code AND pack_size = :sz', {'bid': brandId, 'code': shadeCode, 'sz': packSize});
    if (r.rows.isEmpty) return null;
    return r.rows.first.assoc();
  }

  Future<void> saveShadePrice(int brandId, String shadeCode, String shadeName, double packSize, double price) async {
    await _db.query('''
      INSERT INTO shade_prices (brand_id, shade_code, shade_name, pack_size, price) 
      VALUES (:bid, :code, :name, :sz, :p)
      ON DUPLICATE KEY UPDATE shade_name = :name, price = :p
    ''', {'bid': brandId, 'code': shadeCode, 'name': shadeName, 'sz': packSize, 'p': price});
  }
}
