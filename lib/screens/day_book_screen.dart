import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';

class DayBookScreen extends StatefulWidget {
  const DayBookScreen({super.key});

  @override
  State<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends State<DayBookScreen> {
  final ReportService _svc = ReportService();
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _data = await _svc.getDayBook(_selectedDate);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _data == null) return const Center(child: CircularProgressIndicator());

    final inflows = _data!['inflows'] as Map<String, double>;
    final outflows = _data!['outflows'] as Map<String, double>;

    double totalIn = inflows.values.fold(0, (a, b) => a + b);
    double totalOut = outflows.values.fold(0, (a, b) => a + b);
    double netCash = (inflows['Cash'] ?? 0) - (outflows['Cash'] ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [ const Text('Day Book / Cash Register', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Cash In Hand (Net)', netCash, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('Total Inflow (All)', totalIn, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('Total Outflow (All)', totalOut, Colors.orange)),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMethodList('Money IN (Receipts)', inflows, Colors.green)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildMethodList('Money OUT (Payments)', outflows, Colors.orange)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, MaterialColor color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodList(String title, Map<String, double> data, MaterialColor color) {
    final methods = data.keys.toList()..sort();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            ...methods.map((m) {
              final val = data[m] ?? 0;
              if (val == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(m == 'Cash' ? Icons.money : Icons.account_balance, color: color[400], size: 20),
                        const SizedBox(width: 8),
                        Text(m, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text('₹${val.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
