import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  void _showAddExpenseDialog() {
    final amtCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'Tea & Snacks';
    String method = 'Cash';
    DateTime date = DateTime.now();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
      return AlertDialog(
        title: const Text('Add Shop Expense'),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: ['Tea & Snacks', 'Transport/Freight', 'Electricity/Utility', 'Salary/Wages', 'Maintenance', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setDlgState(() => category = v!),
            )),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: amtCtrl,
            decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: method,
            decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
            items: ['Cash', 'UPI', 'Bank'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setDlgState(() => method = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesCtrl,
            decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            final amt = double.tryParse(amtCtrl.text);
            if (amt != null && amt > 0) {
              final ok = await context.read<ExpenseProvider>().addExpense(Expense(
                expenseDate: date, category: category, amount: amt, paymentMethod: method, notes: notesCtrl.text
              ));
              if (ok && mounted) Navigator.pop(ctx);
            }
          }, child: const Text('Save Expense')),
        ],
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: double.infinity, child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [ const Text('Shop Expenses (Kharcha)', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 48, child: FilledButton.icon(onPressed: _showAddExpenseDialog, icon: const Icon(Icons.add, size: 18), label: const Text('Add Expense'))),
        ])),
        const SizedBox(height: 24),
        Expanded(child: Card(
          child: Consumer<ExpenseProvider>(builder: (ctx, ep, child) {
            if (ep.isLoading && ep.expenses.isEmpty) return const Center(child: CircularProgressIndicator());
            if (ep.expenses.isEmpty) return const Center(child: Text('No expenses recorded.'));

            return ListView.separated(
              itemCount: ep.expenses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final e = ep.expenses[i];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.red[50], child: Icon(Icons.money_off, color: Colors.red[400])),
                  title: Text('${e.category} - ₹${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${DateFormat('dd MMM yyyy').format(e.expenseDate)} | ${e.paymentMethod}${e.notes != null && e.notes!.isNotEmpty ? ' | ${e.notes}' : ''}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                    onPressed: () async {
                      final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                        title: const Text('Delete Expense?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
                        ],
                      ));
                      if (ok == true && e.id != null) ep.deleteExpense(e.id!);
                    }
                  ),
                );
              },
            );
          }),
        )),
      ]),
    );
  }
}
