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
  int _selectedFiscalYear = 2026;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedFiscalYear = now.month >= 4 ? now.year : now.year - 1;
    _selectedMonth = now.month;
    _applyYearAndMonth();
  }

  void _applyYearAndMonth() {
    _invoiceController.clear();
    final y = _selectedFiscalYear;
    if (_selectedMonth == null) {
      _startDate = DateTime(y, 4, 1);
      _endDate = DateTime(y + 1, 3, 31);
    } else {
      final m = _selectedMonth!;
      final year = m >= 4 ? y : y + 1;
      _startDate = DateTime(year, m, 1);
      _endDate = DateTime(year, m + 1, 0);
    }
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
        _selectedMonth = null;
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
      _applyYearAndMonth();
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

  Widget _buildStatCard(
    String title,
    String value,
    Color color, {
    IconData? icon,
    String? subtitle,
    bool isHighlight = false,
  }) {
    return Expanded(
      child: Card(
        elevation: isHighlight ? 2 : 0,
        color: isHighlight ? color.withValues(alpha: 0.04) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isHighlight ? color.withValues(alpha: 0.4) : Colors.grey.shade200,
            width: isHighlight ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null)
                    Icon(icon, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
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
    } else if (_selectedMonth != null && _startDate != null) {
      currentFilterText =
          'Showing figures for ${DateFormat('MMMM yyyy').format(_startDate!)} (FY $_selectedFiscalYear-${(_selectedFiscalYear + 1).toString().substring(2)})';
    } else if (_startDate != null && _endDate != null) {
      currentFilterText =
          'Showing figures for FY $_selectedFiscalYear-${(_selectedFiscalYear + 1).toString().substring(2)} (from ${DateFormat('dd MMM yyyy').format(_startDate!)} to ${DateFormat('dd MMM yyyy').format(_endDate!)})';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standard Top Header: Title on Left, Filters right-aligned on Right
            SizedBox(
              width: double.infinity,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Financial & Margin Reports',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (currentFilterText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentFilterText,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 48,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _selectedFiscalYear,
                          decoration: InputDecoration(
                            labelText: 'Fiscal Year',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: [2024, 2025, 2026, 2027, 2028].map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text('FY $y-${(y + 1).toString().substring(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            );
                          }).toList(),
                          onChanged: (y) {
                            if (y != null) {
                              setState(() {
                                _selectedFiscalYear = y;
                                _applyYearAndMonth();
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        height: 48,
                        child: DropdownButtonFormField<int?>(
                          isExpanded: true,
                          value: _selectedMonth,
                          decoration: InputDecoration(
                            labelText: 'Month',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Months (Full FY)', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 4, child: Text('Apr $_selectedFiscalYear', style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 5, child: Text('May $_selectedFiscalYear', style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 6, child: Text('Jun $_selectedFiscalYear', style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 7, child: Text('Jul $_selectedFiscalYear', style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 8, child: Text('Aug $_selectedFiscalYear', style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 9, child: Text('Sep $_selectedFiscalYear', style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 10, child: Text('Oct $_selectedFiscalYear', style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 11, child: Text('Nov $_selectedFiscalYear', style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 12, child: Text('Dec $_selectedFiscalYear', style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 1, child: Text('Jan ${_selectedFiscalYear + 1}', style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 2, child: Text('Feb ${_selectedFiscalYear + 1}', style: const TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 3, child: Text('Mar ${_selectedFiscalYear + 1}', style: const TextStyle(fontSize: 13))),
                          ],
                          onChanged: (m) {
                            setState(() {
                              _selectedMonth = m;
                              _applyYearAndMonth();
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        height: 48,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _groupByMode,
                          decoration: InputDecoration(
                            labelText: 'Group By',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'date',
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text('By Date', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'product',
                              child: Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text('By Product', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'invoice',
                              child: Row(
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 14, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text('By Invoice', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _groupByMode = val);
                              _loadData();
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: const Text('Custom Range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _exportGstReport,
                          icon: const Icon(Icons.file_download, size: 18),
                          label: const Text('Export GST for CA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        height: 48,
                        child: TextField(
                          controller: _invoiceController,
                          decoration: InputDecoration(
                            hintText: 'Search Invoice #...',
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onSubmitted: (_) => _searchInvoice(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _report == null
                  ? const Center(child: Text('Failed to load report'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatCard(
                              'Net Revenue',
                              _fmt(_report!.netRevenue),
                              Colors.blue[700]!,
                              icon: Icons.point_of_sale,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              'Cost of Goods (COGS)',
                              _fmt(_report!.totalCost),
                              Colors.orange[700]!,
                              icon: Icons.inventory_2,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              'Gross Profit',
                              _fmt(_report!.grossProfit),
                              _report!.grossProfit >= 0 ? const Color(0xFF2E7D32) : Colors.red[700]!,
                              icon: Icons.trending_up,
                              subtitle: '${_report!.marginPercent.toStringAsFixed(1)}% margin',
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              'Operating Expenses',
                              _fmt(_report!.totalExpenses),
                              Colors.deepOrange[700]!,
                              icon: Icons.receipt_long,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              _report!.netProfit >= 0 ? 'Net Total Profit' : 'Net Total Loss',
                              _fmt(_report!.netProfit),
                              _report!.netProfit >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFC62828),
                              icon: _report!.netProfit >= 0 ? Icons.monetization_on : Icons.warning_amber_rounded,
                              subtitle: '${_report!.netMarginPercent.toStringAsFixed(1)}% net margin',
                              isHighlight: true,
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
                                    if (_groupByMode == 'date') ...[
                                      const DataColumn(
                                        label: Text('Expenses'),
                                        numeric: true,
                                      ),
                                      const DataColumn(
                                        label: Text('Net Profit / (Loss)'),
                                        numeric: true,
                                      ),
                                    ],
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
                                            style: TextStyle(
                                              color: r.grossProfit >= 0
                                                  ? const Color(0xFF2E7D32)
                                                  : Colors.red[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (_groupByMode == 'date') ...[
                                          DataCell(
                                            Text(
                                              _fmt(r.expenses),
                                              style: TextStyle(
                                                color: r.expenses > 0
                                                    ? Colors.deepOrange[700]
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _fmt(r.netProfit),
                                              style: TextStyle(
                                                color: r.netProfit >= 0
                                                    ? const Color(0xFF1B5E20)
                                                    : const Color(0xFFC62828),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
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
          ],
        ),
      ),
    );
  }
}
