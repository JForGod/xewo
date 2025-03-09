import 'dart:async';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:mysql1/mysql1.dart' as mysql;
import 'package:postgres/postgres.dart';
import 'database_service.dart';
import 'query_result.dart';

/// 数据库连接接口
abstract class DatabaseConnection {
  Future<QueryResult> executeQuery(String query, [List<dynamic>? params]);
  Future<void> disconnect();
}

/// SQLite数据库连接
class SqliteConnection implements DatabaseConnection {
  final Database _db;
  final DatabaseConfig _config;
  
  SqliteConnection(this._db, this._config);
  
  @override
  Future<QueryResult> executeQuery(String query, [List<dynamic>? params]) async {
    final stopwatch = Stopwatch()..start();
    final result = await _db.rawQuery(query, params ?? []);
    stopwatch.stop();
    
    return QueryResult.fromMaps(
      result,
      stopwatch.elapsed,
      affectedRows: 0, // SQLite不直接返回受影响的行数
    );
  }
  
  @override
  Future<void> disconnect() async {
    await _db.close();
  }
}

/// MySQL数据库连接
class MySqlConnection implements DatabaseConnection {
  final mysql.MySqlConnection _conn;
  final DatabaseConfig _config;
  
  MySqlConnection(this._conn, this._config);
  
  @override
  Future<QueryResult> executeQuery(String query, [List<dynamic>? params]) async {
    final stopwatch = Stopwatch()..start();
    final result = await _conn.query(query, params ?? []);
    stopwatch.stop();
    
    return QueryResult.fromMaps(
      result.map((row) => row.fields).toList(),
      stopwatch.elapsed,
      affectedRows: result.affectedRows ?? 0,
    );
  }
  
  @override
  Future<void> disconnect() async {
    await _conn.close();
  }
}

/// PostgreSQL数据库连接
class PostgreSqlConnection implements DatabaseConnection {
  final PostgreSQLConnection _conn;
  final DatabaseConfig _config;
  
  PostgreSqlConnection(this._conn, this._config);
  
  @override
  Future<QueryResult> executeQuery(String query, [List<dynamic>? params]) async {
    final stopwatch = Stopwatch()..start();
    
    final result = await _conn.query(
      query,
      substitutionValues: params?.asMap().map(
        (key, value) => MapEntry((key + 1).toString(), value),
      ),
    );
    
    stopwatch.stop();
    
    return QueryResult.fromMaps(
      result.map((row) => row.toColumnMap()).toList(),
      stopwatch.elapsed,
      affectedRows: result.affectedRowCount ?? 0,
    );
  }
  
  @override
  Future<void> disconnect() async {
    await _conn.close();
  }
} 