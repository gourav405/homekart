import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_data.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/shared_widgets.dart';
import '../services/inventory_service.dart';
import '../models/inventory.dart';

typedef DashboardNavigate = void Function(String screenLabel);

class DashboardScreen extends StatefulWidget {
  final DashboardNavigate? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _chartColors = [
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFFA726),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
    Color(0xFF546E7A),
  ];

  void _showLowStockDialog(BuildContext context) async {
    final items = await InventoryService().getLowStock();
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Low Stock Variants'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: items.isEmpty 
              ? const Center(child: Text('No low stock items!'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      title: Text('${item.productName ?? ""} - ${item.variantSku ?? ""}'),
                      subtitle: Text('Min: ${item.minimumStock} | Current: ${item.quantity}'),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onNavigate?.call('Products'); // Go to Products -> Variants tab
                        },
                        child: const Text('View'),
                      ),
                    );
                  }
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            )
          ],
        );
      }
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<DashboardProvider>().load();
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload keeps old DashboardData in memory; refetch with new fields.
    Future.microtask(() {
      if (mounted) context.read<DashboardProvider>().load();
    });
  }

  String _fmt(double v) {
    final isNeg = v < 0;
    v = v.abs();
    final prefix = isNeg ? '-₹' : '₹';
    if (v >= 10000000) return '$prefix${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '$prefix${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '$prefix${(v / 1000).toStringAsFixed(1)}K';
    return '$prefix${NumberFormat('#,##,###').format(v.toInt())}';
  }

  String _fmtFull(double v) => '₹ ${NumberFormat('#,##,###').format(v.round())}';

  Widget _trend(double current, double previous, {String suffix = 'vs yesterday'}) {
    if (previous == 0) {
      return Text('--', style: TextStyle(fontSize: 12, color: Colors.grey[500]));
    }
    final change = ((current - previous) / previous.abs()) * 100;
    final isPositive = change >= 0;
    final color = isPositive ? const Color(0xFF43A047) : const Color(0xFFE53935);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '${change.abs().toStringAsFixed(0)}% ',
          style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
        ),
        Text(suffix, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    Widget? trend,
  }) {
    return Expanded(
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, color: Colors.blue[900], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    if (trend != null) trend,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child, Widget? trailing}) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 20),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _stockBadge(String label, bool isLow) {
    final color = isLow ? const Color(0xFFE53935) : const Color(0xFF43A047);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    if (status.toLowerCase() == 'paid' || status.toLowerCase() == 'delivered') {
      color = const Color(0xFF43A047);
    } else if (status.toLowerCase() == 'pending') {
      color = const Color(0xFFFFA726);
    } else {
      color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (ctx, p, _) {
        if (p.isLoading && p.data == null) return const Center(child: CircularProgressIndicator());
        if (p.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(p.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                FilledButton(onPressed: p.load, child: const Text('Retry')),
              ],
            ),
          );
        }

        final d = p.data;
        if (d == null) return const Center(child: Text('No data'));

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FE),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                        const SizedBox(height: 4),
                        Text('Here\'s what\'s happening with your store today', style: TextStyle(fontSize: 14, color: Colors.blueGrey[400])),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey[600]),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.blueGrey[600]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── KPI Cards ──
                Row(
                  children: [
                    _buildKpiCard(
                      title: 'Total Sales',
                      value: _fmtFull(d.todaySales),
                      icon: Icons.shopping_cart,
                      color: const Color(0xFF2E7D32), // Green
                      trend: _trend(d.todaySales, d.yesterdaySales, suffix: 'vs yesterday'),
                    ),
                    const SizedBox(width: 16),
                    _buildKpiCard(
                      title: 'Total Orders',
                      value: '${d.todaySaleCount}',
                      icon: Icons.inventory_2,
                      color: const Color(0xFF1565C0), // Blue
                      trend: _trend(d.todaySaleCount.toDouble(), d.yesterdaySaleCount.toDouble(), suffix: 'vs yesterday'),
                    ),
                    const SizedBox(width: 16),
                    _buildKpiCard(
                      title: 'New Customers',
                      value: '${d.newCustomersToday}',
                      icon: Icons.people,
                      color: const Color(0xFF6A1B9A), // Purple
                      trend: _trend(d.totalCustomers.toDouble(), d.prevMonthCustomerCount.toDouble(), suffix: 'vs last month'),
                    ),
                    const SizedBox(width: 16),
                    _buildKpiCard(
                      title: 'Pending Purchase Orders',
                      value: '${d.pendingPurchasesCount}',
                      icon: Icons.local_shipping,
                      color: const Color(0xFFEF6C00), // Orange
                      trend: Text('pending orders', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Charts & Quick Actions ──
                SizedBox(
                  height: 380,
                  child: Row(
                    children: [
                      // Sales Overview (Line Chart)
                      Expanded(
                        flex: 5,
                        child: _buildSectionCard(
                          title: 'Sales Overview',
                          trailing: Row(
                            children: [
                              Icon(Icons.circle, size: 10, color: Colors.blue[600]),
                              const SizedBox(width: 4),
                              const Text('This Week', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 12),
                              Icon(Icons.circle, size: 10, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              const Text('Last Week', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          child: d.dailySalesData.isEmpty
                              ? const Center(child: Text('No sales data'))
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[200], strokeWidth: 1)),
                                    titlesData: FlTitlesData(
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (v, meta) {
                                            if (v.toInt() < 0 || v.toInt() >= d.dailySalesData.length) return const SizedBox();
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(d.dailySalesData[v.toInt()].day, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                            );
                                          },
                                          reservedSize: 30,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 60,
                                          getTitlesWidget: (v, meta) => Text(_fmt(v), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: d.dailySalesData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
                                        isCurved: true,
                                        color: Colors.blue[600],
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(show: true, getDotPainter: (a,b,c,d) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: Colors.blue[600]!)),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.blue[600]!.withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Sales by Category (Pie Chart)
                      Expanded(
                        flex: 3,
                        child: _buildSectionCard(
                          title: 'Sales by Category',
                          child: d.categorySales.isEmpty
                              ? const Center(child: Text('No data'))
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          PieChart(
                                            PieChartData(
                                              sectionsSpace: 2,
                                              centerSpaceRadius: 50,
                                              sections: d.categorySales.asMap().entries.map((e) {
                                                return PieChartSectionData(
                                                  color: _chartColors[e.key % _chartColors.length],
                                                  value: e.value.revenue,
                                                  title: '',
                                                  radius: 40,
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(_fmt(d.categorySales.fold(0.0, (s, c) => s + c.revenue)), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                              Text('Total Sales', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: d.categorySales.length,
                                        itemBuilder: (ctx, i) {
                                          final total = d.categorySales.fold(0.0, (s, c) => s + c.revenue);
                                          final pct = total > 0 ? (d.categorySales[i].revenue / total * 100).toStringAsFixed(0) : '0';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Row(
                                              children: [
                                                Icon(Icons.circle, size: 12, color: _chartColors[i % _chartColors.length]),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text(d.categorySales[i].name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                                                Text('$pct%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Quick Actions
                      Expanded(
                        flex: 2,
                        child: _buildSectionCard(
                          title: 'Quick Actions',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _quickActionTile(Icons.shopping_cart, 'New Sale', Colors.blue, () => widget.onNavigate?.call('Sales')),
                              _quickActionTile(Icons.description, 'Purchase Order', Colors.green, () => widget.onNavigate?.call('Purchases')),
                              _quickActionTile(Icons.add_box, 'Add Product', Colors.blue[700]!, () => widget.onNavigate?.call('Products')),
                              _quickActionTile(Icons.inventory, 'Check Stock', Colors.orange, () => widget.onNavigate?.call('Dashboard')),
                              _quickActionTile(Icons.bar_chart, 'Generate Report', Colors.purple, () => widget.onNavigate?.call('Day Book')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Tables Row ──
                SizedBox(
                  height: 400,
                  child: Row(
                    children: [
                      // Recent Sales
                      Expanded(
                        flex: 4,
                        child: _buildSectionCard(
                          title: 'Recent Sales',
                          trailing: InkWell(onTap: () => widget.onNavigate?.call('Sales'), child: const Text('View All →', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13))),
                          child: SingleChildScrollView(
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(1.5),
                                1: FlexColumnWidth(2),
                                2: FlexColumnWidth(1.5),
                                3: FlexColumnWidth(1.5),
                                4: FlexColumnWidth(1.2),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                                  children: ['Invoice No.', 'Customer', 'Date', 'Amount', 'Status']
                                      .map((t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 13))))
                                      .toList(),
                                ),
                                ...d.recentSales.take(6).map((s) => TableRow(
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                                  children: [
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(s.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(s.customerName ?? 'Walk-in', style: const TextStyle(fontSize: 13))),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(DateFormat('dd MMM yyyy').format(s.createdAt ?? DateTime.now()), style: const TextStyle(fontSize: 13))),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('₹${s.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Align(alignment: Alignment.centerLeft, child: _statusBadge(s.status))),
                                  ]
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Low Stock Alert
                      Expanded(
                        flex: 4,
                        child: _buildSectionCard(
                          title: 'Low Stock Alert',
                          trailing: InkWell(onTap: () => _showLowStockDialog(context), child: const Text('View All →', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13))),
                          child: SingleChildScrollView(
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2.5),
                                1: FlexColumnWidth(1.5),
                                2: FlexColumnWidth(1),
                                3: FlexColumnWidth(1),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                                  children: ['Product', 'SKU', 'Stock', 'Status']
                                      .map((t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 13))))
                                      .toList(),
                                ),
                                ...d.inventoryOverview.where((i) => i.isLowStock).take(6).map((i) => TableRow(
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                                  children: [
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(i.productName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('-', style: const TextStyle(fontSize: 13))), // Mock SKU as we don't have it in OverviewItem currently
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('${i.quantity.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13))),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Align(alignment: Alignment.centerLeft, child: _stockBadge('Low', true))),
                                  ]
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Store Performance
                      Expanded(
                        flex: 3,
                        child: _buildSectionCard(
                          title: 'Store Performance',
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    _perfTile('Total Sales', _fmtFull(d.totalRevenue), true, '14%'),
                                    const SizedBox(width: 16),
                                    _perfTile('Total Profit', _fmtFull(d.totalRevenue - d.totalCogs), true, '11%'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    _perfTile('Total Orders', '${d.todaySaleCount * 10}', true, '9%'),
                                    const SizedBox(width: 16),
                                    _perfTile('Avg. Order Value', _fmtFull(d.totalRevenue / (d.todaySaleCount == 0 ? 1 : d.todaySaleCount)), true, '6%'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickActionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _perfTile(String title, String value, bool isUp, String pct) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: isUp ? Colors.green : Colors.red),
                const SizedBox(width: 4),
                Text('$pct', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUp ? Colors.green : Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
