import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'database_service.dart';

/// 导出格式枚举
enum ExportFormat {
  csv,
  json,
  sql,
}

/// 数据传输服务
class DataTransferService {
  final DatabaseService _databaseService;
  
  DataTransferService(this._databaseService);

  /// 导出表结构
  Future<void> exportSchema({
    required String connectionName,
    required String tableName,
    required String filePath,
    ExportFormat format = ExportFormat.sql,
  }) async {
    try {
      final schema = await _databaseService.getSchema(connectionName);
      final tableSchema = schema[tableName];
      
      if (tableSchema == null) {
        throw Exception('Table not found: $tableName');
      }
      
      final file = File(filePath);
      String content;
      
      switch (format) {
        case ExportFormat.sql:
          content = _generateCreateTableSQL(tableName, tableSchema);
          break;
        case ExportFormat.json:
          content = jsonEncode({tableName: tableSchema});
          break;
        case ExportFormat.csv:
          content = _generateSchemaCSV(tableSchema);
          break;
      }
      
      await file.writeAsString(content);
    } catch (e) {
      debugPrint('Failed to export schema: $e');
      rethrow;
    }
  }
  
  /// 导出表数据
  Future<void> exportData({
    required String connectionName,
    required String tableName,
    required String filePath,
    ExportFormat format = ExportFormat.csv,
    int? batchSize,
  }) async {
    try {
      final file = File(filePath);
      final sink = file.openWrite();
      
      try {
        // 获取总行数
        final countResult = await _databaseService.executeQuery(
          connectionName,
          'SELECT COUNT(*) as count FROM $tableName',
        );
        final totalRows = int.parse(countResult.rows[0][0].toString());
        
        // 分批查询数据
        final pageSize = batchSize ?? 1000;
        var offset = 0;
        
        while (offset < totalRows) {
          final result = await _databaseService.executeQuery(
            connectionName,
            'SELECT * FROM $tableName LIMIT $pageSize OFFSET $offset',
          );
          
          if (offset == 0) {
            // 写入表头
            switch (format) {
              case ExportFormat.csv:
                sink.writeln(result.columns.join(','));
                break;
              case ExportFormat.json:
                sink.write('{"data":[');
                break;
              case ExportFormat.sql:
                sink.writeln('INSERT INTO $tableName (${result.columns.join(', ')}) VALUES');
                break;
            }
          }
          
          // 写入数据
          for (var i = 0; i < result.rows.length; i++) {
            final row = result.rows[i];
            switch (format) {
              case ExportFormat.csv:
                sink.writeln(row.map((cell) => _escapeCSV(cell)).join(','));
                break;
              case ExportFormat.json:
                if (offset > 0 || i > 0) sink.write(',');
                sink.write(jsonEncode(
                  Map.fromIterables(result.columns, row),
                ));
                break;
              case ExportFormat.sql:
                sink.write(
                  '(${row.map((cell) => _escapeSQLValue(cell)).join(', ')})'
                  '${offset + i + pageSize < totalRows ? ',' : ';'}\n'
                );
                break;
            }
          }
          
          offset += pageSize;
        }
        
        // 完成写入
        if (format == ExportFormat.json) {
          sink.write(']}');
        }
      } finally {
        await sink.close();
      }
    } catch (e) {
      debugPrint('Failed to export data: $e');
      rethrow;
    }
  }
  
  /// 导入数据
  Future<void> importData({
    required String connectionName,
    required String tableName,
    required String filePath,
    ExportFormat? format,
    bool truncateFirst = false,
    int? batchSize,
  }) async {
    try {
      // 自动检测格式
      format ??= _detectFormat(filePath);
      
      if (truncateFirst) {
        await _databaseService.executeQuery(
          connectionName,
          'TRUNCATE TABLE $tableName',
        );
      }
      
      final file = File(filePath);
      final content = await file.readAsString();
      
      switch (format) {
        case ExportFormat.csv:
          await _importCSV(
            connectionName: connectionName,
            tableName: tableName,
            content: content,
            batchSize: batchSize,
          );
          break;
        case ExportFormat.json:
          await _importJSON(
            connectionName: connectionName,
            tableName: tableName,
            content: content,
            batchSize: batchSize,
          );
          break;
        case ExportFormat.sql:
          await _databaseService.executeQuery(connectionName, content);
          break;
      }
    } catch (e) {
      debugPrint('Failed to import data: $e');
      rethrow;
    }
  }
  
  // 私有辅助方法
  
  String _generateCreateTableSQL(String tableName, List<dynamic> columns) {
    final buffer = StringBuffer();
    buffer.writeln('CREATE TABLE $tableName (');
    
    for (var i = 0; i < columns.length; i++) {
      final column = columns[i];
      buffer.write('  ${column['name']} ${column['type']}');
      
      if (column['notnull']) buffer.write(' NOT NULL');
      if (column['pk']) buffer.write(' PRIMARY KEY');
      
      if (i < columns.length - 1) buffer.writeln(',');
    }
    
    buffer.writeln('\n);');
    return buffer.toString();
  }
  
  String _generateSchemaCSV(List<dynamic> columns) {
    final header = ['Column', 'Type', 'Nullable', 'Primary Key'].join(',');
    final rows = columns.map((col) => [
      col['name'],
      col['type'],
      !col['notnull'],
      col['pk'],
    ].join(',')).join('\n');
    
    return '$header\n$rows';
  }
  
  String _escapeCSV(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(RegExp(r'[,"\n]'))) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }
  
  String _escapeSQLValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    return "'${value.toString().replaceAll("'", "''")}'";
  }
  
  ExportFormat _detectFormat(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.csv':
        return ExportFormat.csv;
      case '.json':
        return ExportFormat.json;
      case '.sql':
        return ExportFormat.sql;
      default:
        throw Exception('Unsupported file format: $ext');
    }
  }
  
  Future<void> _importCSV({
    required String connectionName,
    required String tableName,
    required String content,
    int? batchSize,
  }) async {
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) return;
    
    final columns = _parseCSVLine(lines.first);
    final values = lines.skip(1).map(_parseCSVLine).toList();
    
    await _batchInsert(
      connectionName: connectionName,
      tableName: tableName,
      columns: columns,
      values: values,
      batchSize: batchSize,
    );
  }
  
  Future<void> _importJSON({
    required String connectionName,
    required String tableName,
    required String content,
    int? batchSize,
  }) async {
    final json = jsonDecode(content) as Map<String, dynamic>;
    final data = json['data'] as List;
    if (data.isEmpty) return;
    
    final columns = data.first.keys.toList();
    final values = data.map((row) => 
      columns.map((col) => row[col]).toList()
    ).toList();
    
    await _batchInsert(
      connectionName: connectionName,
      tableName: tableName,
      columns: columns,
      values: values,
      batchSize: batchSize,
    );
  }
  
  Future<void> _batchInsert({
    required String connectionName,
    required String tableName,
    required List<String> columns,
    required List<List<dynamic>> values,
    int? batchSize,
  }) async {
    final pageSize = batchSize ?? 1000;
    
    for (var i = 0; i < values.length; i += pageSize) {
      final batch = values.skip(i).take(pageSize).toList();
      final sql = '''
        INSERT INTO $tableName (${columns.join(', ')})
        VALUES ${batch.map((row) => 
          '(${row.map((value) => _escapeSQLValue(value)).join(', ')})'
        ).join(',\n')}
      ''';
      
      await _databaseService.executeQuery(connectionName, sql);
    }
  }
  
  List<String> _parseCSVLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    StringBuffer? currentValue;
    
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        if (currentValue == null) {
          currentValue = StringBuffer();
          inQuotes = true;
        } else if (inQuotes) {
          if (i + 1 < line.length && line[i + 1] == '"') {
            currentValue.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          currentValue.write(char);
        }
      } else if (char == ',' && !inQuotes) {
        result.add(currentValue?.toString() ?? '');
        currentValue = null;
      } else {
        currentValue ??= StringBuffer();
        currentValue.write(char);
      }
    }
    
    if (currentValue != null) {
      result.add(currentValue.toString());
    }
    
    return result;
  }
}

/// 数据传输服务提供者
final dataTransferServiceProvider = Provider<DataTransferService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return DataTransferService(databaseService);
}); 