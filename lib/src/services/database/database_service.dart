import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:mysql1/mysql1.dart' as mysql;
import 'package:postgres/postgres.dart';
import 'query_result.dart';
import 'database_exception.dart';
import '../core/logger_service.dart';
import 'database_connection.dart';

/// 数据库类型枚举
enum DatabaseType {
  sqlite,
  mysql,
  postgresql,
  sqlServer,
  oracle,
}

/// 数据库连接配置
class DatabaseConfig {
  final String name;
  final DatabaseType type;
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final Map<String, String> options;

  const DatabaseConfig({
    required this.name,
    required this.type,
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.options = const {},
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.toString(),
    'host': host,
    'port': port,
    'database': database,
    'username': username,
    'password': password,
    'options': options,
  };

  factory DatabaseConfig.fromJson(Map<String, dynamic> json) {
    return DatabaseConfig(
      name: json['name'] as String,
      type: DatabaseType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      host: json['host'] as String,
      port: int.parse(json['port'].toString()),
      database: json['database'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      options: Map<String, String>.from(json['options'] as Map<String, dynamic>),
    );
  }
}

/// 表列信息
class ColumnInfo {
  final String name;
  final String type;
  final bool nullable;
  final String key;
  final String? defaultValue;
  final String extra;
  
  ColumnInfo({
    required this.name,
    required this.type,
    required this.nullable,
    required this.key,
    this.defaultValue,
    required this.extra,
  });
}

/// 表索引信息
class IndexInfo {
  final String name;
  final String columnName;
  final bool unique;
  final bool primary;
  
  IndexInfo({
    required this.name,
    required this.columnName,
    required this.unique,
    required this.primary,
  });
}

/// 数据库服务类
class DatabaseService {
  final Map<String, DatabaseConnection> _connections = {};
  final Map<String, DatabaseConfig> _configs = {};
  final _logger = LoggerService();
  
  /// 获取数据库配置
  DatabaseConfig? getConfig(String name) {
    return _configs[name];
  }

  /// 添加数据库配置
  void addConfig(DatabaseConfig config) {
    _configs[config.name] = config;
  }
  
  /// 移除数据库配置
  void removeConfig(String name) {
    _configs.remove(name);
    disconnect(name);
  }
  
  /// 获取所有配置
  List<DatabaseConfig> getAllConfigs() {
    return _configs.values.toList();
  }
  
  /// 连接数据库
  Future<void> connect(String connectionName, DatabaseConfig config) async {
    try {
      final connection = await _createConnection(config);
      _connections[connectionName] = connection;
    } catch (e) {
      _logger.error('Failed to connect to database: ${e.toString()}');
      rethrow;
    }
  }
  
  Future<DatabaseConnection> _createConnection(DatabaseConfig config) async {
    switch (config.type) {
      case DatabaseType.sqlite:
        final db = await openDatabase(config.database);
        return SqliteConnection(db, config);
      case DatabaseType.mysql:
        final conn = await mysql.MySqlConnection.connect(
          mysql.ConnectionSettings(
            host: config.host,
            port: config.port,
            user: config.username,
            password: config.password,
            db: config.database,
          ),
        );
        return MySqlConnection(conn, config);
      case DatabaseType.postgresql:
        final conn = PostgreSQLConnection(
          config.host,
          config.port,
          config.database,
          username: config.username,
          password: config.password,
        );
        await conn.open();
        return PostgreSqlConnection(conn, config);
      default:
        throw UnsupportedError('Unsupported database type: ${config.type}');
    }
  }
  
  /// 执行SQL查询
  Future<QueryResult> executeQuery(String connectionName, String query, [List<dynamic>? params]) async {
    try {
      final connection = _getConnection(connectionName);
      return await connection.executeQuery(query, params);
    } catch (e) {
      _logger.error('Failed to execute query: ${e.toString()}');
      rethrow;
    }
  }
  
  DatabaseConnection _getConnection(String connectionName) {
    final connection = _connections[connectionName];
    if (connection == null) {
      throw StateError('Connection $connectionName not found');
    }
    return connection;
  }
  
  /// 获取数据库模式信息
  Future<Map<String, dynamic>> getSchema(String name) async {
    final conn = _connections[name];
    if (conn == null) {
      throw Exception('Database not connected: $name');
    }
    
    try {
      if (conn is SqliteConnection) {
        final tables = await executeQuery(name, 'SELECT name FROM sqlite_master WHERE type="table"');
        final schema = <String, dynamic>{};
        
        for (final row in tables.rows) {
          final tableName = row[0] as String;
          final columns = await executeQuery(name, 'PRAGMA table_info(${tableName})');
          schema[tableName] = columns.rows.map((col) => {
            'name': col[1],
            'type': col[2],
            'notnull': col[3] == 1,
            'pk': col[5] == 1,
          }).toList();
        }
        
        return schema;
      } else if (conn is MySqlConnection) {
        final tables = await executeQuery(name, 'SHOW TABLES');
        final schema = <String, dynamic>{};
        
        for (final row in tables.rows) {
          final tableName = row[0] as String;
          final columns = await executeQuery(name, 'DESCRIBE ${tableName}');
          schema[tableName] = columns.rows.map((col) => {
            'name': col[0],
            'type': col[1],
            'notnull': col[2] == 'NO',
            'pk': col[3] == 'PRI',
          }).toList();
        }
        
        return schema;
      } else if (conn is PostgreSqlConnection) {
        final tables = await executeQuery(name, '''
          SELECT table_name 
          FROM information_schema.tables 
          WHERE table_schema = 'public'
        ''');
        final schema = <String, dynamic>{};
        
        for (final row in tables.rows) {
          final tableName = row[0] as String;
          final columns = await executeQuery(name, '''
            SELECT column_name, data_type, is_nullable, 
                   (SELECT true 
                    FROM information_schema.table_constraints tc 
                    JOIN information_schema.key_column_usage kcu 
                    ON tc.constraint_name = kcu.constraint_name 
                    WHERE tc.table_name = '${tableName}' 
                    AND kcu.column_name = columns.column_name 
                    AND tc.constraint_type = 'PRIMARY KEY'
                   ) is_primary_key
            FROM information_schema.columns 
            WHERE table_name = '${tableName}'
          ''');
          
          schema[tableName] = columns.rows.map((col) => {
            'name': col[0],
            'type': col[1],
            'notnull': col[2] == 'NO',
            'pk': col[3] ?? false,
          }).toList();
        }
        
        return schema;
      } else {
        throw UnimplementedError('Unsupported database connection type');
      }
    } catch (e) {
      debugPrint('Failed to get database schema: $e');
      rethrow;
    }
  }

  /// 获取表的列信息
  Future<List<ColumnInfo>> getTableColumns(String connectionName, String tableName) async {
    final conn = _connections[connectionName];
    if (conn == null) {
      throw Exception('Database not connected: $connectionName');
    }

    final config = _configs[connectionName];
    if (config == null) {
      throw Exception('Database configuration not found: $connectionName');
    }

    try {
      switch (config.type) {
        case DatabaseType.mysql:
          final result = await executeQuery(
            connectionName,
            'SHOW COLUMNS FROM $tableName',
          );
          return result.rows.map((row) => ColumnInfo(
            name: row[0] as String,
            type: row[1] as String,
            nullable: row[2] as String == 'YES',
            key: row[3] as String,
            defaultValue: row[4] as String?,
            extra: row[5] as String,
          )).toList();

        case DatabaseType.postgresql:
          final result = await executeQuery(
            connectionName,
            '''
            SELECT 
              column_name, 
              data_type,
              is_nullable,
              column_default,
              (
                SELECT constraint_type 
                FROM information_schema.table_constraints tc
                INNER JOIN information_schema.constraint_column_usage ccu 
                ON tc.constraint_name = ccu.constraint_name
                WHERE tc.table_name = columns.table_name 
                AND ccu.column_name = columns.column_name 
                AND constraint_type = 'PRIMARY KEY'
              ) as key_type
            FROM information_schema.columns 
            WHERE table_name = '${tableName}'
            ''',
          );
          
          return result.rows.map((row) => ColumnInfo(
            name: row[0] as String,
            type: row[1] as String,
            nullable: row[2] as String == 'YES',
            key: row[4] as String? ?? '',
            defaultValue: row[3] as String?,
            extra: '',
          )).toList();

        case DatabaseType.sqlite:
          final result = await executeQuery(
            connectionName,
            'PRAGMA table_info(${tableName})',
          );
          return result.rows.map((row) => ColumnInfo(
            name: row[1] as String, // name
            type: row[2] as String, // type
            nullable: (row[3] as int) == 0, // notnull
            key: (row[5] as int) == 1 ? 'PRI' : '',
            defaultValue: row[4] as String?,
            extra: '',
          )).toList();

        default:
          throw UnimplementedError(
            'Database type ${config.type} is not supported yet',
          );
      }
    } catch (e) {
      debugPrint('Failed to get table columns: $e');
      rethrow;
    }
  }

  /// 获取表的索引信息
  Future<List<IndexInfo>> getTableIndexes(String connectionName, String tableName) async {
    final conn = _connections[connectionName];
    if (conn == null) {
      throw Exception('Connection not found: $connectionName');
    }
    
    try {
      final config = _configs[connectionName];
      if (config == null) {
        throw Exception('Configuration not found: $connectionName');
      }
      
      switch (config.type) {
        case DatabaseType.mysql:
          final result = await executeQuery(
            connectionName,
            'SHOW INDEX FROM ${tableName}',
          );
          
          final indexes = <IndexInfo>[];
          for (final row in result.rows) {
            indexes.add(IndexInfo(
              name: row[2] as String, // Key_name
              columnName: row[4] as String, // Column_name
              unique: (row[1] as int) == 0, // Non_unique (0 means unique)
              primary: row[2] == 'PRIMARY', // Key_name
            ));
          }
          
          return indexes;
          
        case DatabaseType.postgresql:
          final result = await executeQuery(
            connectionName,
            '''
            SELECT
                i.relname AS index_name,
                a.attname AS column_name,
                ix.indisunique AS is_unique,
                ix.indisprimary AS is_primary
            FROM
                pg_class t,
                pg_class i,
                pg_index ix,
                pg_attribute a
            WHERE
                t.oid = ix.indrelid
                AND i.oid = ix.indexrelid
                AND a.attrelid = t.oid
                AND a.attnum = ANY(ix.indkey)
                AND t.relkind = 'r'
                AND t.relname = '${tableName}'
            ORDER BY
                t.relname,
                i.relname;
            ''',
          );
          
          final indexes = <IndexInfo>[];
          for (final row in result.rows) {
            indexes.add(IndexInfo(
              name: row[0] as String, // index_name
              columnName: row[1] as String, // column_name
              unique: row[2] as bool, // is_unique
              primary: row[3] as bool, // is_primary
            ));
          }
          
          return indexes;
          
        case DatabaseType.sqlite:
          final result = await executeQuery(
            connectionName,
            'PRAGMA index_list(${tableName})',
          );
          
          final indexes = <IndexInfo>[];
          for (final indexRow in result.rows) {
            final indexName = indexRow[1] as String;
            final isUnique = (indexRow[2] as int) == 1;
            
            // 获取索引的列
            final indexInfoResult = await executeQuery(
              connectionName,
              'PRAGMA index_info(${indexName})',
            );
            
            for (final infoRow in indexInfoResult.rows) {
              final columnName = infoRow[2] as String;
              indexes.add(IndexInfo(
                name: indexName,
                columnName: columnName,
                unique: isUnique,
                primary: indexName == 'sqlite_autoindex_${tableName}_1', // SQLite主键索引命名约定
              ));
            }
          }
          
          return indexes;
          
        default:
          throw UnimplementedError('Unsupported database type: ${config.type}');
      }
    } catch (e) {
      debugPrint('Failed to get table indexes: $e');
      // 如果查询失败，返回空列表
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTableInfo(String connectionName, String tableName) async {
    final connection = _connections[connectionName];
    if (connection == null) {
      throw DatabaseException('Connection $connectionName not found');
    }

    try {
      if (connection is SqliteConnection) {
        final result = await executeQuery(connectionName, 'PRAGMA table_info(${tableName})');
        return result.rows.map((row) {
          return {
            'name': row[1] as String, // name
            'type': row[2] as String, // type
            'notnull': (row[3] as int) == 1, // notnull
            'pk': (row[5] as int) == 1, // pk
            'dflt_value': row[4], // dflt_value
          };
        }).toList();
      } else if (connection is MySqlConnection) {
        final result = await executeQuery(connectionName, 'SHOW COLUMNS FROM ${tableName}');
        return result.rows.map((row) {
          return {
            'name': row[0] as String, // Field
            'type': row[1] as String, // Type
            'notnull': row[2] == 'NO', // Null
            'pk': row[3] == 'PRI', // Key
            'dflt_value': row[4], // Default
          };
        }).toList();
      } else if (connection is PostgreSqlConnection) {
        final result = await executeQuery(connectionName, '''
          SELECT column_name, data_type, is_nullable, column_default,
                 (SELECT true FROM information_schema.key_column_usage
                  WHERE table_name = '${tableName}' AND column_name = columns.column_name
                  AND constraint_name IN (
                    SELECT constraint_name FROM information_schema.table_constraints
                    WHERE table_name = '${tableName}' AND constraint_type = 'PRIMARY KEY'
                  )
                 ) as is_primary_key
          FROM information_schema.columns
          WHERE table_name = '${tableName}'
          ORDER BY ordinal_position
        ''');
        
        return result.rows.map((row) {
          return {
            'name': row[0] as String, // column_name
            'type': row[1] as String, // data_type
            'notnull': row[2] == 'NO', // is_nullable
            'pk': row[4] == true, // is_primary_key
            'dflt_value': row[3], // column_default
          };
        }).toList();
      } else {
        throw DatabaseException('Unsupported connection type: ${connection.runtimeType}');
      }
    } catch (e) {
      throw DatabaseException('Error getting table info', e);
    }
  }

  Future<List<Map<String, dynamic>>> getTables(String connectionName) async {
    final connection = _connections[connectionName];
    if (connection == null) {
      throw DatabaseException('Connection $connectionName not found');
    }

    try {
      if (connection is SqliteConnection) {
        final result = await executeQuery(connectionName, 'SELECT name FROM sqlite_master WHERE type = ?', ['table']);
        return result.rows.map((row) => {
          'name': row[0] as String,
          'type': 'table',
        }).toList();
      } else if (connection is MySqlConnection) {
        final result = await executeQuery(connectionName, 'SHOW TABLES');
        return result.rows.map((row) => {
          'name': row[0] as String,
          'type': 'table',
        }).toList();
      } else if (connection is PostgreSqlConnection) {
        final result = await executeQuery(connectionName, 
          'SELECT table_name FROM information_schema.tables WHERE table_schema = \'public\'',
        );
        return result.rows.map((row) => {
          'name': row[0] as String,
          'type': 'table',
        }).toList();
      } else {
        throw DatabaseException('Unsupported connection type: ${connection.runtimeType}');
      }
    } catch (e) {
      throw DatabaseException('Error getting tables', e);
    }
  }

  Map<String, String> _parseMySqlConnectionString(String connectionString) {
    final uri = Uri.parse(connectionString.substring(6));
    return {
      'host': uri.host,
      'port': uri.port.toString(),
      'user': uri.userInfo.split(':')[0],
      'password': uri.userInfo.split(':')[1],
      'database': uri.path.substring(1),
    };
  }

  Map<String, String> _parsePostgresConnectionString(String connectionString) {
    final uri = Uri.parse(connectionString.substring(11));
    return {
      'host': uri.host,
      'port': uri.port.toString(),
      'user': uri.userInfo.split(':')[0],
      'password': uri.userInfo.split(':')[1],
      'database': uri.path.substring(1),
    };
  }

  Future<void> disconnect(String connectionName) async {
    try {
      final connection = _getConnection(connectionName);
      await connection.disconnect();
      _connections.remove(connectionName);
    } catch (e) {
      _logger.error('Failed to disconnect: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> disconnectAll() async {
    for (final connectionName in _connections.keys) {
      await disconnect(connectionName);
    }
  }
}

/// 数据库服务提供者
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
}); 