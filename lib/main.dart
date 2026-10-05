import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/product_provider.dart';
import 'providers/people_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ledger_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/supplier_ledger_provider.dart';
import 'services/database_service.dart';
import 'screens/app_shell.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await DatabaseService().connection; } catch (e) { debugPrint('DB error: $e'); }
  runApp(const HomekartApp());
}

class HomekartApp extends StatelessWidget {
  const HomekartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LedgerProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => SupplierLedgerProvider()),
      ],
      child: MaterialApp(
        title: 'Homekart',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            primary: const Color(0xFF1E88E5),
            secondary: const Color(0xFFFFA726),
            surface: Colors.white,
            error: const Color(0xFFE53935),
            brightness: Brightness.light,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
            margin: EdgeInsets.zero,
          ),
          inputDecorationTheme: InputDecorationTheme(
            constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            filled: true, fillColor: Colors.white,
          ),
          filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48), maximumSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )),
          outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48), maximumSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )),
          textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
            minimumSize: const Size(0, 48), maximumSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )),
          dataTableTheme: DataTableThemeData(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7FA)),
            headingTextStyle: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 13),
            dataRowMinHeight: 52, dataRowMaxHeight: 52,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isAuthenticated) {
              return const AppShell();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
