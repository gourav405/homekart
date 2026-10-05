import 'package:flutter/material.dart';
import '../services/report_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _invoiceController = TextEditingController();

  MarginReport? _report;
  bool _isLoading = true;
  String _groupByMode = 'date';

  @override
  void initState() {
    super.initState();
    _setThisMonth();
  }

  void _setThisMonth() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _invoiceController.clear();
    _loadData();
  }

  void _setThisYear() {
    final now = DateTime.now();
    int startYear = now.month >= 4 ? now.year : now.year - 1;
    _startDate = DateTime(startYear, 4, 1);
    _endDate = DateTime(startYear + 1, 3, 31);
    _invoiceController.clear();
    _loadData();
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
        _invoiceController.clear();
      });
      _loadData();
    }
  }

  void _searchInvoice() {
    if (_invoiceController.text.trim().isNotEmpty) {
      setState(() {
        _startDate = null;
        _endDate = null;
      });
      _loadData();
    } else {
      _setThisMonth();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _report = await ReportService().getMarginReport(
        startDate: _startDate,
        endDate: _endDate,
        invoiceNumber: _invoiceController.text.trim().isEmpty
            ? null
            : _invoiceController.text.trim(),
        groupByMode: _groupByMode,
      );
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _exportGstReport() async {
    final dir = await FilePicker.getDirectoryPath();
    if (dir == null) return;

    try {
      final data = await ReportService().getGstReportData(_startDate, _endDate);

      final salesFile = File('$dir/GSTR1_Sales.csv');
      final salesCsv = const CsvEncoder().convert(data['sales'] ?? []);
      await salesFile.writeAsString(salesCsv);

      final purchaseFile = File('$dir/GSTR2_Purchases.csv');
      final purchaseCsv = const CsvEncoder().convert(data['purchases'] ?? []);
      await purchaseFile.writeAsString(purchaseCsv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported GST Reports to $dir successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _fmt(double v) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(v);

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentFilterText = '';
    if (_invoiceController.text.isNotEmpty) {
      currentFilterText =
          'Showing margins for Invoice: ${_invoiceController.text}';
    } else if (_startDate != null && _endDate != null) {
      currentFilterText =
          'Showing margins from ${DateFormat('dd MMM yyyy').format(_startDate!)} to ${DateFormat('dd MMM yyyy').format(_endDate!)}';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Financial & Margin Reports'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Custom Date Range'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _setThisMonth,
                  child: const Text('This Month'),
                ),
                TextButton(
                  onPressed: _setThisYear,
                  child: const Text('Current FY'),
                ),
                const SizedBox(width: 24),
                FilledButton.icon(
                  onPressed: _exportGstReport,
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text('Export GST Report for CA'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                ),
                const SizedBox(width: 24),
                const Text(
                  'Group By: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'date',
                      label: Text('Date'),
                      icon: Icon(Icons.calendar_today, size: 16),
                    ),
                    ButtonSegment(
                      value: 'product',
                      label: Text('Product'),
                      icon: Icon(Icons.inventory_2, size: 16),
                    ),
                    ButtonSegment(
                      value: 'invoice',
                      label: Text('Invoice'),
                      icon: Icon(Icons.receipt_long, size: 16),
                    ),
                  ],
                  selected: {_groupByMode},
                  onSelectionChanged: (val) {
                    setState(() => _groupByMode = val.first);
                    _loadData();
                  },
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _invoiceController,
                    decoration: InputDecoration(
                      hintText: 'Search Invoice # (e.g. INV-123)',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _invoiceController,
                        builder: (context, value, child) {
                          return value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _invoiceController.clear();
                                    _searchInvoice();
                                  },
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                  ),
                                  onPressed: _searchInvoice,
                                );
                        },
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (_) => _searchInvoice(),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey[200]),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _report == null
                ? const Center(child: Text('Failed to load report'))
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentFilterText,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard(
                              'Net Revenue (No Tax)',
                              _fmt(_report!.netRevenue),
                              Colors.blue[700]!,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Cost of Goods (COGS)',
                              _fmt(_report!.totalCost),
                              Colors.orange[700]!,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Gross Profit',
                              _fmt(_report!.grossProfit),
                              Colors.green[700]!,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Average Margin %',
                              '${_report!.marginPercent.toStringAsFixed(2)}%',
                              Colors.purple[700]!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Detailed Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListView(
                              children: [
                                DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.grey[100],
                                  ),
                                  showCheckboxColumn: false,
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        _invoiceController.text.isNotEmpty ||
                                                _groupByMode == 'product'
                                            ? 'Product Item'
                                            : (_groupByMode == 'invoice'
                                                  ? 'Invoice & Customer'
                                                  : 'Period'),
                                      ),
                                    ),
                                    const DataColumn(
                                      label: Text('Net Revenue'),
                                      numeric: true,
                                    ),
                                    const DataColumn(
                                      label: Text('COGS'),
                                      numeric: true,
                                    ),
                                    const DataColumn(
                                      label: Text('Gross Profit'),
                                      numeric: true,
                                    ),
                                    const DataColumn(
                                      label: Text('Margin %'),
                                      numeric: true,
                                    ),
                                  ],
                                  rows: _report!.rows.map((r) {
                                    final isInvoice =
                                        _groupByMode == 'invoice' &&
                                        _invoiceController.text.isEmpty;
                                    return DataRow(
                                      onSelectChanged: isInvoice
                                          ? (_) {
                                              final invNumber = r.label
                                                  .split(' - ')
                                                  .first;
                                              _invoiceController.text =
                                                  invNumber;
                                              _searchInvoice();
                                            }
                                          : null,
                                      cells: [
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                r.label,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (isInvoice)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    left: 8,
                                                  ),
                                                  child: Icon(
                                                    Icons.open_in_new,
                                                    size: 14,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(_fmt(r.netRevenue))),
                                        DataCell(Text(_fmt(r.totalCost))),
                                        DataCell(
                                          Text(
                                            _fmt(r.grossProfit),
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${r.marginPercent.toStringAsFixed(1)}%',
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
