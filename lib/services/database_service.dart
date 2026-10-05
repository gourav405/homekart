import 'package:mysql_client/mysql_client.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  MySQLConnection? _connection;

  Future<MySQLConnection> get connection async {
    if (_connection == null || !_connection!.connected) {
      _connection = await MySQLConnection.createConnection(
        host: 'localhost',
        port: 3306,
        userName: 'root',
        password: 'Thinksys@123',
        databaseName: 'homekart',
      );
      await _connection!.connect();
    }
    return _connection!;
  }

  Future<void> close() async {
    await _connection?.close();
  }

  Future<IResultSet> query(String sql, [Map<String, dynamic>? params]) async {
    final conn = await connection;
    if (params != null && params.isNotEmpty) {
      return await conn.execute(sql, params);
    }
    return await conn.execute(sql);
  }
}
