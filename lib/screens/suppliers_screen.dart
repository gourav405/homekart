import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/people_provider.dart';
import '../models/supplier.dart';
import '../widgets/shared_widgets.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});
  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); Future.microtask(() => context.read<SupplierProvider>().load()); }

  void _showForm(BuildContext context, {Supplier? supplier}) {
    final nameCtrl = TextEditingController(text: supplier?.name ?? '');
    final phoneCtrl = TextEditingController(text: supplier?.phone ?? '');
    final emailCtrl = TextEditingController(text: supplier?.email ?? '');
    final gstCtrl = TextEditingController(text: supplier?.gstNumber ?? '');
    final addrCtrl = TextEditingController(text: supplier?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(supplier == null ? 'Add Supplier' : 'Edit Supplier'),
      content: SizedBox(width: 450, child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.business_outlined)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
        const SizedBox(height: 12),
        TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextFormField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GST Number', prefixIcon: Icon(Icons.receipt_outlined))),
        const SizedBox(height: 12),
        TextFormField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)), maxLines: 2),
      ])))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          final s = Supplier(id: supplier?.id, name: nameCtrl.text, phone: phoneCtrl.text.isNotEmpty ? phoneCtrl.text : null, email: emailCtrl.text.isNotEmpty ? emailCtrl.text : null, gstNumber: gstCtrl.text.isNotEmpty ? gstCtrl.text : null, address: addrCtrl.text.isNotEmpty ? addrCtrl.text : null);
          final prov = context.read<SupplierProvider>();
          final ok = supplier == null ? await prov.add(s) : await prov.update(s);
          if (ok && ctx.mounted) Navigator.pop(ctx);
        }, child: Text(supplier == null ? 'Add' : 'Save')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierProvider>(builder: (ctx, p, _) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: double.infinity, child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, children: [
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, children: [
              const Text('Suppliers', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF1E88E5).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text('${p.suppliers.length}', style: const TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.w600))),
            ]),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 12, children: [
              SizedBox(height: 48, width: 300, child: TextField(controller: _searchCtrl, decoration: const InputDecoration(hintText: 'Search suppliers...', prefixIcon: Icon(Icons.search, size: 20), border: OutlineInputBorder()), onChanged: p.search)),
              SizedBox(height: 48, child: FilledButton.icon(onPressed: () => _showForm(context), icon: const Icon(Icons.add, size: 18), label: const Text('Add Supplier'))),
            ]),
          ])),
          const SizedBox(height: 20),
          Expanded(child: p.isLoading
            ? const Center(child: CircularProgressIndicator())
            : p.suppliers.isEmpty
              ? const EmptyState(icon: Icons.local_shipping_outlined, title: 'No suppliers', subtitle: 'Add your first supplier')
              : Card(child: SizedBox(width: double.infinity, child: DataTable(
                columns: const [DataColumn(label: Text('Name')), DataColumn(label: Text('Phone')), DataColumn(label: Text('Email')), DataColumn(label: Text('GST Number')), DataColumn(label: Text('Address')), DataColumn(label: Text('Actions'))],
                rows: p.suppliers.map((s) => DataRow(cells: [
                  DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(s.phone ?? '-')),
                  DataCell(Text(s.email ?? '-')),
                  DataCell(Text(s.gstNumber ?? '-')),
                  DataCell(SizedBox(width: 150, child: Text(s.address ?? '-', overflow: TextOverflow.ellipsis))),
                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Edit', onPressed: () => _showForm(context, supplier: s)),
                    IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]), tooltip: 'Delete', onPressed: () async {
                      final ok = await showDialog<bool>(context: context, builder: (_) => const ConfirmDialog(title: 'Delete Supplier', message: 'Are you sure?'));
                      if (ok == true && s.id != null) p.delete(s.id!);
                    }),
                  ])),
                ])).toList(),
              )))),
        ]),
      );
    });
  }
}
