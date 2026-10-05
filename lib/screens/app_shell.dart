import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'purchases_screen.dart';
import 'customers_screen.dart';
import 'suppliers_screen.dart';
import 'settings_screen.dart';
import 'ledger_screen.dart';

import 'expenses_screen.dart';

import 'supplier_ledger_screen.dart';

import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import 'reports_screen.dart';
import 'day_book_screen.dart';
import "audit_log_screen.dart";

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selected = 0;

  static const _allItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'allowedRoles': ['admin']},
    {'icon': Icons.inventory_2_rounded, 'label': 'Products', 'allowedRoles': ['admin', 'cashier', 'stock_manager']},
    {'icon': Icons.point_of_sale_rounded, 'label': 'Sales', 'allowedRoles': ['admin', 'cashier']},
    {'icon': Icons.shopping_cart_rounded, 'label': 'Purchases', 'allowedRoles': ['admin', 'stock_manager']},
    {'icon': Icons.account_balance_wallet_rounded, 'label': 'Customer Ledger', 'allowedRoles': ['admin']},
    {'icon': Icons.account_balance, 'label': 'Supplier Ledger', 'allowedRoles': ['admin', 'stock_manager']},
    {'icon': Icons.receipt_long_rounded, 'label': 'Expenses', 'allowedRoles': ['admin']},
    {'icon': Icons.analytics_rounded, 'label': 'Reports', 'allowedRoles': ['admin']},
    {'icon': Icons.book_rounded, 'label': 'Day Book', 'allowedRoles': ['admin']},
    {'icon': Icons.security_rounded, 'label': 'Audit Log', 'allowedRoles': ['admin']},
    {'icon': Icons.people_rounded, 'label': 'Customers', 'allowedRoles': ['admin', 'cashier']},
    {'icon': Icons.local_shipping_rounded, 'label': 'Suppliers', 'allowedRoles': ['admin', 'stock_manager']},
    {'icon': Icons.settings_rounded, 'label': 'Settings', 'allowedRoles': ['admin']},
  ];

  static final _screenWidgets = <Widget>[
    const ProductsScreen(),
    const SalesScreen(),
    const PurchasesScreen(),
    const LedgerScreen(),
    const SupplierLedgerScreen(),
    const ExpensesScreen(),
    const ReportsScreen(),
    const DayBookScreen(),
    const AuditLogScreen(),
    const CustomersScreen(),
    const SuppliersScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    
    final _items = <Map<String, Object>>[];
    final _screenIndices = <int>[];
    
    for (int i = 0; i < _allItems.length; i++) {
      final item = _allItems[i];
      final allowedRoles = item['allowedRoles'] as List<String>;
      if (!allowedRoles.contains(auth.role)) continue;
      _items.add(item);
      _screenIndices.add(i);
    }
    
    if (_selected >= _screenIndices.length) _selected = 0;

    void navigateTo(String label) {
      final idx = _items.indexWhere((i) => i['label'] == label);
      if (idx >= 0) setState(() => _selected = idx);
    }

    Widget buildScreen(int originalIndex) {
      if (originalIndex == 0) {
        return DashboardScreen(onNavigate: navigateTo);
      }
      return _screenWidgets[originalIndex - 1];
    }

    return Scaffold(
      body: Row(children: [
        // Sidebar
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Column(children: [
            // Logo
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Homekart', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Nav items
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, i) {
                  final item = _items[i];
                  final isSelected = _selected == i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Material(
                      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _selected = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(children: [
                            Icon(item['icon'] as IconData, size: 22, color: isSelected ? theme.colorScheme.primary : Colors.grey[600]),
                            const SizedBox(width: 14),
                            Text(item['label'] as String, style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? theme.colorScheme.primary : Colors.grey[700],
                              fontSize: 14,
                            )),
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout, color: Colors.grey),
                label: const Text('Logout', style: TextStyle(color: Colors.grey)),
                style: TextButton.styleFrom(alignment: Alignment.centerLeft, minimumSize: const Size(double.infinity, 48)),
              ),
            ),
            // Version
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text('Homekart v1.0.0 | ${auth.currentUser?.role.toUpperCase()}', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ),
          ]),
        ),
        // Content
        Expanded(
          child: Container(
            color: const Color(0xFFF5F7FA),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: buildScreen(_screenIndices[_selected]),
            ),
          ),
        ),
      ]),
    );
  }
}
