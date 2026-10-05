import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import "../services/pdf_service.dart";
import "package:printing/printing.dart";
import '../providers/ledger_provider.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  int? _selectedCustomerId;
  String? _selectedCustomerName;
  double _selectedCustomerBalance = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().loadBalances();
    });
  }

  void _selectCustomer(int id, String name, double balance) {
    setState(() {
      _selectedCustomerId = id;
      _selectedCustomerName = name;
      _selectedCustomerBalance = balance;
    });
    context.read<LedgerProvider>().loadCustomerDetails(id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Customer Ledger', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Left: Customer List
          Expanded(flex: 2, child: Card(
            child: Consumer<LedgerProvider>(builder: (ctx, lp, child) {
              if (lp.isLoading && lp.balances.isEmpty) return const Center(child: CircularProgressIndicator());
              if (lp.balances.isEmpty) return const Center(child: Text('No outstanding Udhar across any customers.'));
              
              return ListView.separated(
                itemCount: lp.balances.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final b = lp.balances[i];
                  final id = int.parse(b['id']!.toString());
                  final bal = double.parse(b['balance_due']!.toString());
                  final isSelected = id == _selectedCustomerId;
                  
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.blue[50],
                    title: Text(b['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(b['phone'] ?? 'No Phone'),
                    trailing: Text('₹${bal.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[700])),
                    onTap: () => _selectCustomer(id, b['name'], bal),
                  );
                },
              );
            }),
          )),
          const SizedBox(width: 16),
          // Right: Customer Details & Payment
          Expanded(flex: 3, child: Card(
            child: _selectedCustomerId == null 
              ? const Center(child: Text('Select a customer to view ledger and receive payments.'))
              : Consumer<LedgerProvider>(builder: (ctx, lp, child) {
                  if (lp.isLoading) return const Center(child: CircularProgressIndicator());
                  
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_selectedCustomerName!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Total Outstanding: ₹${_selectedCustomerBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, color: Colors.red[700], fontWeight: FontWeight.w600)),
                        ]),
                        Row(children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final pdfBytes = await PdfService().generateCustomerLedgerStatement(
                                customerName: _selectedCustomerName!,
                                customerPhone: '', // Currently not capturing in state, can fetch later if needed
                                customerAddress: '',
                                totalBalance: _selectedCustomerBalance,
                                unpaidInvoices: context.read<LedgerProvider>().unpaidInvoices,
                                recentPayments: context.read<LedgerProvider>().payments,
                              );
                              await Printing.layoutPdf(onLayout: (_) => pdfBytes, name: 'Statement_${_selectedCustomerName}_${DateTime.now().millisecondsSinceEpoch}');
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Print Statement'),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _selectedCustomerBalance > 0 ? () => _showReceivePaymentDialog(context, _selectedCustomerId!, _selectedCustomerName!, _selectedCustomerBalance) : null,
                            icon: const Icon(Icons.payments),
                            label: const Text('Receive Payment'),
                            style: FilledButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                          ),
                        ]),
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
                              final due = inv.totalAmount - inv.returnedAmount - inv.amountPaid;
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.receipt_long, color: Colors.grey),
                                title: Text('Invoice ${inv.invoiceNumber}'),
                                subtitle: Text(DateFormat('dd MMM yyyy').format(inv.saleDate)),
                                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('Total: ₹${inv.totalAmount.toStringAsFixed(2)}'),
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

  void _showReceivePaymentDialog(BuildContext context, int customerId, String customerName, double maxBalance) {
    final amtCtrl = TextEditingController(text: maxBalance.toStringAsFixed(0));
    final notesCtrl = TextEditingController();
    String method = 'Cash';
    bool saving = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
      return AlertDialog(
        title: Text('Receive Payment: $customerName'),
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
              final ok = await context.read<LedgerProvider>().receivePayment(customerId, amt, method, notesCtrl.text);
              if (ok && context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment successfully recorded!')));
                // refresh selected customer balance from UI perspective
                final newBal = maxBalance - amt;
                setState(() => _selectedCustomerBalance = newBal > 0 ? newBal : 0);
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
