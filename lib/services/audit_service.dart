import 'dart:convert';
import '../services/database_service.dart';

class AuditService {
  final DatabaseService _db = DatabaseService();

  Future<void> log({
    required String action,
    required String entityType,
    int? entityId,
    String? description,
    String? oldValue,
    String? newValue,
    int? userId,
    String? username,
  }) async {
    try {
      await _db.query(
        '''
        INSERT INTO audit_log 
        (user_id, username, action, entity_type, entity_id, description, old_value, new_value)
        VALUES 
        (:userId, :username, :action, :entityType, :entityId, :description, :oldValue, :newValue)
        ''',
        {
          'userId': userId,
          'username': username,
          'action': action,
          'entityType': entityType,
          'entityId': entityId,
          'description': description,
          'oldValue': oldValue,
          'newValue': newValue,
        },
      );
    } catch (e) {
      print('Audit log error: $e');
    }
  }

  Future<List<Map<String, String?>>> getLogs({
    DateTime? from,
    DateTime? to,
    String? entityType,
    String? action,
    int? limit,
  }) async {
    try {
      String sql = 'SELECT * FROM audit_log WHERE 1=1';
      Map<String, dynamic> params = {};

      if (from != null) {
        sql += ' AND DATE(created_at) >= :from';
        params['from'] = "${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}";
      }
      if (to != null) {
        sql += ' AND DATE(created_at) <= :to';
        params['to'] = "${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}";
      }
      if (entityType != null && entityType.isNotEmpty && entityType != 'All') {
        sql += ' AND entity_type = :entityType';
        params['entityType'] = entityType;
      }
      if (action != null && action.isNotEmpty && action != 'All') {
        sql += ' AND action = :action';
        params['action'] = action;
      }

      sql += ' ORDER BY created_at DESC';

      if (limit != null) {
        sql += ' LIMIT :limit';
        params['limit'] = limit;
      }

      final res = await _db.query(sql, params);
      
      return res.rows.map((row) {
        final map = row.assoc();
        return map.map((key, value) => MapEntry(key, value?.toString()));
      }).toList();
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }
}
