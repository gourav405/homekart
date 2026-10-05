import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/masters.dart';
import '../services/product_service.dart';
import '../services/inventory_service.dart';
import '../models/inventory.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _svc = ProductService();
  List<Product> _products = [];
  List<ProductVariant> _variants = [];
  List<Brand> _brands = [];
  List<Category> _categories = [];
  List<Subcategory> _subcategories = [];
  List<ProductType> _types = [];
  List<Unit> _units = [];
  List<PaintColor> _colors = [];
  List<TaxRate> _taxRates = [];
  bool _isLoading = false;
  String? _error;
  String _search = '';
  int? _filterBrand;
  int? _filterCategory;
  bool? _filterVariantStatus = true; // true = Active, false = Discontinued, null = All
  
  int? get filterBrand => _filterBrand;
  int? get filterCategory => _filterCategory;
  bool? get filterVariantStatus => _filterVariantStatus;
  String get searchQuery => _search;

  List<Product> get products => _products;
  List<ProductVariant> get variants => _variants;
  List<Brand> get brands => _brands;
  List<Category> get categories => _categories;
  List<Subcategory> get subcategories => _subcategories;
  List<ProductType> get types => _types;
  List<Unit> get units => _units;
  List<PaintColor> get colors => _colors;
  List<TaxRate> get taxRates => _taxRates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int _productsTotal = 0;
  int _productsPage = 1;
  int get productsTotal => _productsTotal;
  int get productsPage => _productsPage;

  int _variantsTotal = 0;
  int _variantsPage = 1;
  int get variantsTotal => _variantsTotal;
  int get variantsPage => _variantsPage;

  Future<void> loadAll() async {
    _isLoading = true; notifyListeners();
    try {
      _brands = await _svc.getBrands();
      _categories = await _svc.getCategories();
      _subcategories = await _svc.getSubcategories();
      _types = await _svc.getProductTypes();
      _units = await _svc.getUnits();
      _colors = await _svc.getColors();
      _taxRates = await _svc.getTaxRates();
      
      final pRes = await _svc.getAllProducts(search: _search.isNotEmpty ? _search : null, brandId: _filterBrand, categoryId: _filterCategory, limit: 20, offset: (_productsPage - 1) * 20);
      _products = pRes.$1;
      _productsTotal = pRes.$2;
      
      final vRes = await _svc.getVariants(search: _search.isNotEmpty ? _search : null, limit: 20, offset: (_variantsPage - 1) * 20);
      _variants = vRes.$1;
      _variantsTotal = vRes.$2;
    } catch (e) { _error = e.toString(); }
    _isLoading = false; notifyListeners();
  }

  Future<void> loadProducts() async {
    try { 
      final pRes = await _svc.getAllProducts(search: _search.isNotEmpty ? _search : null, brandId: _filterBrand, categoryId: _filterCategory, limit: 20, offset: (_productsPage - 1) * 20); 
      _products = pRes.$1;
      _productsTotal = pRes.$2;
      notifyListeners(); 
    } catch (e) { _error = e.toString(); notifyListeners(); }
  }

  Future<void> loadVariants({int? productId}) async {
    try { 
      final vRes = await _svc.getVariants(productId: productId, brandId: _filterBrand, categoryId: _filterCategory, isActive: _filterVariantStatus, search: _search.isNotEmpty ? _search : null, limit: 20, offset: (_variantsPage - 1) * 20); 
      _variants = vRes.$1;
      _variantsTotal = vRes.$2;
      notifyListeners(); 
    } catch (e) { _error = e.toString(); notifyListeners(); }
  }

  void setProductsPage(int page) { _productsPage = page; loadProducts(); }
  void setVariantsPage(int page) { _variantsPage = page; loadVariants(); }

  void setSearch(String s) { _search = s; _productsPage = 1; _variantsPage = 1; _movementsPage = 1; loadProducts(); loadVariants(); loadMovements(); }
  void setFilterBrand(int? id) { _filterBrand = id; _productsPage = 1; _variantsPage = 1; _movementsPage = 1; loadProducts(); loadVariants(); loadMovements(); }
  void setFilterCategory(int? id) { _filterCategory = id; _productsPage = 1; _variantsPage = 1; loadProducts(); loadVariants(); }
  void setFilterVariantStatus(bool? val) { _filterVariantStatus = val; _variantsPage = 1; loadVariants(); }

  Future<bool> addProduct(Product p) async { try { await _svc.createProduct(p); await loadProducts(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> updateProduct(Product p) async { try { await _svc.updateProduct(p); await loadProducts(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> deleteProduct(int id) async { try { await _svc.deleteProduct(id); await loadProducts(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }

  Future<bool> addVariant(ProductVariant v) async { try { await _svc.createVariant(v); await loadVariants(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> updateVariant(ProductVariant v) async { try { await _svc.updateVariant(v); await loadVariants(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> deleteVariant(int id) async { try { await _svc.deleteVariant(id); await loadVariants(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> updateStockLimits(int variantId, double min, double max) async { try { await _svc.updateStockLimits(variantId, min, max); await loadVariants(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> updateStockLimitsBySku(String sku, double min, double max) async { try { await _svc.updateStockLimitsBySku(sku, min, max); await loadVariants(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }

  Future<bool> toggleVariantSkuStatus(String sku, bool isActive) async {
    try {
      await _svc.toggleVariantSkuStatus(sku, isActive);
      await loadVariants(); // Refresh variants list
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addBrand(String name, String? desc) async { try { await _svc.createBrand(name, desc); _brands = await _svc.getBrands(); notifyListeners(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> addCategory(String name, String? desc) async { try { await _svc.createCategory(name, desc); _categories = await _svc.getCategories(); notifyListeners(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> addSubcategory(String name, int catId) async { try { await _svc.createSubcategory(name, catId); _subcategories = await _svc.getSubcategories(); notifyListeners(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> addProductType(String name, {int? subcategoryId}) async { try { await _svc.createProductType(name, subcategoryId: subcategoryId); _types = await _svc.getProductTypes(); notifyListeners(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> addUnit(String name, String symbol) async { try { await _svc.createUnit(name, symbol); _units = await _svc.getUnits(); notifyListeners(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> addColor(String name, String? code, String? hex) async { try { await _svc.createColor(name, code, hex); _colors = await _svc.getColors(); notifyListeners(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }
  Future<bool> addTaxRate(String name, double pct) async { try { await _svc.createTaxRate(name, pct); _taxRates = await _svc.getTaxRates(); notifyListeners(); return true; } catch (e) { _error = e.toString(); notifyListeners(); return false; } }

  Future<Map<String, dynamic>?> getShadePrice(int brandId, String shadeCode, double packSize) async {
    try { return await _svc.getShadePrice(brandId, shadeCode, packSize); } catch (_) { return null; }
  }
  Future<bool> saveShadePrice(int brandId, String shadeCode, String shadeName, double packSize, double price) async {
    try { await _svc.saveShadePrice(brandId, shadeCode, shadeName, packSize, price); return true; } catch (_) { return false; }
  }

  // ── Stock Management ──
  final InventoryService _invSvc = InventoryService();
  List<StockMovement> _movements = [];
  List<Inventory> _lowStock = [];

  int _movementsTotal = 0;
  int _movementsPage = 1;
  int get movementsTotal => _movementsTotal;
  int get movementsPage => _movementsPage;

  List<StockMovement> get movements => _movements;
  List<Inventory> get lowStock => _lowStock;

  Future<void> loadMovements({int? variantId, String? type}) async {
    try { 
      final mRes = await _invSvc.getMovements(variantId: variantId, brandId: _filterBrand, search: _search.isNotEmpty ? _search : null, type: type, limit: 20, offset: (_movementsPage - 1) * 20); 
      _movements = mRes.$1;
      _movementsTotal = mRes.$2;
      notifyListeners(); 
    } catch (e) { _error = e.toString(); notifyListeners(); }
  }

  void setMovementsPage(int page, {int? variantId, String? type}) {
    _movementsPage = page;
    loadMovements(variantId: variantId, type: type);
  }
  
  void resetMovementsPage() {
    _movementsPage = 1;
  }

  Future<List<ProductVariant>> searchVariants(String query) async {
    try {
      final vRes = await _svc.getVariants(search: query, isActive: true, limit: 10, offset: 0);
      return vRes.$1;
    } catch (e) {
      return [];
    }
  }

  Future<double> getProductTotalStock(int productId) async {
    try {
      return await _svc.getProductTotalStock(productId);
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> loadLowStock() async {
    try { _lowStock = await _invSvc.getLowStock(); notifyListeners(); } catch (e) { _error = e.toString(); notifyListeners(); }
  }

  Future<bool> adjustStock(int variantId, double newQty, String remarks) async {
    try {
      await _invSvc.addStockMovement(variantId, 'ADJUSTMENT', newQty, remarks: remarks);
      await loadVariants();
      await loadMovements();
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> recordDamage(int variantId, double qty, String remarks) async {
    try {
      await _invSvc.addStockMovement(variantId, 'DAMAGE', qty, remarks: remarks);
      await loadVariants();
      await loadMovements();
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> recordReturn(int variantId, double qty, String remarks) async {
    try {
      await _invSvc.addStockMovement(variantId, 'RETURN', qty, remarks: remarks);
      await loadVariants();
      await loadMovements();
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> updateStockLevels(int variantId, double minStock, double maxStock) async {
    try {
      await _invSvc.updateStockLevels(variantId, minStock, maxStock);
      await loadVariants();
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }
}
