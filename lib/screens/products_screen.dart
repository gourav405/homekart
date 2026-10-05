import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../widgets/shared_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String? _movementTypeFilter;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() { if (_tabCtrl.index == 2 && !_tabCtrl.indexIsChanging) { context.read<ProductProvider>().loadMovements(); } });
    Future.microtask(() {
      final p = context.read<ProductProvider>();
      _searchCtrl.text = p.searchQuery;
      p.loadAll();
    });
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(builder: (ctx, p, _) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: double.infinity, child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, children: [
            const Text('Products & Inventory', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 12, children: [
              SizedBox(height: 48, width: 160, child: DropdownButtonFormField<int?>(isExpanded: true, decoration: const InputDecoration(border: OutlineInputBorder()), value: p.filterBrand, items: [const DropdownMenuItem(value: null, child: Text('All Brands')), ...p.brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))], onChanged: p.setFilterBrand)),
              if (_tabCtrl.index == 2) ...[
                SizedBox(height: 48, width: 160, child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: _movementTypeFilter,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(value: 'PURCHASE', child: Text('📥 Purchase')),
                    DropdownMenuItem(value: 'SALE', child: Text('📤 Sale')),
                    DropdownMenuItem(value: 'RETURN', child: Text('🔄 Return')),
                    DropdownMenuItem(value: 'ADJUSTMENT', child: Text('🔧 Adjustment')),
                    DropdownMenuItem(value: 'DAMAGE', child: Text('💥 Damage')),
                  ],
                  onChanged: (v) { setState(() => _movementTypeFilter = v); p.setMovementsPage(1, type: v); },
                )),
              ],
              if (_tabCtrl.index == 1) ...[
                SizedBox(height: 48, width: 160, child: DropdownButtonFormField<bool?>(
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: p.filterVariantStatus,
                  items: const [
                    DropdownMenuItem(value: true, child: Text('🟢 Active Only')),
                    DropdownMenuItem(value: false, child: Text('🔴 Discontinued')),
                    DropdownMenuItem(value: null, child: Text('⚪ All Variants')),
                  ],
                  onChanged: p.setFilterVariantStatus,
                )),
              ],
              SizedBox(height: 48, width: 300, child: TextField(controller: _searchCtrl, decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search, size: 20), border: OutlineInputBorder()), onChanged: p.setSearch)),
              if (_tabCtrl.index == 0)
                SizedBox(height: 48, child: FilledButton.icon(onPressed: () => _showProductForm(p), icon: const Icon(Icons.add, size: 18), label: const Text('Add Product'))),
              if (_tabCtrl.index == 1)
                SizedBox(height: 48, child: FilledButton.icon(onPressed: () => _showVariantForm(p), icon: const Icon(Icons.add, size: 18), label: const Text('Add Variant'))),
              if (_tabCtrl.index == 2)
                OutlinedButton.icon(onPressed: () => p.setMovementsPage(1, type: _movementTypeFilter), icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh')),
            ]),
          ])),
          const SizedBox(height: 16),
          TabBar(controller: _tabCtrl, isScrollable: true, onTap: (_) => setState(() {}), tabs: [
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.category_rounded, size: 18), const SizedBox(width: 8), Text('Products (${p.productsTotal})')])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.style_rounded, size: 18), const SizedBox(width: 8), Text('Variants (${p.variantsTotal})')])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.swap_vert_rounded, size: 18), const SizedBox(width: 8), Text('Stock Movements (${p.movementsTotal})')])),
          ]),
          const SizedBox(height: 16),
          Expanded(child: TabBarView(controller: _tabCtrl, children: [
            _buildProductsTab(p),
            _buildVariantsTab(p),
            _buildMovementsTab(p),
          ])),
        ]),
      );
    });
  }

  // ════════════════════════ PRODUCTS TAB ════════════════════════
  Widget _buildProductsTab(ProductProvider p) {
    if (p.isLoading) return const Center(child: CircularProgressIndicator());
    return Column(children: [
      Expanded(child: p.products.isEmpty
        ? const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products', subtitle: 'Add your first product')
        : Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              // Sticky Header
              Container(
                color: Colors.grey.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: const [
                  SizedBox(width: 120, child: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 80, child: Text('Variants', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                ]),
              ),
              const Divider(height: 1),
              // Scrollable Content
              Expanded(child: ListView.separated(
                itemCount: p.products.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final pr = p.products[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      SizedBox(width: 120, child: Text(pr.sku, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                      Expanded(flex: 2, child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
                        Text(pr.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        if (pr.isTintable) const Tooltip(message: 'Machine Tintable', child: Text('🎨', style: TextStyle(fontSize: 12))),
                        if (pr.isTaxInclusive) Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: const Text('Tax Incl', style: TextStyle(fontSize: 10, color: Colors.blue))),
                        if (!pr.isActive) Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: const Text('Discontinued', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))),
                      ])),
                      Expanded(child: Text(pr.brandName ?? '-')),
                      Expanded(child: Text(pr.categoryName ?? '-')),
                      Expanded(child: Text(pr.typeName ?? '-')),
                      SizedBox(width: 80, child: Text('${pr.variantCount}', textAlign: TextAlign.center)),
                      SizedBox(width: 100, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Edit', onPressed: () => _showProductForm(p, product: pr)),
                        IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]), tooltip: 'Delete', onPressed: () async {
                          final ok = await showDialog<bool>(context: context, builder: (_) => const ConfirmDialog(title: 'Delete Product', message: 'This will delete the product and all its variants.'));
                          if (ok == true && pr.id != null) p.deleteProduct(pr.id!);
                        }),
                      ])),
                    ]),
                  );
                },
              )),
              if (p.productsTotal > 20) _buildPagination(p.productsPage, p.productsTotal, (page) => p.setProductsPage(page)),
            ]),
          )),
    ]);
  }

  // ════════════════════════ VARIANTS TAB ════════════════════════
  Widget _buildVariantsTab(ProductProvider p) {
    if (p.isLoading) return const Center(child: CircularProgressIndicator());
    return Column(children: [
      Expanded(child: p.variants.isEmpty
        ? const EmptyState(icon: Icons.style_outlined, title: 'No variants', subtitle: 'Add product variants with sizes and colors')
        : Builder(builder: (ctx) {
            final grouped = <String, List<ProductVariant>>{};
            for (final v in p.variants) {
              grouped.putIfAbsent(v.sku, () => []).add(v);
            }
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                // Sticky Header
                Container(
                  color: Colors.grey.withValues(alpha: 0.1),
                  padding: const EdgeInsets.only(left: 16, right: 56, top: 12, bottom: 12),
                  child: Row(children: const [
                    Expanded(flex: 2, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Size & Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Variant / Color', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 70, child: Text('Batches', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    SizedBox(width: 40, child: Text('Min', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    SizedBox(width: 40, child: Text('Max', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    SizedBox(width: 70, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    SizedBox(width: 120, child: Text('')),
                  ]),
                ),
                const Divider(height: 1),
                // Scrollable Content
                Expanded(child: ListView.separated(
                  itemCount: grouped.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final sku = grouped.keys.elementAt(i);
                    final batches = grouped[sku]!;
                    final base = batches.first;
                    final totalStock = batches.fold<double>(0, (sum, v) => sum + (v.stockQty ?? 0));
                    
                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Row(children: [
                          Expanded(flex: 2, child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
                            Text('${base.productName ?? "-"}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, decoration: !batches.any((b) => b.isActive) ? TextDecoration.lineThrough : null, color: !batches.any((b) => b.isActive) ? Colors.grey : null)),
                            if (!batches.any((b) => b.isActive))
                              Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: const Text('Discontinued', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))),
                          ])),
                          Expanded(child: Text('${base.packSize.toStringAsFixed(base.packSize == base.packSize.roundToDouble() ? 0 : 1)} ${base.unitSymbol ?? ""}', style: TextStyle(color: !batches.any((b) => b.isActive) ? Colors.grey : Colors.grey[800], fontSize: 14))),
                          Expanded(child: Row(children: [
                            if (base.colorHex != null && base.colorHex!.isNotEmpty) Container(width: 14, height: 14, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: _parseHex(base.colorHex!), shape: BoxShape.circle, border: Border.all(color: Colors.grey[400]!))),
                            Text((base.variantName != null && base.variantName!.isNotEmpty) ? base.variantName! : ((base.colorName != null && base.colorName!.isNotEmpty && base.colorName!.toLowerCase() != 'none') ? base.colorName! : '-'), style: TextStyle(color: !batches.any((b) => b.isActive) ? Colors.grey : Colors.grey[800], fontSize: 14)),
                          ])),
                          SizedBox(width: 70, child: Center(child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('${batches.length}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
                          ))),
                          SizedBox(width: 40, child: Text('${base.minStock?.toStringAsFixed(0) ?? "0"}', style: TextStyle(color: Colors.grey[700], fontSize: 13), textAlign: TextAlign.center)),
                          SizedBox(width: 40, child: Text('${base.maxStock?.toStringAsFixed(0) ?? "0"}', style: TextStyle(color: Colors.grey[700], fontSize: 13), textAlign: TextAlign.center)),
                          SizedBox(width: 70, child: Center(child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF1E88E5).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('${totalStock.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: totalStock <= (base.minStock ?? 0) ? Colors.red : const Color(0xFF1E88E5), fontSize: 13)),
                          ))),
                          SizedBox(width: 40, child: IconButton(icon: const Icon(Icons.settings_outlined, size: 18), tooltip: 'Variant Limits', onPressed: () => _showStockLimitsDialog(p, base))),
                          SizedBox(width: 40, child: IconButton(icon: Icon(batches.any((b) => b.isActive) ? Icons.power_settings_new_rounded : Icons.play_circle_outline, size: 18, color: batches.any((b) => b.isActive) ? Colors.orange[700] : Colors.green), tooltip: batches.any((b) => b.isActive) ? 'Discontinue Variant' : 'Reactivate Variant', onPressed: () async {
                            bool isActive = batches.any((b) => b.isActive);
                            if (isActive && totalStock > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot discontinue variant: Total stock must be 0.'), backgroundColor: Colors.red));
                              return;
                            }
                            final ok = await showDialog<bool>(context: context, builder: (_) => ConfirmDialog(title: isActive ? 'Discontinue Variant' : 'Reactivate Variant', message: isActive ? 'This will turn off all batches for this variant. Are you sure?' : 'This will reactivate all batches for this variant. Are you sure?'));
                            if (ok == true) p.toggleVariantSkuStatus(sku, !isActive);
                          })),
                          SizedBox(width: 40, child: IconButton(icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green), tooltip: 'Add New Batch', onPressed: () => _showVariantForm(p, template: base))),
                        ]),
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))),
                            child: DataTable(
                              headingRowHeight: 40,
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 48,
                              columns: const [DataColumn(label: Text('MRP ₹')), DataColumn(label: Text('Purchase ₹')), DataColumn(label: Text('Selling ₹')), DataColumn(label: Text('Tax')), DataColumn(label: Text('Stock')), DataColumn(label: Text('Actions'))],
                              rows: batches.map((v) => DataRow(cells: [
                                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text(v.mrp != null ? '₹${v.mrp!.toStringAsFixed(0)}' : '-', style: TextStyle(fontWeight: FontWeight.w600, decoration: !v.isActive ? TextDecoration.lineThrough : null, color: !v.isActive ? Colors.grey : null)),
                                  if (!v.isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red[200]!)), child: const Text('Discontinued', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))),
                                  ]
                                ])),
                                DataCell(Text('₹${v.purchasePrice.toStringAsFixed(2)}')),
                                DataCell(Text('₹${v.sellingPrice.toStringAsFixed(2)}')),
                                DataCell(Text(v.taxName ?? '-')),
                                DataCell(Text('${((v.stockQty ?? 0) == (v.stockQty ?? 0).toInt() ? (v.stockQty ?? 0).toInt().toString() : (v.stockQty ?? 0).toString())}', style: TextStyle(fontWeight: FontWeight.bold, color: (v.stockQty ?? 0) <= (v.minStock ?? 0) ? Colors.red : Colors.green[700]))),
                                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF1E88E5)), tooltip: 'Adjust Stock', onPressed: () => _showAdjustStockDialog(p, v)),
                                  IconButton(icon: Icon(Icons.broken_image_outlined, size: 18, color: Colors.orange[700]), tooltip: 'Record Damage', onPressed: () => _showDamageDialog(p, v)),
                                  IconButton(icon: const Icon(Icons.keyboard_return_rounded, size: 18, color: Colors.purple), tooltip: 'Process Return', onPressed: () => _showReturnDialog(p, v)),
                                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Edit Batch', onPressed: () => _showVariantForm(p, variant: v)),
                                  IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]), tooltip: 'Delete Batch', onPressed: () async {
                                    final ok = await showDialog<bool>(context: context, builder: (_) => const ConfirmDialog(title: 'Delete Batch', message: 'Are you sure?'));
                                    if (ok == true && v.id != null) p.deleteVariant(v.id!);
                                  }),
                                ])),
                              ])).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )),
                if (p.variantsTotal > 20) _buildPagination(p.variantsPage, p.variantsTotal, (page) => p.setVariantsPage(page)),
              ]),
            );
          })),
    ]);
  }

  // ════════════════════════ MOVEMENTS TAB ════════════════════════
  Widget _buildMovementsTab(ProductProvider p) {
    return Column(children: [
      Expanded(child: p.movements.isEmpty
        ? const EmptyState(icon: Icons.swap_vert_rounded, title: 'No stock movements', subtitle: 'Movements appear when you create sales, purchases, or adjustments')
        : Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              // Sticky Header
              Container(
                color: Colors.grey.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: const [
                  SizedBox(width: 140, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 120, child: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 120, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 80, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(child: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
                ]),
              ),
              const Divider(height: 1),
              // Scrollable Content
              Expanded(child: ListView.separated(
                itemCount: p.movements.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final m = p.movements[i];
                  final isPositive = m.type == 'PURCHASE' || m.type == 'RETURN';
                  Color typeColor;
                  IconData typeIcon;
                  switch (m.type) {
                    case 'PURCHASE': typeColor = const Color(0xFF43A047); typeIcon = Icons.arrow_downward; break;
                    case 'SALE': typeColor = const Color(0xFF1E88E5); typeIcon = Icons.arrow_upward; break;
                    case 'RETURN': typeColor = const Color(0xFFFFA726); typeIcon = Icons.replay; break;
                    case 'ADJUSTMENT': typeColor = const Color(0xFF7B1FA2); typeIcon = Icons.tune; break;
                    case 'DAMAGE': typeColor = const Color(0xFFE53935); typeIcon = Icons.broken_image; break;
                    default: typeColor = Colors.grey; typeIcon = Icons.help;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      SizedBox(width: 140, child: Text(m.createdAt != null ? DateFormat('dd MMM yyyy HH:mm').format(m.createdAt!) : '-', style: const TextStyle(fontSize: 12))),
                      Expanded(flex: 2, child: Text(m.productName ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
                      SizedBox(width: 120, child: Text(m.variantSku ?? '-', style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                      SizedBox(width: 120, child: Align(alignment: Alignment.centerLeft, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: typeColor.withValues(alpha: 0.3))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(typeIcon, size: 14, color: typeColor),
                          const SizedBox(width: 4),
                          Text(m.type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: typeColor)),
                        ]),
                      ))),
                      SizedBox(width: 80, child: Text(
                        '${isPositive ? "+" : "-"}${m.quantity.abs().toStringAsFixed(0)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isPositive ? const Color(0xFF43A047) : const Color(0xFFE53935)),
                      )),
                      Expanded(child: Text(m.remarks ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                    ]),
                  );
                },
              )),
              if (p.movementsTotal > 20) _buildPagination(p.movementsPage, p.movementsTotal, (page) => p.setMovementsPage(page, type: _movementTypeFilter)),
            ]),
          )),
    ]);
  }

  Widget _buildPagination(int currentPage, int totalItems, Function(int) onPageChange) {
    int totalPages = (totalItems / 20).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), border: const Border(top: BorderSide(color: Colors.black12))),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text('Showing ${(currentPage - 1) * 20 + 1} - ${(currentPage * 20) > totalItems ? totalItems : (currentPage * 20)} of $totalItems', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 16),
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: currentPage > 1 ? () => onPageChange(currentPage - 1) : null),
        Text('Page $currentPage of $totalPages', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: currentPage < totalPages ? () => onPageChange(currentPage + 1) : null),
      ]),
    );
  }

  // ════════════════════════ DIALOGS ════════════════════════
  Color _parseHex(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); } catch (_) { return Colors.grey; }
  }

  void _showAdjustStockDialog(ProductProvider p, ProductVariant v) {
    final qtyCtrl = TextEditingController(text: ((v.stockQty ?? 0) == (v.stockQty ?? 0).toInt() ? (v.stockQty ?? 0).toInt().toString() : (v.stockQty ?? 0).toString()));
    final remarkCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.tune_rounded, color: Color(0xFF1E88E5)),
        const SizedBox(width: 8),
        const Text('Adjust Stock'),
      ]),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('SKU: ${v.sku}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Current: ${((v.stockQty ?? 0) == (v.stockQty ?? 0).toInt() ? (v.stockQty ?? 0).toInt().toString() : (v.stockQty ?? 0).toString())}', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
              Text('Min: ${(v.minStock ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        TextFormField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'New Quantity *', prefixIcon: Icon(Icons.inventory)), keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true),
        const SizedBox(height: 12),
        TextFormField(controller: remarkCtrl, decoration: const InputDecoration(labelText: 'Reason / Remarks', prefixIcon: Icon(Icons.note_outlined)), maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: () async {
            final newQty = double.tryParse(qtyCtrl.text);
            if (newQty == null || v.id == null) return;
            final ok = await p.adjustStock(v.id!, newQty, remarkCtrl.text.isNotEmpty ? remarkCtrl.text : 'Manual adjustment');
            if (ok && ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock adjusted!'), backgroundColor: Color(0xFF43A047))); }
          },
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Update'),
        ),
      ],
    ));
  }

  void _showDamageDialog(ProductProvider p, ProductVariant v) {
    final qtyCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Icon(Icons.broken_image_outlined, color: Colors.orange[700]),
        const SizedBox(width: 8),
        const Text('Record Damage'),
      ]),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withValues(alpha: 0.2))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('SKU: ${v.sku}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            Text('Stock: ${((v.stockQty ?? 0) == (v.stockQty ?? 0).toInt() ? (v.stockQty ?? 0).toInt().toString() : (v.stockQty ?? 0).toString())}', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
          ]),
        ),
        const SizedBox(height: 16),
        TextFormField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Damaged Quantity *', prefixIcon: Icon(Icons.remove_circle_outline)), keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true),
        const SizedBox(height: 12),
        TextFormField(controller: remarkCtrl, decoration: const InputDecoration(labelText: 'Reason *', prefixIcon: Icon(Icons.note_outlined), hintText: 'e.g., Container leaked, Can dented'), maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.orange[700]),
          onPressed: () async {
            final qty = double.tryParse(qtyCtrl.text);
            if (qty == null || qty <= 0 || v.id == null) return;
            final ok = await p.recordDamage(v.id!, qty, remarkCtrl.text.isNotEmpty ? remarkCtrl.text : 'Damaged stock');
            if (ok && ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$qty units recorded as damaged'), backgroundColor: Colors.orange[700])); }
          },
          icon: const Icon(Icons.broken_image, size: 18),
          label: const Text('Record Damage'),
        ),
      ],
    ));
  }

  void _showReturnDialog(ProductProvider p, ProductVariant v) {
    final qtyCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [Icon(Icons.keyboard_return_rounded, color: Colors.purple), SizedBox(width: 8), Text('Process Return')]),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Product: ${v.productName} - ${v.packSize}${v.unitSymbol}', style: const TextStyle(fontWeight: FontWeight.bold)),
        if (v.variantName != null && v.variantName!.isNotEmpty) Text('Variant: ${v.variantName}'),
        const SizedBox(height: 16),
        Text('This will ADD stock back into your inventory. Use this for customer returns or cancelled orders.', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        const SizedBox(height: 16),
        TextFormField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity to Return *', prefixIcon: Icon(Icons.numbers)), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 12),
        TextFormField(controller: remarkCtrl, decoration: const InputDecoration(labelText: 'Reason / Invoice Ref *', prefixIcon: Icon(Icons.note_outlined), hintText: 'e.g., Customer returned against Inv #104'), maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.purple),
          onPressed: () async {
            final qty = double.tryParse(qtyCtrl.text);
            if (qty == null || qty <= 0 || v.id == null) return;
            final ok = await p.recordReturn(v.id!, qty, remarkCtrl.text.isNotEmpty ? remarkCtrl.text : 'Customer return');
            if (ok && ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$qty units returned to stock'), backgroundColor: Colors.purple)); }
          },
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: const Text('Add to Stock'),
        ),
      ],
    ));
  }

  void _showProductForm(ProductProvider p, {Product? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final skuCtrl = TextEditingController(text: product?.sku ?? '');
    final hsnCtrl = TextEditingController(text: product?.hsnCode ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    int? brandId = product?.brandId;
    int? catId = product?.categoryId;
    int? subCatId = product?.subcategoryId;
    int? typeId = product?.typeId;
    bool isTintable = product?.isTintable ?? false;
    bool isTaxInclusive = product?.isTaxInclusive ?? false;
    bool taxRemittable = product?.taxRemittable ?? true;
    bool isActive = product?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(product == null ? 'Add Product' : 'Edit Product'),
      content: SizedBox(width: 600, child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU *'), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: hsnCtrl, decoration: const InputDecoration(labelText: 'HSN/SAC Code'))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Row(children: [
            Expanded(child: DropdownButtonFormField<int>(isExpanded: true, decoration: const InputDecoration(labelText: 'Brand *'), value: brandId, items: p.brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setDlgState(() => brandId = v), validator: (v) => v == null ? 'Required' : null)),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1E88E5)), tooltip: 'Add new Brand', onPressed: () => _showAddBrandDialog(p, () => setDlgState(() {}))),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Row(children: [
            Expanded(child: DropdownButtonFormField<int>(isExpanded: true, decoration: const InputDecoration(labelText: 'Category *'), value: catId, items: p.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setDlgState(() { catId = v; subCatId = null; typeId = null; }), validator: (v) => v == null ? 'Required' : null)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int?>(isExpanded: true, decoration: const InputDecoration(labelText: 'Subcategory'), value: subCatId, items: [const DropdownMenuItem(value: null, child: Text('None')), ...p.subcategories.where((s) => catId == null || s.categoryId == catId || s.id == subCatId).map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)))], onChanged: (v) => setDlgState(() { subCatId = v; typeId = null; }))),
          const SizedBox(width: 12),
          Expanded(child: Row(children: [
            Expanded(child: DropdownButtonFormField<int?>(isExpanded: true, decoration: const InputDecoration(labelText: 'Type'), value: typeId, items: [const DropdownMenuItem(value: null, child: Text('None')), ...p.types.where((t) => t.subcategoryId == null || t.subcategoryId == subCatId || t.id == typeId).map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis)))], onChanged: (v) => setDlgState(() => typeId = v))),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1E88E5)), tooltip: 'Add new Type', onPressed: () => _showAddTypeDialog(p, subCatId, () => setDlgState(() {}))),
          ])),
        ]),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            bool showTintable = false;
            if (catId != null) {
              try {
                final cat = p.categories.firstWhere((c) => c.id == catId);
                showTintable = cat.name.toLowerCase().contains('paint');
              } catch (_) {}
            }
            if (!showTintable) isTintable = false;

            return Row(children: [
              if (showTintable) ...[
                Expanded(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: isTintable ? Colors.orange.withValues(alpha: 0.05) : null, borderRadius: BorderRadius.circular(8), border: Border.all(color: isTintable ? Colors.orange.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2))),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('🎨 Machine Tintable', style: TextStyle(fontSize: 13)),
                    value: isTintable,
                    onChanged: (v) => setDlgState(() => isTintable = v ?? false),
                  ),
                )),
                const SizedBox(width: 12),
              ],
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: isTaxInclusive ? Colors.blue.withValues(alpha: 0.05) : null, borderRadius: BorderRadius.circular(8), border: Border.all(color: isTaxInclusive ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2))),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tax Inclusive Price', style: TextStyle(fontSize: 13)),
                  value: isTaxInclusive,
                  onChanged: (v) => setDlgState(() => isTaxInclusive = v ?? false),
                ),
              )),
            ]);
          }
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: !taxRemittable ? Colors.amber.withValues(alpha: 0.05) : null, borderRadius: BorderRadius.circular(8), border: Border.all(color: !taxRemittable ? Colors.amber.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2))),
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tax Remittable to Govt', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Uncheck for services like tinting where you keep the tax', style: TextStyle(fontSize: 11)),
            value: taxRemittable,
            onChanged: (v) => setDlgState(() => taxRemittable = v ?? true),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Active (Available in System)'),
          subtitle: const Text('Turn off to completely discontinue this product and all its variants'),
          value: isActive,
          onChanged: (v) => setDlgState(() => isActive = v),
          activeColor: Colors.green,
        ),
      ])))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          
          if (!isActive && product != null) {
            double stock = await p.getProductTotalStock(product.id!);
            if (stock > 0) {
              if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot discontinue: Total stock of all variants must be 0.'), backgroundColor: Colors.red));
              return;
            }
          }
          
          bool finalTintable = isTintable;
          if (catId != null) {
            try {
              final cat = p.categories.firstWhere((c) => c.id == catId);
              if (!cat.name.toLowerCase().contains('paint')) finalTintable = false;
            } catch (_) {}
          }
          final pr = Product(id: product?.id, name: nameCtrl.text, sku: skuCtrl.text, hsnCode: hsnCtrl.text.isNotEmpty ? hsnCtrl.text : null, description: descCtrl.text.isNotEmpty ? descCtrl.text : null, brandId: brandId!, categoryId: catId!, subcategoryId: subCatId, typeId: typeId, isTintable: finalTintable, isTaxInclusive: isTaxInclusive, taxRemittable: taxRemittable, isActive: isActive);
          final ok = product == null ? await p.addProduct(pr) : await p.updateProduct(pr);
          if (ok && ctx.mounted) Navigator.pop(ctx);
        }, child: Text(product == null ? 'Add' : 'Save')),
      ],
    )));
  }

  void _showAddBrandDialog(ProductProvider p, VoidCallback onAdded) {
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Brand'),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Brand Name *'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          final ok = await p.addBrand(nameCtrl.text, null);
          if (ok && ctx.mounted) {
            Navigator.pop(ctx);
            onAdded();
          }
        }, child: const Text('Add')),
      ],
    ));
  }

  void _showAddTypeDialog(ProductProvider p, int? subCatId, VoidCallback onAdded) {
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Type'),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (subCatId != null) Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Adding type for ${p.subcategories.firstWhere((s) => s.id == subCatId).name}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ),
        TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Type Name *'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          final ok = await p.addProductType(nameCtrl.text, subcategoryId: subCatId);
          if (ok && ctx.mounted) {
            Navigator.pop(ctx);
            onAdded();
          }
        }, child: const Text('Add')),
      ],
    ));
  }

  void _showVariantForm(ProductProvider p, {ProductVariant? variant, ProductVariant? template}) {
    final source = variant ?? template;
    final skuCtrl = TextEditingController(text: source?.sku ?? '');
    final vNameCtrl = TextEditingController(text: source?.variantName ?? '');
    final barcodeCtrl = TextEditingController(text: source?.barcode ?? '');
    final packCtrl = TextEditingController(text: source != null ? source.packSize.toString() : '');
    final ppCtrl = TextEditingController(text: source != null ? source.purchasePrice.toString() : '');
    final spCtrl = TextEditingController(text: source != null ? source.sellingPrice.toString() : '');
    final mrpCtrl = TextEditingController(text: source?.mrp?.toString() ?? '');
    final minStockCtrl = TextEditingController(text: source?.minStock?.toStringAsFixed(0) ?? '0');
    final maxStockCtrl = TextEditingController(text: source?.maxStock?.toStringAsFixed(0) ?? '0');
    final convCtrl = TextEditingController(text: source?.conversionFactor?.toStringAsFixed(2) ?? '');
    int? productId = source?.productId;
    int? unitId = source?.unitId;
    int? purchaseUnitId = source?.purchaseUnitId;
    int? colorId = source?.colorId;
    int? taxId = source?.taxRateId;
    bool isActive = variant?.isActive ?? true; // Default to active for new batches even if template is inactive
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(variant == null ? 'Add Variant' : 'Edit Variant'),
      content: SizedBox(width: 520, child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(decoration: const InputDecoration(labelText: 'Product *'), value: productId, items: p.products.map((pr) => DropdownMenuItem(value: pr.id, child: Text(pr.name))).toList(), onChanged: variant != null ? null : (v) => setDlgState(() => productId = v), validator: (v) => v == null ? 'Required' : null),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU *'), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: vNameCtrl, decoration: const InputDecoration(labelText: 'Variant Name / Size', hintText: 'e.g. 90 Grit, 2 inch'))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode'))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: packCtrl, decoration: const InputDecoration(labelText: 'Pack Size *'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<int>(decoration: const InputDecoration(labelText: 'Base Unit *'), value: unitId, items: p.units.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.name} (${u.symbol})'))).toList(), onChanged: (v) => setDlgState(() => unitId = v), validator: (v) => v == null ? 'Required' : null)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int?>(decoration: const InputDecoration(labelText: 'Color'), value: colorId, items: [const DropdownMenuItem(value: null, child: Text('None')), ...p.colors.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))], onChanged: (v) => setDlgState(() => colorId = v))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<int?>(decoration: const InputDecoration(labelText: 'Tax Rate'), value: taxId, items: [const DropdownMenuItem(value: null, child: Text('None')), ...p.taxRates.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.name} (${t.percentage}%)')))], onChanged: (v) => setDlgState(() => taxId = v))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: ppCtrl, decoration: const InputDecoration(labelText: 'Purchase ₹ (per Base Unit) *', prefixText: '₹ '), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: spCtrl, decoration: const InputDecoration(labelText: 'Selling ₹ *', prefixText: '₹ '), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: mrpCtrl, decoration: const InputDecoration(labelText: 'MRP', prefixText: '₹ '), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int?>(decoration: const InputDecoration(labelText: 'Purchase Unit (Optional)'), value: purchaseUnitId, items: [const DropdownMenuItem(value: null, child: Text('Same as Base Unit')), ...p.units.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.name} (${u.symbol})')))], onChanged: (v) => setDlgState(() => purchaseUnitId = v))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: convCtrl, decoration: const InputDecoration(labelText: 'Base Units per Purchase Unit', hintText: 'e.g. 50 (if 1 Box = 50 Pieces)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: minStockCtrl, decoration: const InputDecoration(labelText: 'Min Stock'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: maxStockCtrl, decoration: const InputDecoration(labelText: 'Max Stock'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
        ]),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Active (Available for Sale)'),
          subtitle: const Text('Turn off to discontinue this batch'),
          value: isActive,
          onChanged: (v) => setDlgState(() => isActive = v),
          activeColor: Colors.green,
        ),
        const SizedBox(height: 12),
      ])))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          
          if (!isActive && variant != null && (variant.stockQty ?? 0) > 0) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot discontinue batch: Stock must be exactly 0.'), backgroundColor: Colors.red));
            return;
          }
          
          final nv = ProductVariant(id: variant?.id, productId: productId!, unitId: unitId!, packSize: double.parse(packCtrl.text), sku: skuCtrl.text, variantName: vNameCtrl.text.isNotEmpty ? vNameCtrl.text : null, barcode: barcodeCtrl.text.isNotEmpty ? barcodeCtrl.text : null, purchasePrice: double.parse(ppCtrl.text), sellingPrice: double.parse(spCtrl.text), mrp: mrpCtrl.text.isNotEmpty ? double.parse(mrpCtrl.text) : null, colorId: colorId, taxRateId: taxId, purchaseUnitId: purchaseUnitId, conversionFactor: double.tryParse(convCtrl.text), minStock: double.tryParse(minStockCtrl.text), maxStock: double.tryParse(maxStockCtrl.text), isActive: isActive);
          final ok = variant == null ? await p.addVariant(nv) : await p.updateVariant(nv);
          if (ok && ctx.mounted) Navigator.pop(ctx);
        }, child: Text(variant == null ? 'Add' : 'Save')),
      ],
    )));
  }
  void _showStockLimitsDialog(ProductProvider p, ProductVariant base) {
    final minCtrl = TextEditingController(text: base.minStock?.toStringAsFixed(0) ?? '0');
    final maxCtrl = TextEditingController(text: base.maxStock?.toStringAsFixed(0) ?? '0');
    
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Set Variant Stock Limits'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(base.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Applies to all batches of this variant.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: TextFormField(controller: minCtrl, decoration: const InputDecoration(labelText: 'Min Stock'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: maxCtrl, decoration: const InputDecoration(labelText: 'Max Stock'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final min = double.tryParse(minCtrl.text) ?? 0;
          final max = double.tryParse(maxCtrl.text) ?? 0;
          final ok = await p.updateStockLimitsBySku(base.sku, min, max);
          if (ok && ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }
}
