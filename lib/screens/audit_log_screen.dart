import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/audit_service.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});
  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final AuditService _auditService = AuditService();
  List<Map<String, String?>> _logs = [];
  bool _isLoading = true;

  DateTime? _fromDate = DateTime.now();
  DateTime? _toDate = DateTime.now();
  String _selectedEntityType = 'All';
  final List<String> _entityTypes = ['All', 'sale', 'purchase', 'product', 'user'];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    final logs = await _auditService.getLogs(
      from: _fromDate,
      to: _toDate,
      entityType: _selectedEntityType,
    );
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              children: [
                const Text('Audit Log', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      height: 48,
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        value: _selectedEntityType,
                        items: _entityTypes.map((e) => DropdownMenuItem(value: e, child: Text(e == 'All' ? 'All Entities' : e.toUpperCase()))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedEntityType = val);
                            _fetchLogs();
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range, size: 18),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        label: Text(
                          _fromDate == null || _toDate == null
                              ? 'All Time'
                              : '${DateFormat('MMM dd').format(_fromDate!)} - ${DateFormat('MMM dd, yyyy').format(_toDate!)}',
                        ),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            initialDateRange: (_fromDate != null && _toDate != null)
                                ? DateTimeRange(start: _fromDate!, end: _toDate!)
                                : DateTimeRange(start: DateTime.now(), end: DateTime.now()),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(platform: TargetPlatform.windows),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _fromDate = picked.start;
                              _toDate = picked.end;
                            });
                            _fetchLogs();
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: TextButton.icon(
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear'),
                        onPressed: () {
                          setState(() {
                            _fromDate = null;
                            _toDate = null;
                            _selectedEntityType = 'All';
                          });
                          _fetchLogs();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('No audit logs found'))
                    : SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.grey.withValues(alpha: 0.1)),
                            dataRowMaxHeight: double.infinity,
                            dataRowMinHeight: 48,
                            columns: const [
                              DataColumn(label: Text('Date/Time', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Entity', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _logs.map((log) {
                              return DataRow(cells: [
                                DataCell(Text(log['created_at']?.split('.').first ?? '')), // strip microseconds
                                DataCell(Text(log['username'] ?? 'Unknown')),
                                DataCell(Text(log['action'] ?? '')),
                                DataCell(Text(log['entity_type'] ?? '')),
                                DataCell(Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(log['description'] ?? ''),
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
