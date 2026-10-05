import '../models/user.dart';
import '../services/user_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();


  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final p = context.read<SettingsProvider>();
      await p.load();
      _nameCtrl.text = p.businessName;
      _addrCtrl.text = p.businessAddress;
      _phoneCtrl.text = p.businessPhone;
      _emailCtrl.text = p.businessEmail;
      _gstCtrl.text = p.gstin;
      _upiCtrl.text = p.upiId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (ctx, p, _) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          // Business Info
          Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.storefront_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Business Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
            const Divider(height: 32),
            Row(children: [
              Expanded(child: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.business_outlined)))),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _gstCtrl, decoration: const InputDecoration(labelText: 'GSTIN', prefixIcon: Icon(Icons.receipt_outlined)))),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)))),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)))),
            ]),
            const SizedBox(height: 16),
            TextField(controller: _addrCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)), maxLines: 2),
            const SizedBox(height: 16),
            TextField(controller: _upiCtrl, decoration: const InputDecoration(labelText: 'Business UPI ID', prefixIcon: Icon(Icons.qr_code_2_outlined))),
            const SizedBox(height: 16),

            Align(alignment: Alignment.centerRight, child: FilledButton.icon(
              onPressed: () async {
                await p.updateBusinessInfo({
                  'business_name': _nameCtrl.text,
                  'business_address': _addrCtrl.text,
                  'business_phone': _phoneCtrl.text,
                  'business_email': _emailCtrl.text,
                  'business_gstin': _gstCtrl.text,
                  'business_upi_id': _upiCtrl.text,
                });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!'), backgroundColor: Color(0xFF43A047)));
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            )),
          ]))),
          const SizedBox(height: 24),
          const UsersSettingsWidget(),
          const SizedBox(height: 24),
          // About
          Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
            const Divider(height: 32),
            _infoRow('Application', 'Homekart'),
            const SizedBox(height: 8),
            _infoRow('Version', '1.0.0'),
            const SizedBox(height: 8),
            _infoRow('Database', 'MySQL 8.0 (homekart)'),
            const SizedBox(height: 8),
            _infoRow('Framework', 'Flutter Desktop'),
          ]))),
        ]),
      );
    });
  }

  Widget _infoRow(String label, String value) {
    return Row(children: [
      SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    ]);
  }
}




class UsersSettingsWidget extends StatefulWidget {
  const UsersSettingsWidget({super.key});
  @override
  State<UsersSettingsWidget> createState() => _UsersSettingsWidgetState();
}

class _UsersSettingsWidgetState extends State<UsersSettingsWidget> {
  final UserService _svc = UserService();
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      _users = await _svc.getAllUsers();
    } catch (e) {
      debugPrint(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'cashier';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        title: const Text('Add User'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Username', isDense: true)),
          const SizedBox(height: 16),
          TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password', isDense: true)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(labelText: 'Role', isDense: true),
            items: ['admin', 'cashier', 'stock_manager'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase().replaceAll('_', ' ')))).toList(),
            onChanged: (v) { if (v != null) setDlgState(() => role = v); },
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (nameCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
            Navigator.pop(ctx);
            await _svc.addUser(nameCtrl.text, passCtrl.text, role);
            _loadUsers();
          }, child: const Text('Save')),
        ],
      )
    ));
  }

  void _showChangePasswordDialog(User u) {
    final passCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Change Password: ${u.username}'),
      content: TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'New Password', isDense: true)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (passCtrl.text.isEmpty) return;
          Navigator.pop(ctx);
          await _svc.updatePassword(u.id, passCtrl.text);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
        }, child: const Text('Save')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.security_rounded, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Security & Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ]),
        OutlinedButton.icon(onPressed: _showAddUserDialog, icon: const Icon(Icons.person_add, size: 18), label: const Text('Add User')),
      ]),
      const Divider(height: 32),
      if (_loading) const Center(child: CircularProgressIndicator())
      else ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _users.length,
        itemBuilder: (ctx, i) {
          final u = _users[i];
          return ListTile(
            leading: CircleAvatar(child: Icon(u.isAdmin ? Icons.admin_panel_settings : (u.role == 'stock_manager' ? Icons.inventory : Icons.point_of_sale), size: 20)),
            title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(u.role.toUpperCase().replaceAll('_', ' ')),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              TextButton(onPressed: () => _showChangePasswordDialog(u), child: const Text('Change Password')),
              if (_users.length > 1) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                  title: const Text('Delete User?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ));
                if (ok == true) { await _svc.deleteUser(u.id); _loadUsers(); }
              }),
            ]),
          );
        },
      )
    ])));
  }
}
