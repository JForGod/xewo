import 'dart:async';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:mysql1/mysql1.dart' as mysql;
import 'package:postgres/postgres.dart';
import 'database_service.dart';
import 'query_result.dart';

/// 数据库连接配置
class DatabaseConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final DatabaseType type;

  DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    required this.type,
  });
}

/// 数据库类型
enum DatabaseType {
  sqlite,
  mysql,
  postgresql,
}

/// 查询结果
class QueryResult {
  final List<List<dynamic>> rows;
  final Duration duration;
  final int affectedRows;

  QueryResult(this.rows, this.duration, {this.affectedRows = 0});

  factory QueryResult.fromMaps(List<Map<String, dynamic>> maps, Duration duration, {int affectedRows = 0}) {
    return QueryResult(
      maps.map((map) => map.values.toList()).toList(),
      duration,
      affectedRows: affectedRows,
    );
  }
}

/// 数据库异常
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
  
  @override
  String toString() => message;
}

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
  final Connection _conn;
  final DatabaseConfig _config;
  
  PostgreSqlConnection(this._conn, this._config);
  
  @override
  Future<QueryResult> executeQuery(String query, [List<dynamic>? params]) async {
    final stopwatch = Stopwatch()..start();
    try {
      final results = await _conn.execute(query, parameters: params);
      return QueryResult(
        results.map((row) => row.toList()).toList(),
        stopwatch.elapsed,
      );
    } catch (e) {
      throw DatabaseException('执行查询失败: $e');
    }
  }
  
  @override
  Future<void> disconnect() async {
    await _conn.close();
  }
} 