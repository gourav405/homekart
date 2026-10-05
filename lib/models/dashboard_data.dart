import 'sale.dart';

class DashboardData {
  final int totalProducts;
  final int totalVariants;
  final int lowStockCount;
  final int totalCustomers;
  final int totalSuppliers;

  // Sales (Revenue)
  final double todaySales;
  final double yesterdaySales;
  final double monthlySales;
  final double prevMonthSales;
  final double yearlySales;
  final double prevYearSales;
  final double totalRevenue;
  final int todaySaleCount;

  // COGS
  final double todayCogs;
  final double yesterdayCogs;
  final double monthlyCogs;
  final double prevMonthCogs;
  final double yearlyCogs;
  final double prevYearCogs;
  final double totalCogs;

  // Purchases
  final double todayPurchases;
  final double yesterdayPurchases;
  final double monthlyPurchases;
  final double prevMonthPurchases;
  final double yearlyPurchases;
  final double prevYearPurchases;
  final double totalPurchases;

  // Expenses
  final double todayExpenses;
  final double yesterdayExpenses;
  final double monthlyExpenses;
  final double prevMonthExpenses;
  final double yearlyExpenses;
  final double prevYearExpenses;
  final double totalExpenses;

  final int yesterdaySaleCount;
  final int pendingPurchasesCount;
  final int newCustomersToday;
  final int prevMonthCustomerCount;

  final List<TopVariant> topVariants;
  final List<MonthlySale> monthlySalesData;
  final List<DailySale> dailySalesData;
  final List<CategorySale> categorySales;
  final List<InventoryOverviewItem> inventoryOverview;
  final List<Sale> recentSales;

  DashboardData({
    required this.totalProducts, required this.totalVariants, required this.lowStockCount, required this.totalCustomers, required this.totalSuppliers,
    required this.todaySales, required this.yesterdaySales, required this.monthlySales, required this.prevMonthSales, required this.yearlySales, required this.prevYearSales, required this.totalRevenue, required this.todaySaleCount,
    required this.yesterdaySaleCount, required this.pendingPurchasesCount, required this.newCustomersToday, required this.prevMonthCustomerCount,
    required this.todayCogs, required this.yesterdayCogs, required this.monthlyCogs, required this.prevMonthCogs, required this.yearlyCogs, required this.prevYearCogs, required this.totalCogs,
    required this.todayPurchases, required this.yesterdayPurchases, required this.monthlyPurchases, required this.prevMonthPurchases, required this.yearlyPurchases, required this.prevYearPurchases, required this.totalPurchases,
    required this.todayExpenses, required this.yesterdayExpenses, required this.monthlyExpenses, required this.prevMonthExpenses, required this.yearlyExpenses, required this.prevYearExpenses, required this.totalExpenses,
    required this.topVariants, required this.monthlySalesData, required this.dailySalesData, required this.categorySales, required this.inventoryOverview, required this.recentSales
  });
}

class TopVariant {
  final String name;
  final int quantitySold;
  final double revenue;
  TopVariant({required this.name, required this.quantitySold, required this.revenue});
  factory TopVariant.fromMap(Map<String, String?> map) => TopVariant(
    name: map['name'] ?? '',
    quantitySold: map['quantity_sold'] != null ? int.tryParse(map['quantity_sold']!) ?? 0 : 0,
    revenue: map['revenue'] != null ? double.tryParse(map['revenue']!) ?? 0 : 0,
  );
}

class MonthlySale {
  final String month;
  final double amount;
  MonthlySale({required this.month, required this.amount});
  factory MonthlySale.fromMap(Map<String, String?> map) => MonthlySale(
    month: map['month'] ?? '',
    amount: map['amount'] != null ? double.tryParse(map['amount']!) ?? 0 : 0,
  );
}

class DailySale {
  final String day;
  final double amount;
  DailySale({required this.day, required this.amount});
  factory DailySale.fromMap(Map<String, String?> map) => DailySale(
    day: map['day'] ?? '',
    amount: map['amount'] != null ? double.tryParse(map['amount']!) ?? 0 : 0,
  );
}

class CategorySale {
  final String name;
  final double revenue;
  CategorySale({required this.name, required this.revenue});
  factory CategorySale.fromMap(Map<String, String?> map) => CategorySale(
    name: map['name'] ?? 'Others',
    revenue: map['revenue'] != null ? double.tryParse(map['revenue']!) ?? 0 : 0,
  );
}

class InventoryOverviewItem {
  final String productName;
  final double quantity;
  final double minimumStock;
  InventoryOverviewItem({required this.productName, required this.quantity, required this.minimumStock});
  bool get isLowStock => minimumStock > 0 && quantity <= minimumStock;
  factory InventoryOverviewItem.fromMap(Map<String, String?> map) => InventoryOverviewItem(
    productName: map['product_name'] ?? '',
    quantity: map['quantity'] != null ? double.tryParse(map['quantity']!) ?? 0 : 0,
    minimumStock: map['minimum_stock'] != null ? double.tryParse(map['minimum_stock']!) ?? 0 : 0,
  );
}
