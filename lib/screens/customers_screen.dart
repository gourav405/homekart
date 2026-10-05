import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/people_provider.dart';
import '../models/customer.dart';
import '../widgets/shared_widgets.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); Future.microtask(() => context.read<CustomerProvider>().load()); }

  void _showForm(BuildContext context, {Customer? customer}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final gstCtrl = TextEditingController(text: customer?.gstNumber ?? '');
    final addrCtrl = TextEditingController(text: customer?.address ?? '');
    String? state = customer?.state;
    final formKey = GlobalKey<FormState>();

    final states = ['Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Chandigarh', 'Puducherry', 'Lakshadweep', 'Andaman & Nicobar Islands', 'Dadra & Nagar Haveli and Daman & Diu'];

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
      content: SizedBox(width: 450, child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
        const SizedBox(height: 12),
        TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextFormField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GST Number', prefixIcon: Icon(Icons.receipt_outlined))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map_outlined)),
          value: state != null && state!.isNotEmpty ? state : null,
          items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setDlgState(() => state = v),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)), maxLines: 2),
      ])))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          final c = Customer(id: customer?.id, name: nameCtrl.text, phone: phoneCtrl.text.isNotEmpty ? phoneCtrl.text : null, email: emailCtrl.text.isNotEmpty ? emailCtrl.text : null, gstNumber: gstCtrl.text.isNotEmpty ? gstCtrl.text : null, address: addrCtrl.text.isNotEmpty ? addrCtrl.text : null, state: state);
          final prov = context.read<CustomerProvider>();
          final ok = customer == null ? await prov.add(c) : await prov.update(c);
          if (ok && ctx.mounted) Navigator.pop(ctx);
        }, child: Text(customer == null ? 'Add' : 'Save')),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(builder: (ctx, p, _) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: double.infinity, child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, children: [
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, children: [
              const Text('Customers', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF1E88E5).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text('${p.customers.length}', style: const TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.w600))),
            ]),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 12, children: [
              SizedBox(height: 48, width: 300, child: TextField(controller: _searchCtrl, decoration: InputDecoration(hintText: 'Search customers...', prefixIcon: const Icon(Icons.search, size: 20), suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); p.search(''); }) : null, border: const OutlineInputBorder()), onChanged: p.search)),
              SizedBox(height: 48, child: FilledButton.icon(onPressed: () => _showForm(context), icon: const Icon(Icons.add, size: 18), label: const Text('Add Customer'))),
            ]),
          ])),
          const SizedBox(height: 20),
          Expanded(child: p.isLoading
            ? const Center(child: CircularProgressIndicator())
            : p.customers.isEmpty
              ? const EmptyState(icon: Icons.people_outline, title: 'No customers', subtitle: 'Add your first customer to get started')
              : Card(child: SizedBox(width: double.infinity, child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')), DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Email')), DataColumn(label: Text('State')), DataColumn(label: Text('GST Number')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: p.customers.map((c) => DataRow(cells: [
                  DataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(c.phone ?? '-')),
                  DataCell(Text(c.email ?? '-')),
                  DataCell(Text(c.state ?? '-')),
                  DataCell(Text(c.gstNumber ?? '-')),
                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showForm(context, customer: c), tooltip: 'Edit'),
                    IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]), onPressed: () async {
                      final ok = await showDialog<bool>(context: context, builder: (_) => const ConfirmDialog(title: 'Delete Customer', message: 'Are you sure you want to delete this customer?'));
                      if (ok == true) p.delete(c.id!);
                    }, tooltip: 'Delete'),
                  ])),
                ])).toList(),
              )))),
        ]),
      );
    });
  }
}
