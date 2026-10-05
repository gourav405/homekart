import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import "../models/purchase.dart";
import '../providers/purchase_provider.dart';
import '../providers/people_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_variant.dart';
import '../widgets/shared_widgets.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  bool _creating = false;
  final _searchCtrl = TextEditingController();
  final _invCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _varSearchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  List<ProductVariant> _searchResults = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<PurchaseProvider>().loadPurchases();
      context.read<SupplierProvider>().load();
      context.read<ProductProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseProvider>(
      builder: (ctx, pp, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: _creating ? _buildCreateView(pp) : _buildListView(pp),
        );
      },
    );
  }

  Widget _buildListView(PurchaseProvider pp) {
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
                    'Purchases',
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
                      '${pp.purchases.length}',
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
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () {
                        pp.clearPurchase();
                        setState(() => _creating = true);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Purchase'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: pp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : pp.purchases.isEmpty
              ? const EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'No purchases',
                  subtitle: 'Record your first purchase',
                )
              : Card(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Invoice #')),
                        DataColumn(label: Text('Supplier')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Total'), numeric: true),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: pp.purchases
                          .map(
                            (p) => DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    p.invoiceNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                DataCell(Text(p.supplierName ?? '-')),
                                DataCell(
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(p.purchaseDate),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '₹${p.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 18,
                                          color: Color(0xFF1E88E5),
                                        ),
                                        tooltip: 'View Details',
                                        onPressed: () =>
                                            _showPurchaseDetails(pp, p.id!),
                                      ),
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
                                              title: 'Delete Purchase',
                                              message:
                                                  'Stock will be adjusted. Continue?',
                                            ),
                                          );
                                          if (ok == true && p.id != null)
                                            pp.deletePurchase(p.id!);
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

  void _processReturn(
    PurchaseProvider pp,
    Purchase purchase,
    PurchaseItem item,
    BuildContext parentContext,
  ) {
    final qtyCtrl = TextEditingController(text: '1');
    String refundMethod = 'Ledger Adjustment';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Return to Supplier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Returning: ${item.productName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantity to return',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Refund Method',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: refundMethod,
                decoration: const InputDecoration(isDense: true),
                items: ['Ledger Adjustment', 'Cash', 'UPI', 'Bank Transfer']
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m, style: const TextStyle(fontSize: 14)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => refundMethod = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                double q = double.tryParse(qtyCtrl.text) ?? 0;
                double maxReturn = item.quantity - item.returnedQuantity;
                if (q <= 0 || q > maxReturn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Invalid quantity. Max allowed: $maxReturn',
                      ),
                    ),
                  );
                  return;
                }
                double returnAmount = q * item.purchasePrice;
                Navigator.pop(ctx);
                Navigator.pop(parentContext);
                final ok = await pp.processReturn(
                  purchase.id!,
                  item.id!,
                  q,
                  returnAmount,
                  refundMethod,
                );
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Return processed successfully.'),
                    ),
                  );
                  _showPurchaseDetails(pp, purchase.id!); // refresh
                }
              },
              child: const Text('Process Return'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseDetails(PurchaseProvider pp, int purchaseId) async {
    final purchase = await pp.getDetails(purchaseId);
    if (purchase == null || !mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.local_shipping_outlined, color: Color(0xFF1E88E5)),
            const SizedBox(width: 8),
            Text('Invoice ${purchase.invoiceNumber}'),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supplier: ${purchase.supplierName ?? "-"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Date: ${DateFormat('dd MMM yyyy').format(purchase.purchaseDate)}',
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
                // Items
                const Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (purchase.items != null && purchase.items!.isNotEmpty)
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Qty'), numeric: true),
                      DataColumn(label: Text('Price'), numeric: true),
                      DataColumn(label: Text('Amount'), numeric: true),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: purchase.items!.map((i) {
                      final qtyAvailable = i.quantity - i.returnedQuantity;
                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  i.productName ?? '-',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${i.packSize?.toStringAsFixed(i.packSize == i.packSize?.roundToDouble() ? 0 : 1) ?? ''}${i.unitSymbol ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              '${i.quantity == i.quantity.toInt() ? i.quantity.toInt().toString() : i.quantity.toString()} ${qtyAvailable < i.quantity ? "(-${i.returnedQuantity == i.returnedQuantity.toInt() ? i.returnedQuantity.toInt().toString() : i.returnedQuantity.toString()})" : ""}',
                            ),
                          ),
                          DataCell(
                            Text('₹${i.purchasePrice.toStringAsFixed(2)}'),
                          ),
                          DataCell(
                            Text(
                              '₹${i.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            qtyAvailable > 0
                                ? TextButton(
                                    onPressed: () =>
                                        _processReturn(pp, purchase, i, ctx),
                                    child: const Text(
                                      'Return',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  )
                                : const Text(
                                    'Returned',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${purchase.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                if (purchase.returnedAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Returned (Debit)',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '-₹${purchase.returnedAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Payable',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${(purchase.totalAmount - purchase.returnedAmount).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
                if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Notes',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    purchase.notes!,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _processAdd(ProductVariant v, PurchaseProvider pp) {
    double rawQty = double.tryParse(_qtyCtrl.text) ?? 1;
    double rawPrice = double.tryParse(_priceCtrl.text) ?? v.purchasePrice;

    void _doAdd(double q, double p) {
      pp.addItem(v, q, p);
      _varSearchCtrl.clear();
      _priceCtrl.clear();
      _qtyCtrl.text = '1';
      setState(() => _searchResults = []);
    }

    if (v.purchaseUnitId != null &&
        v.conversionFactor != null &&
        v.conversionFactor! > 1) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select Purchase Unit'),
          content: Text(
            'How did you purchase this item?\n\nBase Unit: ${v.unitSymbol}\nPurchase Unit: ${v.purchaseUnitSymbol} (${v.conversionFactor!.toStringAsFixed(0)} ${v.unitSymbol})',
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _doAdd(rawQty, rawPrice);
              },
              child: Text('${v.unitSymbol} (No Conversion)'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _doAdd(
                  rawQty * v.conversionFactor!,
                  rawPrice / v.conversionFactor!,
                );
              },
              child: Text(
                '${v.purchaseUnitSymbol} (x${v.conversionFactor!.toStringAsFixed(0)})',
              ),
            ),
          ],
        ),
      );
    } else {
      _doAdd(rawQty, rawPrice);
    }
  }

  void _showBatchSelectionDialog(
    PurchaseProvider pp,
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...batches.map((b) {
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
                        'Current Stock: ${(b.stockQty ?? 0).toStringAsFixed(0)} units',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: FilledButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Select'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _processAdd(b, pp);
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddNewBatchDialog(batches.first, pp);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Batch'),
                  ),
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
        ],
      ),
    );
  }

  void _showAddNewBatchDialog(ProductVariant baseVariant, PurchaseProvider pp) {
    final costCtrl = TextEditingController();
    final sellCtrl = TextEditingController(
      text: baseVariant.sellingPrice.toStringAsFixed(2),
    );
    final mrpCtrl = TextEditingController(
      text: baseVariant.mrp?.toStringAsFixed(2) ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Batch: ${baseVariant.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: costCtrl,
              decoration: const InputDecoration(
                labelText: 'Purchase Price (Cost) *',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sellCtrl,
              decoration: const InputDecoration(
                labelText: 'Selling Price *',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mrpCtrl,
              decoration: const InputDecoration(
                labelText: 'MRP',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              double? cost = double.tryParse(costCtrl.text);
              double? sell = double.tryParse(sellCtrl.text);
              double? mrp = double.tryParse(mrpCtrl.text);
              if (cost == null || sell == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cost and Selling price are required'),
                  ),
                );
                return;
              }
              final newV = ProductVariant(
                productId: baseVariant.productId,
                unitId: baseVariant.unitId,
                packSize: baseVariant.packSize,
                sku: baseVariant.sku,
                variantName: baseVariant.variantName,
                barcode: baseVariant.barcode,
                purchasePrice: cost,
                sellingPrice: sell,
                mrp: mrp,
                colorId: baseVariant.colorId,
                taxRateId: baseVariant.taxRateId,
                purchaseUnitId: baseVariant.purchaseUnitId,
                conversionFactor: baseVariant.conversionFactor,
                isActive: true,
                isTintable: baseVariant.isTintable,
                isTaxInclusive: baseVariant.isTaxInclusive,
              );
              Navigator.pop(ctx);
              bool ok = await context.read<ProductProvider>().addVariant(newV);
              if (ok && mounted) {
                // To fetch the full newly added variant with joins, we could just rely on variants list update
                // But a simple approach is to find it from the updated list
                await context.read<ProductProvider>().loadAll();
                final allV = context.read<ProductProvider>().variants;
                // Find the latest variant with same sku and purchasePrice
                try {
                  final added = allV.lastWhere(
                    (v) =>
                        v.sku == baseVariant.sku &&
                        v.purchasePrice == cost &&
                        v.sellingPrice == sell,
                  );
                  _processAdd(added, pp);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to auto-add batch to cart.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Create Batch'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateView(PurchaseProvider pp) {
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final allVariants = context.watch<ProductProvider>().variants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                pp.clearPurchase();
                setState(() => _creating = false);
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'New Purchase',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Supplier *',
                              prefixIcon: Icon(Icons.local_shipping_outlined),
                            ),
                            value: pp.supplierId,
                            items: suppliers
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                final s = suppliers.firstWhere(
                                  (s) => s.id == v,
                                );
                                pp.setSupplier(s.id!, s.name);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _invCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Invoice Number *',
                              prefixIcon: Icon(Icons.receipt_outlined),
                            ),
                            onChanged: pp.setInvoiceNumber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Variant search and add
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _varSearchCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Search variant...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onTap: () {
                              if (_varSearchCtrl.text.isEmpty) {
                                setState(() {
                                  _searchResults = allVariants.take(8).toList();
                                });
                              }
                            },
                            onChanged: (q) {
                              setState(() {
                                _searchResults = allVariants
                                    .where(
                                      (v) =>
                                          v.displayName.toLowerCase().contains(
                                            q.toLowerCase(),
                                          ) ||
                                          v.sku.toLowerCase().contains(
                                            q.toLowerCase(),
                                          ),
                                    )
                                    .take(8)
                                    .toList();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          width: 300,
                          child: TextField(
                            controller: _qtyCtrl,
                            decoration: const InputDecoration(labelText: 'Qty'),
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          width: 300,
                          child: TextField(
                            controller: _priceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Price ₹',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_searchResults.isNotEmpty)
                      Builder(
                        builder: (ctx) {
                          final groupedSearch =
                              <String, List<ProductVariant>>{};
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
                                    final totalStock = batches.fold<double>(
                                      0,
                                      (sum, b) => sum + (b.stockQty ?? 0),
                                    );
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        v.displayName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'SKU: ${v.sku} | Total Stock: $totalStock | Batches: ${batches.length}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: Color(0xFF1E88E5),
                                        ),
                                        onPressed: () {
                                          _varSearchCtrl.clear();
                                          setState(() => _searchResults = []);
                                          _showBatchSelectionDialog(
                                            pp,
                                            batches,
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: pp.currentItems.isEmpty
                          ? const EmptyState(
                              icon: Icons.inventory_outlined,
                              title: 'No items',
                              subtitle: 'Search and add variants',
                            )
                          : Card(
                              child: SizedBox(
                                width: double.infinity,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Product')),
                                    DataColumn(label: Text('Variant')),
                                    DataColumn(
                                      label: Text('Qty'),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text('Price'),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text('Amount'),
                                      numeric: true,
                                    ),
                                    DataColumn(label: Text('')),
                                  ],
                                  rows: pp.currentItems.asMap().entries.map((
                                    e,
                                  ) {
                                    final i = e.value;
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            i.productName ?? '-',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${i.packSize?.toStringAsFixed(i.packSize == i.packSize?.roundToDouble() ? 0 : 1) ?? ''}${i.unitSymbol ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
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
                                          Text(
                                            '₹${i.purchasePrice.toStringAsFixed(2)}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '₹${i.amount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove_circle_outline,
                                              size: 18,
                                              color: Colors.red[400],
                                            ),
                                            onPressed: () =>
                                                pp.removeItem(e.key),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right - Summary
              SizedBox(
                width: 280,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Items',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text('${pp.currentItems.length}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              '₹${pp.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _notesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            isDense: true,
                          ),
                          maxLines: 2,
                          onChanged: pp.setNotes,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Payment Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'paid', label: Text('Paid')),
                            ButtonSegment(
                              value: 'partial',
                              label: Text('Partial'),
                            ),
                            ButtonSegment(
                              value: 'unpaid',
                              label: Text('Udhar'),
                            ),
                          ],
                          selected: {pp.paymentStatus},
                          onSelectionChanged: (s) =>
                              pp.setPaymentStatus(s.first),
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            selectedBackgroundColor:
                                pp.paymentStatus == 'unpaid'
                                ? Colors.red[100]
                                : (pp.paymentStatus == 'partial'
                                      ? Colors.orange[100]
                                      : Colors.green[100]),
                          ),
                        ),
                        if (pp.paymentStatus != 'unpaid') ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Payment Method',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: pp.paymentMethod,
                            decoration: const InputDecoration(isDense: true),
                            items: ['Cash', 'UPI', 'Card', 'Bank Transfer']
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      m,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) pp.setPaymentMethod(v);
                            },
                          ),
                        ],
                        if (pp.paymentStatus == 'partial') ...[
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Amount Paid (₹)',
                              isDense: true,
                              prefixIcon: Icon(Icons.currency_rupee, size: 16),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (v) =>
                                pp.setAmountPaid(double.tryParse(v) ?? 0),
                          ),
                        ],
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed:
                                (pp.currentItems.isEmpty ||
                                    pp.supplierId == null)
                                ? null
                                : () async {
                                    final ok = await pp.createPurchase();
                                    if (ok && mounted) {
                                      setState(() => _creating = false);
                                      _invCtrl.clear();
                                      _notesCtrl.clear();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Purchase recorded!'),
                                          backgroundColor: Color(0xFF43A047),
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.check),
                            label: const Text('Save Purchase'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              pp.clearPurchase();
                              setState(() => _creating = false);
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
