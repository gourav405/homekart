import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/supplier_ledger_provider.dart';

class SupplierLedgerScreen extends StatefulWidget {
  const SupplierLedgerScreen({super.key});

  @override
  State<SupplierLedgerScreen> createState() => _SupplierLedgerScreenState();
}

class _SupplierLedgerScreenState extends State<SupplierLedgerScreen> {
  int? _selectedSupplierId;
  String? _selectedSupplierName;
  double _selectedSupplierBalance = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierLedgerProvider>().loadBalances();
    });
  }

  void _selectSupplier(int id, String name, double balance) {
    setState(() {
      _selectedSupplierId = id;
      _selectedSupplierName = name;
      _selectedSupplierBalance = balance;
    });
    context.read<SupplierLedgerProvider>().loadSupplierDetails(id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Supplier Ledger', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Left: Supplier List
          Expanded(flex: 2, child: Card(
            child: Consumer<SupplierLedgerProvider>(builder: (ctx, lp, child) {
              if (lp.isLoading && lp.balances.isEmpty) return const Center(child: CircularProgressIndicator());
              if (lp.balances.isEmpty) return const Center(child: Text('No outstanding Udhar across any suppliers.'));
              
              return ListView.separated(
                itemCount: lp.balances.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final b = lp.balances[i];
                  final id = int.parse(b['id']!.toString());
                  final bal = double.parse((b['total_debt'] ?? 0).toString());
                  final isSelected = id == _selectedSupplierId;
                  
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.blue[50],
                    title: Text(b['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(b['phone'] ?? 'No Phone'),
                    trailing: Text('₹${bal.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[700])),
                    onTap: () => _selectSupplier(id, b['name'], bal),
                  );
                },
              );
            }),
          )),
          const SizedBox(width: 16),
          // Right: Supplier Details & Payment
          Expanded(flex: 3, child: Card(
            child: _selectedSupplierId == null 
              ? const Center(child: Text('Select a supplier to view ledger and receive payments.'))
              : Consumer<SupplierLedgerProvider>(builder: (ctx, lp, child) {
                  if (lp.isLoading) return const Center(child: CircularProgressIndicator());
                  
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_selectedSupplierName!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Total Outstanding: ₹${_selectedSupplierBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, color: Colors.red[700], fontWeight: FontWeight.w600)),
                        ]),
                        FilledButton.icon(
                          onPressed: _selectedSupplierBalance > 0 ? () => _showReceivePaymentDialog(context, _selectedSupplierId!, _selectedSupplierName!, _selectedSupplierBalance) : null,
                          icon: const Icon(Icons.payments),
                          label: const Text('Receive Payment'),
                          style: FilledButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                        ),
                      ]),
                      const Divider(height: 32),
                      const Text('Unpaid Invoices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(child: lp.unpaidInvoices.isEmpty 
                        ? const Center(child: Text('No unpaid invoices.'))
                        : ListView.builder(
                            itemCount: lp.unpaidInvoices.length,
                            itemBuilder: (c, i) {
                              final inv = lp.unpaidInvoices[i];
                              final totalAmount = double.parse(inv['total_amount'].toString());
                              final amountPaid = double.parse(inv['amount_paid'].toString());
                              final due = totalAmount - amountPaid;
                              final dt = DateTime.parse(inv['purchase_date']);
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.receipt_long, color: Colors.grey),
                                title: Text('Invoice ${inv['invoice_number']}'),
                                subtitle: Text(DateFormat('dd MMM yyyy').format(dt)),
                                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('Total: ₹${totalAmount.toStringAsFixed(2)}'),
                                  Text('Due: ₹${due.toStringAsFixed(0)}', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                                ]),
                              );
                            }
                          )
                      ),
                      const Divider(height: 32),
                      const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(child: lp.payments.isEmpty 
                        ? const Center(child: Text('No payments recorded.'))
                        : ListView.builder(
                            itemCount: lp.payments.length,
                            itemBuilder: (c, i) {
                              final p = lp.payments[i];
                              final dt = DateTime.parse(p['payment_date']);
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.check_circle, color: Colors.green[700]),
                                title: Text('Paid via ${p['payment_method']}'),
                                subtitle: Text('${DateFormat('dd MMM yyyy, hh:mm a').format(dt)} | ${p['notes'] ?? ''}'),
                                trailing: Text('₹${double.parse(p['amount'].toString()).toStringAsFixed(0)}', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 16)),
                              );
                            }
                          )
                      ),
                    ]),
                  );
                }),
          )),
        ])),
      ]),
    );
  }

  void _showReceivePaymentDialog(BuildContext context, int supplierId, String supplierName, double maxBalance) {
    final amtCtrl = TextEditingController(text: maxBalance.toStringAsFixed(0));
    final notesCtrl = TextEditingController();
    String method = 'Cash';
    bool saving = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
      return AlertDialog(
        title: Text('Receive Payment: $supplierName'),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: amtCtrl,
            decoration: const InputDecoration(labelText: 'Amount Received (₹)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: method,
            decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
            items: ['Cash', 'UPI', 'Bank Transfer', 'Cheque'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setDlgState(() => method = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesCtrl,
            decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text('This payment will automatically be applied to the oldest unpaid invoices first.', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
        ])),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving ? null : () async {
              final amt = double.tryParse(amtCtrl.text);
              if (amt == null || amt <= 0) return;
              
              setDlgState(() => saving = true);
              final ok = await context.read<SupplierLedgerProvider>().receivePayment(supplierId, amt, method, notesCtrl.text);
              if (ok && context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment successfully recorded!')));
                // refresh selected supplier balance from UI perspective
                final newBal = maxBalance - amt;
                setState(() => _selectedSupplierBalance = newBal > 0 ? newBal : 0);
              } else {
                setDlgState(() => saving = false);
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Payment'),
          ),
        ],
      );
    }));
  }
}
