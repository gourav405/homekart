import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/sale_provider.dart';
import '../providers/settings_provider.dart';
import "../models/customer.dart";
import '../providers/people_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_variant.dart';
import '../models/sale.dart';
import '../widgets/shared_widgets.dart';
import '../services/pdf_service.dart';
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  bool _creating = false;
  final _searchCtrl = TextEditingController();
  final _varSearchCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  List<ProductVariant> _searchResults = [];
  String? _selectedCategoryFilter;
  String _paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SaleProvider>().loadSales();
      context.read<CustomerProvider>().load();
      context.read<ProductProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SaleProvider>(
      builder: (ctx, sp, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: _creating ? _buildCreateView(sp) : _buildListView(sp),
        );
      },
    );
  }

  Widget _buildListView(SaleProvider sp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  const Text(
                    'Sales',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${sp.sales.length}',
                      style: const TextStyle(
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    height: 48,
                    width: 300,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: sp.setSearchQuery,
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    width: 160,
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Status'),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('All Statuses'),
                        ),
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        DropdownMenuItem(
                          value: 'unpaid',
                          child: Text('Unpaid'),
                        ),
                        DropdownMenuItem(
                          value: 'partial',
                          child: Text('Partial'),
                        ),
                      ],
                      onChanged: sp.setStatusFilter,
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await sp.initNewSale();
                        bool? result = await _showCustomerSelectionDialog(
                          context,
                          sp,
                        );
                        if (result == true) {
                          setState(() => _creating = true);
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Sale'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: sp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : sp.sales.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No sales',
                  subtitle: 'Create your first sale',
                )
              : Card(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Invoice')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Subtotal'), numeric: true),
                        DataColumn(label: Text('Tax'), numeric: true),
                        DataColumn(label: Text('Total'), numeric: true),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: sp.sales
                          .map(
                            (s) => DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    s.invoiceNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                DataCell(Text(s.customerName ?? 'Walk-in')),
                                DataCell(
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(s.saleDate),
                                  ),
                                ),
                                DataCell(
                                  Text('₹${s.subtotal.toStringAsFixed(2)}'),
                                ),
                                DataCell(Text('₹${s.tax.toStringAsFixed(2)}')),
                                DataCell(
                                  Text(
                                    '₹${s.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  s.status == 'hold'
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[50],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange,
                                            ),
                                          ),
                                          child: const Text(
                                            'HOLD',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : s.paymentStatus == 'refunded'
                                      ? const Text(
                                          'Refunded',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : s.paymentStatus == 'partial_refund'
                                      ? const Text(
                                          'Partial Rtn',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: s.paymentStatus == 'paid'
                                                ? Colors.green[50]
                                                : Colors.orange[50],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            s.paymentStatus.toUpperCase(),
                                            style: TextStyle(
                                              color: s.paymentStatus == 'paid'
                                                  ? Colors.green[700]
                                                  : Colors.orange[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (s.status == 'hold')
                                        FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          onPressed: () async {
                                            final details = await sp
                                                .getSaleDetails(s.id!);
                                            if (details != null && mounted) {
                                              await sp.resumeHoldOrder(details);
                                              setState(() => _creating = true);
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.play_arrow,
                                            size: 16,
                                          ),
                                          label: const Text('Resume'),
                                        )
                                      else ...[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                            size: 18,
                                          ),
                                          tooltip: 'View Details',
                                          onPressed: () =>
                                              _showSaleDetails(sp, s.id!),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.print_outlined,
                                            size: 18,
                                            color: Color(0xFF1E88E5),
                                          ),
                                          tooltip: 'Print Invoice',
                                          onPressed: () =>
                                              _printInvoice(sp, s.id!),
                                        ),
                                      ],
                                      if (context.read<AuthProvider>().isAdmin)
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Colors.red[400],
                                          ),
                                          tooltip: 'Delete',
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => const ConfirmDialog(
                                                title: 'Delete Sale',
                                                message:
                                                    'This will restore stock. Continue?',
                                              ),
                                            );
                                            if (ok == true && s.id != null)
                                              sp.deleteSale(s.id!);
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCreateView(SaleProvider sp) {
    final customers = context.watch<CustomerProvider>().customers;
    final allVariants = context.watch<ProductProvider>().variants;
    final settings = context.watch<SettingsProvider>();
    final categories = context.watch<ProductProvider>().categories;
    const blue = Color(0xFF1565C0);

    return Column(
      children: [
        // ── Header ──
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () { sp.clearSale(); setState(() => _creating = false); }),
          const SizedBox(width: 8),
          const Icon(Icons.shopping_cart_outlined, size: 22),
          const SizedBox(width: 8),
          const Text('New Sale', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('Invoice: ${sp.invoiceNumber}', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontFamily: 'monospace')),
        ]),
        const SizedBox(height: 12),
        // ── Main two-column layout ──
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ════════ LEFT / MAIN AREA ════════
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // ── Search bar + Category chips ──
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(children: [
                              Expanded(
                                child: TextField(
                                  controller: _varSearchCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Scan barcode or search product...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () {}),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onTap: () async {
                                    if (_varSearchCtrl.text.isEmpty) {
                                      final res = await context.read<ProductProvider>().searchVariants('');
                                      if (mounted) setState(() => _searchResults = res);
                                    }
                                  },
                                  onChanged: (q) async {
                                    final res = await context.read<ProductProvider>().searchVariants(q);
                                    if (mounted) setState(() => _searchResults = res);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Category filter chips
                              ...([null, ...categories]).map((cat) {
                                final isAll = cat == null;
                                final label = isAll ? 'All' : cat.name;
                                final isSelected = _selectedCategoryFilter == (isAll ? null : cat.name);
                                return Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: ChoiceChip(
                                    label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : blue)),
                                    selected: isSelected,
                                    selectedColor: blue,
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: isSelected ? blue : Colors.grey[300]!),
                                    onSelected: (_) => setState(() => _selectedCategoryFilter = isAll ? null : cat.name),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                );
                              }),
                            ]),
                          ],
                        ),
                      ),
                    ),

                    // ── Search results dropdown ──
                    if (_searchResults.isNotEmpty)
                      Builder(builder: (ctx) {
                        final groupedSearch = <String, List<ProductVariant>>{};
                        for (final v in _searchResults) {
                          groupedSearch.putIfAbsent(v.sku, () => []).add(v);
                        }
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: Card(
                            margin: const EdgeInsets.only(top: 4),
                            child: SingleChildScrollView(
                              child: Column(
                                children: groupedSearch.entries.map((e) {
                                  final batches = e.value;
                                  final v = batches.first;
                                  final totalStock = batches.fold<double>(0, (sum, b) {
                                    double inCart = sp.currentItems.where((i) => i.productVariantId == b.id).fold(0.0, (s, i) => s + i.quantity);
                                    double rem = (b.stockQty ?? 0) - inCart;
                                    return sum + (rem > 0 ? rem : 0);
                                  });
                                  final isOutOfStock = totalStock <= 0;
                                  return ListTile(
                                    dense: true,
                                    leading: v.isTintable
                                        ? Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                            child: const Text('🎨', style: TextStyle(fontSize: 16)),
                                          )
                                        : null,
                                    title: Text(v.displayName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isOutOfStock ? Colors.grey : null)),
                                    subtitle: Text(
                                      'SKU: ${v.sku} | Total Stock: ${totalStock.toStringAsFixed(2)}${v.isTintable ? ' | Tintable' : ''}${batches.length > 1 ? ' | ${batches.length} Batches' : ' | ₹${v.sellingPrice.toStringAsFixed(2)}'}',
                                      style: TextStyle(fontSize: 11, color: isOutOfStock ? Colors.red : (batches.length > 1 ? Colors.blue[700] : Colors.grey[700]), fontWeight: batches.length > 1 ? FontWeight.w500 : FontWeight.normal),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(isOutOfStock ? Icons.block : Icons.add_circle, color: isOutOfStock ? Colors.grey : blue),
                                      onPressed: isOutOfStock ? null : () {
                                        _varSearchCtrl.clear();
                                        setState(() => _searchResults = []);
                                        _showBatchSelectionDialog(sp, batches);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 8),

                    // ── Items table ──
                    Expanded(
                      child: sp.currentItems.isEmpty
                          ? Card(
                              child: Center(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text('No items added yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('Search and add products above', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                                ]),
                              ),
                            )
                          : Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(children: [
                                // Table header
                                Container(
                                  color: Colors.grey.withValues(alpha: 0.06),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(children: [
                                    const SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    const Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    const SizedBox(width: 110, child: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    const SizedBox(width: 100, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                                    const SizedBox(width: 90, child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right)),
                                    const SizedBox(width: 70, child: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                                    const SizedBox(width: 70, child: Text('Tax', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                                    const SizedBox(width: 90, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right)),
                                    const SizedBox(width: 40),
                                  ]),
                                ),
                                const Divider(height: 1),
                                // Table rows
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: sp.currentItems.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (ctx, idx) {
                                      final i = sp.currentItems[idx];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Row(children: [
                                          SizedBox(width: 30, child: Text('${idx + 1}', style: TextStyle(color: Colors.grey[600], fontSize: 13))),
                                          Expanded(flex: 3, child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(i.productName ?? i.variantSku ?? '-', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                              if (i.isTinted) Text('🎨 ${i.shadeCode} - ${i.shadeName ?? ''}', style: TextStyle(fontSize: 11, color: Colors.orange[800], fontWeight: FontWeight.w500)),
                                            ],
                                          )),
                                          SizedBox(width: 110, child: Text(i.variantSku ?? '-', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey[600]))),
                                          SizedBox(width: 100, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                            InkWell(
                                              onTap: i.quantity > 1 ? () => sp.updateQty(idx, i.quantity - 1) : null,
                                              child: Container(
                                                width: 26, height: 26,
                                                decoration: BoxDecoration(color: blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                                child: Icon(Icons.remove, size: 16, color: i.quantity > 1 ? blue : Colors.grey),
                                              ),
                                            ),
                                            SizedBox(width: 32, child: Text(
                                              i.quantity == i.quantity.toInt() ? i.quantity.toInt().toString() : i.quantity.toString(),
                                              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                            )),
                                            InkWell(
                                              onTap: () => sp.updateQty(idx, i.quantity + 1),
                                              child: Container(
                                                width: 26, height: 26,
                                                decoration: BoxDecoration(color: blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                                child: Icon(Icons.add, size: 16, color: blue),
                                              ),
                                            ),
                                          ])),
                                          SizedBox(width: 90, child: Text('₹ ${i.price.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                                          SizedBox(width: 70, child: Text(
                                            i.discount > 0 ? '₹${i.discount.toStringAsFixed(0)}' : '0%',
                                            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: i.discount > 0 ? Colors.red : Colors.grey[500]),
                                          )),
                                          SizedBox(width: 70, child: Text(
                                            '₹${i.tax.toStringAsFixed(0)}',
                                            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          )),
                                          SizedBox(width: 90, child: Text('₹ ${i.totalWithTinting.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                          SizedBox(width: 40, child: PopupMenuButton<String>(
                                            icon: Icon(Icons.more_horiz, size: 20, color: Colors.grey[600]),
                                            padding: EdgeInsets.zero,
                                            onSelected: (val) {
                                              if (val == 'price') {
                                                final ctrl = TextEditingController(text: i.price.toStringAsFixed(2));
                                                showDialog(context: context, builder: (ctx) => AlertDialog(
                                                  title: Text('Override Unit Price: ${i.productName}', style: const TextStyle(fontSize: 16)),
                                                  content: TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'New Base Price (Before Tax)', prefixText: '₹ '), autofocus: true),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                                    FilledButton(onPressed: () { final p = double.tryParse(ctrl.text); if (p != null) sp.updatePrice(idx, p); Navigator.pop(ctx, true); }, child: const Text('Update')),
                                                  ],
                                                ));
                                              } else if (val == 'discount') {
                                                final ctrl = TextEditingController(text: i.discount > 0 ? i.discount.toStringAsFixed(2) : '');
                                                showDialog(context: context, builder: (ctx) => AlertDialog(
                                                  title: Text('Item Discount: ${i.productName}', style: const TextStyle(fontSize: 16)),
                                                  content: TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Row Discount Amount', prefixText: '₹ '), autofocus: true),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                                    FilledButton(onPressed: () { sp.updateItemDiscount(idx, double.tryParse(ctrl.text) ?? 0); Navigator.pop(ctx, true); }, child: const Text('Apply')),
                                                  ],
                                                ));
                                              } else if (val == 'remove') {
                                                sp.removeItem(idx);
                                              }
                                            },
                                            itemBuilder: (_) => [
                                              const PopupMenuItem(value: 'price', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit Price')])),
                                              const PopupMenuItem(value: 'discount', child: Row(children: [Icon(Icons.discount, size: 16), SizedBox(width: 8), Text('Add Discount')])),
                                              const PopupMenuItem(value: 'remove', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text('Remove', style: TextStyle(color: Colors.red))])),
                                            ],
                                          )),
                                        ]),
                                      );
                                    },
                                  ),
                                ),
                              ]),
                            ),
                    ),

                    const SizedBox(height: 8),

                    // ── Action buttons row ──
                    Row(children: [
                      FilledButton.icon(
                        onPressed: () => FocusScope.of(context).requestFocus(FocusNode()), // focus search
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item'),
                        style: FilledButton.styleFrom(backgroundColor: blue),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(context: context, builder: (ctx) => AlertDialog(
                            title: const Text('Bill Discount'),
                            content: TextField(controller: _discountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Discount Amount', prefixText: '₹ '), autofocus: true),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              FilledButton(onPressed: () { sp.setDiscount(double.tryParse(_discountCtrl.text) ?? 0); Navigator.pop(ctx); }, child: const Text('Apply')),
                            ],
                          ));
                        },
                        icon: const Icon(Icons.diamond_outlined, size: 18),
                        label: const Text('Discount'),
                        style: OutlinedButton.styleFrom(foregroundColor: blue, side: BorderSide(color: blue)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: sp.currentItems.isEmpty ? null : () async {
                          final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                            title: const Text('Remove All Items?'),
                            content: const Text('This will clear all items from the cart.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove All')),
                            ],
                          ));
                          if (ok == true) {
                            while (sp.currentItems.isNotEmpty) { sp.removeItem(0); }
                          }
                        },
                        icon: Icon(Icons.delete_outline, size: 18, color: sp.currentItems.isEmpty ? Colors.grey : Colors.red),
                        label: Text('Remove', style: TextStyle(color: sp.currentItems.isEmpty ? Colors.grey : Colors.red)),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: sp.currentItems.isEmpty ? Colors.grey[300]! : Colors.red[200]!)),
                      ),
                    ]),

                    const SizedBox(height: 12),

                    // ── Bottom: Customer Details + Notes ──
                    SizedBox(
                      height: 140,
                      child: Row(children: [
                        // Customer Details
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ]),
                                const SizedBox(height: 8),
                                Expanded(child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                                    hintText: 'Walk-in Customer',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                  ),
                                  value: sp.customerId,
                                  items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name}${c.phone != null && c.phone!.isNotEmpty ? " - ${c.phone}" : ""}', overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (v) { if (v != null) { final c = customers.firstWhere((c) => c.id == v); sp.setCustomer(c, businessState: context.read<SettingsProvider>().businessState); } },
                                )),
                                const SizedBox(height: 6),
                                Align(alignment: Alignment.centerRight, child: TextButton.icon(
                                  onPressed: () => _showQuickAddCustomerDialog(context, sp),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('New Customer', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(foregroundColor: blue, visualDensity: VisualDensity.compact),
                                )),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Notes
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Icon(Icons.note_outlined, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ]),
                                const SizedBox(height: 8),
                                Expanded(child: TextField(
                                  controller: _notesCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Add remarks (optional)...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                  maxLines: 3,
                                  onChanged: sp.setNotes,
                                )),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ════════ RIGHT SIDEBAR ════════
              SizedBox(
                width: 320,
                child: Column(children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(children: [
                        // ── Order Summary ──
                        Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.receipt_long, size: 20, color: blue),
                          const SizedBox(width: 8),
                          const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 16),
                        _summaryRow('Sub Total', '₹ ${sp.subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _summaryRow('Discount', '₹ ${sp.discount.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        if (sp.isIgst)
                          _summaryRow('Tax (IGST)', '₹ ${sp.totalTax.toStringAsFixed(2)}')
                        else ...[
                          _summaryRow('CGST', '₹ ${(sp.totalTax / 2).toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _summaryRow('SGST', '₹ ${(sp.totalTax / 2).toStringAsFixed(2)}'),
                        ],
                        if (sp.totalTinting > 0) ...[
                          const SizedBox(height: 8),
                          _summaryRow('Tinting', '₹ ${sp.totalTinting.toStringAsFixed(2)}'),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E7D32), fontSize: 14)),
                            Text('₹ ${sp.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0), fontSize: 18)),
                          ]),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Payment Method ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.payment, size: 20, color: blue),
                          const SizedBox(width: 8),
                          const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 8),
                        ...['Cash', 'UPI', 'Card', 'Wallet', 'Cheque'].map((method) {
                          IconData icon;
                          switch (method) {
                            case 'Cash': icon = Icons.money; break;
                            case 'UPI': icon = Icons.account_balance; break;
                            case 'Card': icon = Icons.credit_card; break;
                            case 'Wallet': icon = Icons.account_balance_wallet; break;
                            case 'Cheque': icon = Icons.description; break;
                            default: icon = Icons.payment;
                          }
                          return RadioListTile<String>(
                            value: method,
                            groupValue: _paymentMethod,
                            onChanged: (v) => setState(() => _paymentMethod = v!),
                            title: Row(children: [
                              Icon(icon, size: 18, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text(method, style: const TextStyle(fontSize: 14)),
                            ]),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            activeColor: blue,
                          );
                        }),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Tax toggles ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Column(children: [
                        CheckboxListTile(
                          title: const Text('Include GST / Tax', style: TextStyle(fontSize: 13)),
                          value: sp.applyTax,
                          onChanged: (val) { if (val != null) sp.toggleApplyTax(val); },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: blue,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Inter-state Sale (IGST)', style: TextStyle(fontSize: 13)),
                          value: sp.isIgst,
                          onChanged: (v) => sp.setIsIgst(v),
                          dense: true,
                        ),
                      ]),
                    ),
                  ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Complete Sale button ──
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: sp.currentItems.isEmpty ? null : () {
                        if (sp.customerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A customer must be selected to proceed to checkout.'), backgroundColor: Colors.red));
                          return;
                        }
                        _showCheckoutDialog(sp);
                      },
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Complete Sale', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(backgroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.info_outline, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('Invoice will be generated after payment', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ])),
                  const SizedBox(height: 8),

                  // ── Hold + UPI + WhatsApp row ──
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: sp.currentItems.isEmpty ? null : () async {
                        if (sp.customerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A customer must be selected to put an order on Hold.'), backgroundColor: Colors.red));
                          return;
                        }
                        final ok = await sp.createSale(status: 'hold');
                        if (ok && mounted) { setState(() => _creating = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed on Hold! Stock reserved.'), backgroundColor: Colors.orange)); }
                      },
                      icon: const Icon(Icons.pause, size: 16),
                      label: const Text('Hold', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.orange[800], side: BorderSide(color: Colors.orange[300]!), visualDensity: VisualDensity.compact),
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () {
                        if (settings.upiId.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set UPI ID in Settings'))); return; }
                        final upiString = 'upi://pay?pa=${settings.upiId}&pn=${settings.businessName}&am=${sp.grandTotal.toStringAsFixed(2)}&cu=INR';
                        showDialog(context: context, builder: (ctx) => AlertDialog(
                          title: const Text('UPI QR Code'),
                          content: SizedBox(width: 250, height: 250, child: QrImageView(data: upiString, size: 250)),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                        ));
                      },
                      icon: const Icon(Icons.qr_code, size: 16),
                      label: const Text('UPI QR', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () async {
                        final customer = sp.customerId != null ? customers.firstWhere((c) => c.id == sp.customerId, orElse: () => Customer(name: '')) : null;
                        if (customer == null || customer.phone == null || customer.phone!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer phone number not available')));
                          return;
                        }
                        final msg = 'Hello ${customer.name}, your bill of ₹${sp.grandTotal.toStringAsFixed(2)} at ${settings.businessName} is ready.';
                        final url = 'https://wa.me/91${customer.phone}?text=${Uri.encodeComponent(msg)}';
                        try { await launchUrl(Uri.parse(url)); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open WhatsApp: $e'))); }
                      },
                      icon: const Icon(Icons.message, size: 16),
                      label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    )),
                  ]),
                  const SizedBox(height: 8),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
  void _showTintingDialog(SaleProvider sp, ProductVariant v) {
    final shadeCodeCtrl = TextEditingController();
    final shadeNameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final tintChargeCtrl = TextEditingController(text: '0');
    bool isFetching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Text('🎨', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text('Machine Tinting'),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${v.sellingPrice.toStringAsFixed(2)} per unit | Stock: ${((v.stockQty ?? 0) == (v.stockQty ?? 0).toInt() ? (v.stockQty ?? 0).toInt().toString() : (v.stockQty ?? 0).toString())}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: shadeCodeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Shade Code *',
                          hintText: 'e.g., 7977',
                          prefixIcon: isFetching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.tag),
                        ),
                        autofocus: true,
                        onChanged: (code) async {
                          if (code.length >= 2 &&
                              v.brandId != null &&
                              v.packSize != null) {
                            setDlgState(() => isFetching = true);
                            final saved = await context
                                .read<ProductProvider>()
                                .getShadePrice(v.brandId!, code, v.packSize!);
                            if (saved != null && mounted) {
                              shadeNameCtrl.text =
                                  saved['shade_name'] as String? ?? '';
                              tintChargeCtrl.text =
                                  (saved['price'] as num?)?.toStringAsFixed(
                                    0,
                                  ) ??
                                  '0';
                            }
                            setDlgState(() => isFetching = false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: shadeNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Shade Name',
                          hintText: 'e.g., Autumn Leaf',
                          prefixIcon: Icon(Icons.palette_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: tintChargeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tinting Charge ₹',
                          prefixText: '₹ ',
                          prefixIcon: Icon(Icons.paid_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () {
                double qty = double.tryParse(qtyCtrl.text) ?? 1;
                sp.addItem(v, qty);
                Navigator.pop(ctx, true);
              },
              child: const Text('Add Base Only'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange[700],
              ),
              onPressed: () {
                if (shadeCodeCtrl.text.isEmpty || shadeNameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter Shade Code and Name, or click "Add Base Only"',
                      ),
                    ),
                  );
                  return;
                }
                double qty = double.tryParse(qtyCtrl.text) ?? 1;
                double tintCharge = double.tryParse(tintChargeCtrl.text) ?? 0;
                if (v.brandId != null && v.packSize != null) {
                  context.read<ProductProvider>().saveShadePrice(
                    v.brandId!,
                    shadeCodeCtrl.text,
                    shadeNameCtrl.text,
                    v.packSize!,
                    tintCharge,
                  );
                }
                sp.addItem(
                  v,
                  qty,
                  shadeCode: shadeCodeCtrl.text,
                  shadeName: shadeNameCtrl.text,
                  tintingCharge: tintCharge,
                );
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.palette, size: 18),
              label: const Text('Add Tinted Item'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBatchSelectionDialog(
    SaleProvider sp,
    List<ProductVariant> batches,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: Color(0xFF1E88E5)),
            const SizedBox(width: 8),
            Text('Select Batch: ${batches.first.productName}'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: batches.map((b) {
              double inCart = sp.currentItems
                  .where((i) => i.productVariantId == b.id)
                  .fold(0.0, (s, i) => s + i.quantity);
              double remaining = (b.stockQty ?? 0) - inCart;
              bool outOfStock = remaining <= 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    'MRP: ₹${b.mrp?.toStringAsFixed(2) ?? "-"} | Cost: ₹${b.purchasePrice.toStringAsFixed(2)} | Selling: ₹${b.sellingPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Current Stock: ${remaining.toStringAsFixed(0)} units',
                    style: TextStyle(
                      color: outOfStock ? Colors.red : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: FilledButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Select'),
                    style: FilledButton.styleFrom(
                      backgroundColor: outOfStock ? Colors.grey : null,
                    ),
                    onPressed: outOfStock
                        ? null
                        : () {
                            Navigator.pop(ctx, true);
                            if (b.isTintable) {
                              _showTintingDialog(sp, b);
                            } else {
                              sp.addItem(b, 1);
                            }
                          },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontSize: bold ? 18 : 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _payStatusCard(
    String title,
    String value,
    String current,
    Function(String) onTap,
  ) {
    bool sel = current == value;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: sel ? Colors.blue[600] : Colors.white,
            border: Border.all(
              color: sel ? Colors.blue[600]! : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: sel ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _payMethodCard(
    String method,
    IconData icon,
    String current,
    Function(String) onTap,
  ) {
    bool sel = current == method;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(method),
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: sel ? Colors.green[50] : Colors.white,
            border: Border.all(
              color: sel ? Colors.green[600]! : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: sel ? Colors.green[700] : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                method,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: sel ? Colors.green[800] : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showCustomerSelectionDialog(
    BuildContext context,
    SaleProvider sp,
  ) async {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    List<Customer> matches = [];
    bool searched = false;
    bool creating = false; String? newState;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final allCustomers = context.watch<CustomerProvider>().customers;

            void doSearch(String query) {
              if (query.trim().length < 2) {
                setState(() {
                  matches = [];
                  searched = false;
                  creating = false;
                });
                return;
              }
              final q = query.trim().toLowerCase();
              setState(() {
                matches = allCustomers.where((c) {
                  final nameMatch = c.name.toLowerCase().contains(q);
                  final phoneMatch = c.phone != null && c.phone!.contains(q);
                  return nameMatch || phoneMatch;
                }).toList();
                searched = true;
                creating = false;
              });
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.person_search, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Customer Lookup'),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: phoneCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Enter Phone Number or Name',
                        hintText: 'e.g. 9876543210 or Rahul',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: phoneCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  phoneCtrl.clear();
                                  setState(() {
                                    matches = [];
                                    searched = false;
                                    creating = false;
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: doSearch,
                    ),

                    // Show matching customers
                    if (searched && matches.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${matches.length} customer(s) found:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: matches.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = matches[i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  c.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(c.phone ?? 'No phone'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () {
                                sp.setCustomer(c, businessState: context.read<SettingsProvider>().businessState);
                                Navigator.pop(ctx, true);
                              },
                            );
                          },
                        ),
                      ),
                    ],

                    // No match found — offer to create
                    if (searched && matches.isEmpty && !creating) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'No customer found. Create new?',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () {
                                // Pre-fill: if they typed a number, put it in phone; if text, put it in name
                                final input = phoneCtrl.text.trim();
                                final isPhone = RegExp(r'^\d{5,}$').hasMatch(input);
                                if (isPhone) {
                                  nameCtrl.clear();
                                } else {
                                  nameCtrl.text = input;
                                  phoneCtrl.clear();
                                }
                                setState(() => creating = true);
                              },
                              child: const Text('+ New Customer'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // New customer form
                    if (creating) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'New Customer Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name *',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map_outlined), border: OutlineInputBorder()),
                        value: newState,
                        items: ['Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Chandigarh', 'Puducherry', 'Lakshadweep', 'Andaman & Nicobar Islands', 'Dadra & Nagar Haveli and Daman & Diu'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) {
                          setState(() => newState = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Save & Start Billing'),
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Both Name and Phone are required')),
                              );
                              return;
                            }
                            try {
                              final newCust = Customer(
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                state: newState,
                              );
                              final ok = await context.read<CustomerProvider>().add(newCust);
                              if (ok && ctx.mounted) {
                                final customers = ctx.read<CustomerProvider>().customers;
                                final created = customers.firstWhere(
                                  (c) => c.name == newCust.name && c.phone == newCust.phone,
                                  orElse: () => customers.last,
                                );
                                sp.setCustomer(created, businessState: context.read<SettingsProvider>().businessState);
                                Navigator.pop(ctx, true);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

    Future<bool?> _showQuickAddCustomerDialog(
    BuildContext context,
    SaleProvider sp,
  ) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? state;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Quick Add Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number *'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'State'),
                value: state,
                items: ['Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Chandigarh', 'Puducherry', 'Lakshadweep', 'Andaman & Nicobar Islands', 'Dadra & Nagar Haveli and Daman & Diu'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setDlgState(() => state = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty)
                  return;
                try {
                  final newCust = Customer(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    state: state,
                  );
                  final ok = await context.read<CustomerProvider>().add(newCust);
                  if (ok) {
                    if (ctx.mounted) {
                      final customers = ctx.read<CustomerProvider>().customers;
                      final created = customers.firstWhere(
                        (c) => c.name == newCust.name && c.phone == newCust.phone,
                        orElse: () => customers.last,
                      );
                      sp.setCustomer(created, businessState: context.read<SettingsProvider>().businessState);
                      Navigator.pop(ctx, true);
                    }
                  }
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save & Select'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutDialog(SaleProvider sp) {
    String paymentStatus = 'paid';
    String paymentMethod = 'Cash';
    final amountPaidCtrl = TextEditingController(
      text: sp.grandTotal.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: AppBar(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            title: const Text(
              'Checkout',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: StatefulBuilder(
            builder: (ctx, setDlgState) {
              double amountPaid = double.tryParse(amountPaidCtrl.text) ?? 0.0;
              double remaining = sp.grandTotal - amountPaid;

              return Row(
                children: [
                  // LEFT: RECEIPT
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'ORDER SUMMARY',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(thickness: 2),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) => SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: DataTable(
                                      headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                      dataRowMinHeight: 60,
                                      dataRowMaxHeight: 60,
                                      columns: const [
                                        DataColumn(label: Text('Product')),
                                        DataColumn(
                                          label: Text('Qty'),
                                          numeric: true,
                                        ),
                                        DataColumn(
                                          label: Text('Base Price'),
                                          numeric: true,
                                        ),
                                        DataColumn(
                                          label: Text('Tax (GST)'),
                                          numeric: true,
                                        ),
                                        DataColumn(
                                          label: Text('Tinting'),
                                          numeric: true,
                                        ),
                                        DataColumn(
                                          label: Text('Amount'),
                                          numeric: true,
                                        ),
                                      ],
                                      rows: sp.currentItems
                                          .map(
                                            (item) => DataRow(
                                              cells: [
                                                DataCell(
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        item.productName ?? '-',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (item.isTinted)
                                                        Text(
                                                          '🎨 ${item.shadeCode}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .orange[800],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    item.quantity ==
                                                            item.quantity
                                                                .toInt()
                                                        ? item.quantity
                                                              .toInt()
                                                              .toString()
                                                        : item.quantity
                                                              .toString(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    '₹${item.price.toStringAsFixed(2)}',
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    '₹${item.tax.toStringAsFixed(2)}',
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    item.tintingCharge > 0
                                                        ? '₹${item.tintingCharge.toStringAsFixed(2)}'
                                                        : '-',
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    '₹${item.amount.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Divider(thickness: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _summaryRow(
                                      'Subtotal',
                                      '₹${sp.subtotal.toStringAsFixed(2)}',
                                    ),
                                    const SizedBox(height: 4),
                                    _summaryRow(
                                      'Total Tax',
                                      '₹${sp.totalTax.toStringAsFixed(2)}',
                                    ),
                                    if (sp.totalTinting > 0) ...[
                                      const SizedBox(height: 4),
                                      _summaryRow(
                                        'Total Tinting',
                                        '₹${sp.totalTinting.toStringAsFixed(2)}',
                                      ),
                                    ],
                                    if (sp.discount > 0) ...[
                                      const SizedBox(height: 4),
                                      _summaryRow(
                                        'Discount',
                                        '-₹${sp.discount.toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'GRAND TOTAL',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        '₹${sp.grandTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT: PAYMENT CONTROLS
                  Container(
                    width: 500,
                    margin: const EdgeInsets.only(
                      top: 16,
                      bottom: 16,
                      right: 16,
                    ),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Amount Due',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '₹${sp.grandTotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ToggleButtons(
                                            isSelected: [
                                              !sp.isDiscountPercent,
                                              sp.isDiscountPercent,
                                            ],
                                            onPressed: (idx) {
                                              sp.setDiscountType(idx == 1);
                                              if (paymentStatus == 'paid')
                                                amountPaidCtrl.text = sp
                                                    .grandTotal
                                                    .toStringAsFixed(2);
                                              setDlgState(() {});
                                            },
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            constraints: const BoxConstraints(
                                              minHeight: 52,
                                              minWidth: 40,
                                            ),
                                            children: const [
                                              Text(
                                                '₹',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              Text(
                                                '%',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: TextField(
                                              controller:
                                                  TextEditingController(
                                                      text: sp.discount > 0
                                                          ? sp.discount
                                                                .toStringAsFixed(
                                                                  sp.isDiscountPercent
                                                                      ? 1
                                                                      : 0,
                                                                )
                                                          : '',
                                                    )
                                                    ..selection =
                                                        TextSelection.collapsed(
                                                          offset:
                                                              sp.discount > 0
                                                              ? sp.discount
                                                                    .toStringAsFixed(
                                                                      sp.isDiscountPercent
                                                                          ? 1
                                                                          : 0,
                                                                    )
                                                                    .length
                                                              : 0,
                                                        ),
                                              decoration: InputDecoration(
                                                labelText: 'Discount',
                                                border:
                                                    const OutlineInputBorder(),
                                                prefixText: sp.isDiscountPercent
                                                    ? ''
                                                    : '₹ ',
                                                suffixText: sp.isDiscountPercent
                                                    ? '%'
                                                    : '',
                                              ),
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              onChanged: (v) {
                                                sp.setDiscount(
                                                  double.tryParse(v) ?? 0,
                                                );
                                                if (paymentStatus == 'paid') {
                                                  amountPaidCtrl.text = sp
                                                      .grandTotal
                                                      .toStringAsFixed(2);
                                                }
                                                setDlgState(() {});
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                const Text(
                                  'Payment Status',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _payStatusCard(
                                      'Completely Pay',
                                      'paid',
                                      paymentStatus,
                                      (v) => setDlgState(() {
                                        paymentStatus = v;
                                        amountPaidCtrl.text = sp.grandTotal
                                            .toStringAsFixed(2);
                                      }),
                                    ),
                                    _payStatusCard(
                                      'Partially Pay',
                                      'partial',
                                      paymentStatus,
                                      (v) => setDlgState(() {
                                        paymentStatus = v;
                                      }),
                                    ),
                                    _payStatusCard(
                                      'Pay Later (Udhar)',
                                      'unpaid',
                                      paymentStatus,
                                      (v) => setDlgState(() {
                                        paymentStatus = v;
                                        amountPaidCtrl.text = '0.00';
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                if (paymentStatus != 'unpaid') ...[
                                  const Text(
                                    'Payment Method',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _payMethodCard(
                                        'Cash',
                                        Icons.money,
                                        paymentMethod,
                                        (v) => setDlgState(
                                          () => paymentMethod = v,
                                        ),
                                      ),
                                      _payMethodCard(
                                        'UPI',
                                        Icons.qr_code,
                                        paymentMethod,
                                        (v) => setDlgState(
                                          () => paymentMethod = v,
                                        ),
                                      ),
                                      _payMethodCard(
                                        'Card',
                                        Icons.credit_card,
                                        paymentMethod,
                                        (v) => setDlgState(
                                          () => paymentMethod = v,
                                        ),
                                      ),
                                      _payMethodCard(
                                        'Bank',
                                        Icons.account_balance,
                                        paymentMethod,
                                        (v) => setDlgState(
                                          () => paymentMethod = v,
                                        ),
                                      ),
                                      _payMethodCard(
                                        'Credit',
                                        Icons.store,
                                        paymentMethod,
                                        (v) => setDlgState(
                                          () => paymentMethod = v,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                ],

                                if (paymentStatus == 'partial') ...[
                                  const Text(
                                    'Amount Received (₹)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: amountPaidCtrl,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      prefixText: '₹ ',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 20,
                                          ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (v) => setDlgState(() {}),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: remaining > 0
                                          ? Colors.red[50]
                                          : Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          remaining > 0
                                              ? 'Balance Due:'
                                              : 'Change to Return:',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: remaining > 0
                                                ? Colors.red[800]
                                                : Colors.green[800],
                                          ),
                                        ),
                                        Text(
                                          '₹${remaining.abs().toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: remaining > 0
                                                ? Colors.red[800]
                                                : Colors.green[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (sp.customerId == null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red[700],
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'A customer must be selected to process a sale. Please close this dialog, select or add a Customer on the main screen, and try again.',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Builder(
                          builder: (context) {
                            final customers = context
                                .read<CustomerProvider>()
                                .customers;
                            final selectedCustomer = sp.customerId != null
                                ? customers.firstWhere(
                                    (c) => c.id == sp.customerId,
                                    orElse: () => Customer(name: ''),
                                  )
                                : null;
                            final bool missingContact =
                                (paymentStatus == 'partial' ||
                                    paymentStatus == 'unpaid') &&
                                selectedCustomer != null &&
                                (selectedCustomer.phone == null ||
                                    selectedCustomer.phone!.trim().isEmpty ||
                                    selectedCustomer.address == null ||
                                    selectedCustomer.address!.trim().isEmpty);
                            final bool blockSale =
                                sp.customerId == null || missingContact;

                            return Column(
                              children: [
                                if (missingContact)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.contact_phone,
                                          color: Colors.red[700],
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Udhar / Partial payments require the Customer to have both a Phone Number and an Address saved. Please go to Customers tab and update their profile first.',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 70,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: blockSale
                                          ? Colors.grey
                                          : Colors.green[700],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: blockSale
                                        ? null
                                        : () async {
                                            sp.setPaymentStatus(paymentStatus);
                                            if (paymentStatus != 'unpaid')
                                              sp.setPaymentMethod(
                                                paymentMethod,
                                              );
                                            double finalPaid =
                                                paymentStatus == 'paid'
                                                ? sp.grandTotal
                                                : (paymentStatus == 'unpaid'
                                                      ? 0.0
                                                      : amountPaid);

                                            final ok = await sp.createSale(
                                              status: 'completed',
                                              amountPaid: finalPaid,
                                            );
                                            if (ok && mounted) {
                                              Navigator.pop(ctx, true);
                                              setState(() => _creating = false);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Sale completed successfully!',
                                                  ),
                                                  backgroundColor: Color(
                                                    0xFF43A047,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 32,
                                    ),
                                    label: const Text(
                                      'COMPLETE SALE',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSaleDetails(SaleProvider sp, int saleId) async {
    final sale = await sp.getSaleDetails(saleId);
    if (sale == null) return;

    bool showGstInPrint = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFF1E88E5)),
              const SizedBox(width: 8),
              Text('Invoice ${sale.invoiceNumber}'),
              const Spacer(),
              StatusBadge(status: sale.paymentStatus),
            ],
          ),
          content: SizedBox(
            width: 900,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer: ${sale.customerName ?? "Walk-in"}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(sale.saleDate)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Payment: ${sale.paymentMethod}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Items
                  const Text(
                    'Items',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (sale.items != null && sale.items!.isNotEmpty)
                    Builder(
                      builder: (ctx) {
                        bool hasTax = sale.tax > 0 && showGstInPrint;
                        bool isIgst = sale.isIgst;

                        List<DataColumn> cols = [
                          const DataColumn(label: Text('Product')),
                          const DataColumn(label: Text('Qty'), numeric: true),
                          const DataColumn(
                            label: Text('Unit Base'),
                            numeric: true,
                          ),
                          const DataColumn(
                            label: Text('Base Tot'),
                            numeric: true,
                          ),
                        ];

                        if (hasTax) {
                          if (isIgst) {
                            cols.add(
                              const DataColumn(
                                label: Text('IGST'),
                                numeric: true,
                              ),
                            );
                          } else {
                            cols.addAll([
                              const DataColumn(
                                label: Text('CGST'),
                                numeric: true,
                              ),
                              const DataColumn(
                                label: Text('SGST'),
                                numeric: true,
                              ),
                            ]);
                          }
                        }
                        cols.add(
                          const DataColumn(label: Text('Final'), numeric: true),
                        );

                        return SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            dataRowMaxHeight: double.infinity,
                            columns: cols,
                            rows: sale.items!.map((i) {
                              final tintingPerUnit =
                                  i.tintingCharge /
                                  (i.quantity > 0 ? i.quantity : 1);

                              final basePrice = i.price + tintingPerUnit;
                              final baseAmount =
                                  (i.price * i.quantity) +
                                  i.tintingCharge -
                                  i.discount;
                              final finalAmount = baseAmount + i.tax;

                              double taxPct = baseAmount > 0
                                  ? (i.tax / baseAmount * 100)
                                  : 0;

                              String name =
                                  i.productName ?? i.variantSku ?? '-';
                              if (i.variantName != null &&
                                  i.variantName!.isNotEmpty) {
                                name += ' - ${i.variantName}';
                              }
                              if (i.packSize != null && i.unitSymbol != null) {
                                name +=
                                    ' (${i.packSize!.toStringAsFixed(i.packSize! == i.packSize!.toInt() ? 0 : 2)} ${i.unitSymbol})';
                              }
                              if (i.isTinted)
                                name += '\n(Shade: ${i.shadeCode ?? "Custom"})';
                              if (i.discount > 0)
                                name +=
                                    '\n(Disc: -₹${i.discount.toStringAsFixed(2)})';

                              List<DataCell> cells = [
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    i.quantity == i.quantity.toInt()
                                        ? i.quantity.toInt().toString()
                                        : i.quantity.toString(),
                                  ),
                                ),
                                DataCell(
                                  Text('₹${basePrice.toStringAsFixed(2)}'),
                                ),
                                DataCell(
                                  Text('₹${baseAmount.toStringAsFixed(2)}'),
                                ),
                              ];

                              if (hasTax) {
                                if (isIgst) {
                                  cells.add(
                                    DataCell(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          '${taxPct.toStringAsFixed(2)}%\n₹${i.tax.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  cells.addAll([
                                    DataCell(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          '${(taxPct / 2).toStringAsFixed(1)}%\n₹${(i.tax / 2).toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          '${(taxPct / 2).toStringAsFixed(1)}%\n₹${(i.tax / 2).toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]);
                                }
                              }
                              cells.add(
                                DataCell(
                                  Text(
                                    '₹${finalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );

                              return DataRow(cells: cells);
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  const Divider(height: 24),
                  Builder(
                    builder: (ctx) {
                      final totalTinting =
                          sale.items?.fold(
                            0.0,
                            (sum, i) => sum + i.tintingCharge,
                          ) ??
                          0.0;
                      return Column(
                        children: [
                          _summaryRow(
                            showGstInPrint ? 'Subtotal' : 'Gross Total',
                            '₹${(sale.subtotal + (showGstInPrint ? 0 : sale.tax)).toStringAsFixed(2)}',
                          ),
                          if (totalTinting > 0) ...[
                            const SizedBox(height: 4),
                            _summaryRow(
                              'Tinting Charges',
                              '₹${totalTinting.toStringAsFixed(2)}',
                            ),
                          ],
                          const SizedBox(height: 4),
                          if (sale.tax > 0 && showGstInPrint) ...[
                            if (sale.isIgst)
                              _summaryRow(
                                'IGST',
                                '₹${sale.tax.toStringAsFixed(2)}',
                              )
                            else ...[
                              _summaryRow(
                                'CGST',
                                '₹${(sale.tax / 2).toStringAsFixed(2)}',
                              ),
                              const SizedBox(height: 4),
                              _summaryRow(
                                'SGST',
                                '₹${(sale.tax / 2).toStringAsFixed(2)}',
                              ),
                            ],
                          ],
                          if (sale.discount > 0) ...[
                            const SizedBox(height: 4),
                            _summaryRow(
                              'Discount',
                              '- ₹${sale.discount.toStringAsFixed(2)}',
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  _summaryRow(
                    'Total Amount',
                    '₹${sale.totalAmount.toStringAsFixed(2)}',
                    bold: true,
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final totalCost =
                          sale.items?.fold(
                            0.0,
                            (sum, i) =>
                                sum +
                                ((i.costPrice > 0
                                        ? i.costPrice
                                        : (i.amount / i.quantity)) *
                                    i.quantity),
                          ) ??
                          0.0;
                      final netRevenue = sale.totalAmount - sale.tax;
                      final grossProfit = netRevenue - totalCost;
                      final margin = netRevenue > 0
                          ? (grossProfit / netRevenue) * 100
                          : 0.0;
                      if (totalCost == 0 || grossProfit <= 0)
                        return const SizedBox.shrink(); // Don't show if cost wasn't properly tracked yet
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Internal Gross Profit (Hidden from Customer)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '₹${grossProfit.toStringAsFixed(2)} (${margin.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (sale.returnedAmount > 0) ...[
                    const SizedBox(height: 12),
                    _summaryRow(
                      'Returned (Refunded)',
                      '-₹${sale.returnedAmount.toStringAsFixed(2)}',
                      color: Colors.red,
                    ),
                    const Divider(height: 16),
                    _summaryRow(
                      'Net Final Sale',
                      '₹${(sale.totalAmount - sale.returnedAmount).toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                  if (sale.returnLogs != null &&
                      sale.returnLogs!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Return Timeline',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sale.returnLogs!.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final log = sale.returnLogs![i];
                          final item = sale.items?.firstWhere(
                            (element) => element.id == log.saleItemId,
                            orElse: () => SaleItem(
                              productVariantId: 0,
                              quantity: 0,
                              price: 0,
                              amount: 0,
                              productName: 'Unknown',
                            ),
                          );
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.keyboard_return,
                              color: Colors.purple,
                              size: 18,
                            ),
                            title: Text(
                              '${item?.productName ?? "Item"} - ${log.quantity == log.quantity.toInt() ? log.quantity.toInt().toString() : log.quantity.toString()} returned',
                            ),
                            subtitle: Text(
                              DateFormat(
                                'dd MMM yyyy, hh:mm a',
                              ).format(log.returnDate),
                            ),
                            trailing: Text(
                              '-₹${log.refundAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (sale.paymentStatus == 'partial' ||
                      sale.paymentStatus == 'unpaid') ...[
                    const SizedBox(height: 4),
                    _summaryRow(
                      'Amount Paid',
                      '₹${sale.amountPaid.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 16),
                    _summaryRow(
                      'Balance Due',
                      '₹${(sale.totalAmount - sale.amountPaid).toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                  if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Notes: ${sale.notes}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'Show GST breakdown in printed bill',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: showGstInPrint,
                      onChanged: (v) =>
                          setDlgState(() => showGstInPrint = v ?? true),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (sale.paymentStatus != 'refunded')
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx, true);
                  _showReturnSaleDialog(sp, sale);
                },
                icon: const Icon(
                  Icons.keyboard_return,
                  size: 18,
                  color: Colors.purple,
                ),
                label: const Text(
                  'Process Return',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx, true);
                _printThermalReceipt(sp, saleId, showGst: showGstInPrint);
              },
              icon: const Icon(
                Icons.receipt_long,
                size: 18,
                color: Colors.blueGrey,
              ),
              label: const Text(
                'Print Thermal',
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx, true);
                _printInvoice(sp, saleId, showGst: showGstInPrint);
              },
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Print A4 Invoice'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReturnSaleDialog(SaleProvider sp, Sale sale) {
    // Map of sale_item.id -> returned quantity
    Map<int, double> returnMap = {};
    for (final item in sale.items!) {
      returnMap[item.id!] = 0;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.keyboard_return_rounded, color: Colors.purple),
              const SizedBox(width: 8),
              Text('Return Items for Invoice ${sale.invoiceNumber}'),
            ],
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Specify the quantity being returned for each item. This will restock the inventory and calculate the refund.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowHeight: 40,
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 60,
                      columns: const [
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Purchased')),
                        DataColumn(label: Text('Returned')),
                        DataColumn(label: Text('Return Now')),
                      ],
                      rows: sale.items!.map((i) {
                        double remaining = i.quantity - i.returnedQuantity;
                        return DataRow(
                          cells: [
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Builder(
                                    builder: (context) {
                                      String name = i.productName ?? '-';
                                      if (i.variantName != null &&
                                          i.variantName!.isNotEmpty) {
                                        name += ' - ${i.variantName}';
                                      }
                                      if (i.packSize != null &&
                                          i.unitSymbol != null) {
                                        name +=
                                            ' (${i.packSize!.toStringAsFixed(i.packSize! == i.packSize!.toInt() ? 0 : 2)} ${i.unitSymbol})';
                                      }
                                      return Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                  Text(
                                    '₹${i.effectivePricePerUnit.toStringAsFixed(2)}/unit',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                i.quantity == i.quantity.toInt()
                                    ? i.quantity.toInt().toString()
                                    : i.quantity.toString(),
                              ),
                            ),
                            DataCell(
                              Text(
                                i.returnedQuantity == i.returnedQuantity.toInt()
                                    ? i.returnedQuantity.toInt().toString()
                                    : i.returnedQuantity.toString(),
                                style: TextStyle(
                                  color: i.returnedQuantity > 0
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed:
                                        remaining > 0 && returnMap[i.id!]! > 0
                                        ? () => setDlgState(
                                            () => returnMap[i.id!] =
                                                returnMap[i.id!]! - 1,
                                          )
                                        : null,
                                  ),
                                  Text(
                                    returnMap[i.id!]!.toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: returnMap[i.id!]! < remaining
                                        ? () => setDlgState(
                                            () => returnMap[i.id!] =
                                                returnMap[i.id!]! + 1,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 32),
                  Builder(
                    builder: (context) {
                      double refund = 0;
                      for (final i in sale.items!) {
                        refund += i.effectivePricePerUnit * returnMap[i.id!]!;
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Refund Amount:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${refund.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () async {
                bool hasReturns = returnMap.values.any((q) => q > 0);
                if (!hasReturns) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please select at least one item to return.',
                      ),
                    ),
                  );
                  return;
                }
                if (sale.id != null) {
                  final ok = await sp.processReturn(sale.id!, returnMap);
                  if (ok && mounted) {
                    Navigator.pop(ctx, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Return processed and stock updated successfully!',
                        ),
                        backgroundColor: Colors.purple,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirm Return'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReturnDialog(SaleProvider sp, Sale sale) {
    if (sale.items == null || sale.items!.isEmpty) return;

    // key: sale_item.id, value: quantity to return
    final returnMap = <int, double>{};
    for (var i in sale.items!) {
      returnMap[i.id!] = 0;
    }

    String refundMethod = 'Ledger Adjustment';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Process Return'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select quantities to return:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Purchased')),
                        DataColumn(label: Text('Returned')),
                        DataColumn(label: Text('Return Now')),
                      ],
                      rows: sale.items!.map((i) {
                        double remaining = i.quantity - i.returnedQuantity;
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                i.productName ?? '-',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            DataCell(
                              Text(
                                i.quantity == i.quantity.toInt()
                                    ? i.quantity.toInt().toString()
                                    : i.quantity.toString(),
                              ),
                            ),
                            DataCell(
                              Text(
                                i.returnedQuantity == i.returnedQuantity.toInt()
                                    ? i.returnedQuantity.toInt().toString()
                                    : i.returnedQuantity.toString(),
                                style: TextStyle(
                                  color: i.returnedQuantity > 0
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed:
                                        remaining > 0 && returnMap[i.id!]! > 0
                                        ? () => setDlgState(
                                            () => returnMap[i.id!] =
                                                returnMap[i.id!]! - 1,
                                          )
                                        : null,
                                  ),
                                  Text(
                                    returnMap[i.id!]!.toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: returnMap[i.id!]! < remaining
                                        ? () => setDlgState(
                                            () => returnMap[i.id!] =
                                                returnMap[i.id!]! + 1,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Refund Method',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: refundMethod,
                    decoration: const InputDecoration(isDense: true),
                    items: ['Ledger Adjustment', 'Cash', 'UPI', 'Bank Transfer']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDlgState(() => refundMethod = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      double refund = 0;
                      for (final i in sale.items!) {
                        refund += i.effectivePricePerUnit * returnMap[i.id!]!;
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Refund Amount:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${refund.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () async {
                bool hasReturns = returnMap.values.any((q) => q > 0);
                if (!hasReturns) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please select at least one item to return.',
                      ),
                    ),
                  );
                  return;
                }
                if (sale.id != null) {
                  final ok = await sp.processReturn(
                    sale.id!,
                    returnMap,
                    refundMethod: refundMethod,
                  );
                  if (ok && mounted) {
                    Navigator.pop(ctx, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Return processed successfully!'),
                        backgroundColor: Colors.purple,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirm Return'),
            ),
          ],
        ),
      ),
    );
  }

  void _printInvoice(SaleProvider sp, int saleId, {bool showGst = true}) async {
    final sale = await sp.getSaleDetails(saleId);
    if (sale == null) return;
    await PdfService().printInvoice(sale, showGst: showGst);
  }

  void _printThermalReceipt(
    SaleProvider sp,
    int saleId, {
    bool showGst = true,
  }) async {
    final sale = await sp.getSaleDetails(saleId);
    if (sale == null) return;
    final pdfBytes = await PdfService().generateThermalReceipt(
      sale,
      showGst: showGst,
    );
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'Receipt_${sale.invoiceNumber}',
    );
  }
}
