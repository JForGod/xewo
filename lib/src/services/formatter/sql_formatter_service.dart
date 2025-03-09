import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/core/settings_service.dart';

/// SQL代码格式化服务
class SqlFormatterService {
  final LoggerService _logger;
  final SettingsService _settings;
  
  /// 构造函数
  SqlFormatterService(this._logger, this._settings);
  
  /// 格式化SQL代码
  Future<String> formatCode(String code) async {
    try {
      // 获取格式化工具设置
      final formatterTool = _settings.getStringValue('editor.sql.formatter.tool', 'sql-formatter');
      
      switch (formatterTool) {
        case 'sql-formatter':
          return await _formatWithSqlFormatter(code);
        case 'pgFormatter':
          return await _formatWithPgFormatter(code);
        default:
          _logger.warning('不支持的SQL格式化工具: $formatterTool，使用默认格式化');
          return _defaultFormat(code);
      }
    } catch (e, stackTrace) {
      _logger.error('SQL代码格式化失败', e, stackTrace);
      return code; // 出错时返回原始代码
    }
  }
  
  /// 使用sql-formatter格式化代码
  Future<String> _formatWithSqlFormatter(String code) async {
    try {
      // 检查sql-formatter是否可用
      final result = await Process.run('npx', ['sql-formatter', '--version']);
      if (result.exitCode != 0) {
        _logger.warning('sql-formatter不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.sql'));
      await tempFile.writeAsString(code);
      
      // 获取sql-formatter配置
      final language = _settings.getStringValue('editor.sql.formatter.sqlFormatter.language', 'sql');
      final uppercase = _settings.getBoolValue('editor.sql.formatter.sqlFormatter.uppercase', false);
      final indentSize = _settings.getIntValue('editor.sql.formatter.sqlFormatter.indentSize', 2);
      
      // 运行sql-formatter
      final formatResult = await Process.run(
        'npx',
        [
          'sql-formatter',
          '--language', language,
          uppercase ? '--uppercase' : '--no-uppercase',
          '--indent', ' ' * indentSize,
          '--output', tempFile.path,
          tempFile.path,
        ],
      );
      
      // 读取格式化后的文件
      final formattedCode = await tempFile.readAsString();
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('sql-formatter执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formattedCode;
    } catch (e, stackTrace) {
      _logger.error('使用sql-formatter格式化失败', e, stackTrace);
      return _defaultFormat(code);
    }
  }
  
  /// 使用pgFormatter格式化代码
  Future<String> _formatWithPgFormatter(String code) async {
    try {
      // 检查pg_format是否可用
      final result = await Process.run('pg_format', ['--version']);
      if (result.exitCode != 0) {
        _logger.warning('pg_format不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.sql'));
      await tempFile.writeAsString(code);
      
      // 获取pgFormatter配置
      final spaces = _settings.getIntValue('editor.sql.formatter.pgFormatter.spaces', 4);
      final maxLength = _settings.getIntValue('editor.sql.formatter.pgFormatter.maxLength', 80);
      final noComment = _settings.getBoolValue('editor.sql.formatter.pgFormatter.noComment', false);
      final functionCase = _settings.getStringValue('editor.sql.formatter.pgFormatter.functionCase', 'unchanged');
      final keywordCase = _settings.getStringValue('editor.sql.formatter.pgFormatter.keywordCase', 'unchanged');
      
      // 构建参数
      final args = <String>[
        '--spaces', '$spaces',
        '--maxlength', '$maxLength',
      ];
      
      // 添加可选参数
      if (noComment) {
        args.add('--nocomment');
      }
      
      if (functionCase != 'unchanged') {
        args.add('--function-case');
        args.add(functionCase);
      }
      
      if (keywordCase != 'unchanged') {
        args.add('--keyword-case');
        args.add(keywordCase);
      }
      
      // 添加文件路径
      args.add(tempFile.path);
      
      // 运行pg_format
      final formatResult = await Process.run('pg_format', args);
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('pg_format执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formatResult.stdout as String;
    } catch (e, stackTrace) {
      _logger.error('使用pg_format格式化失败', e, stackTrace);
      return _defaultFormat(code);
    }
  }
  
  /// 默认格式化（简单的缩进和关键字处理）
  String _defaultFormat(String code) {
    try {
      final lines = LineSplitter.split(code).toList();
      final formattedLines = <String>[];
      int indentLevel = 0;
      
      // SQL关键字列表
      final keywords = [
        'SELECT', 'FROM', 'WHERE', 'GROUP BY', 'HAVING', 'ORDER BY',
        'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'ALTER', 'DROP',
        'JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'INNER JOIN', 'OUTER JOIN',
        'UNION', 'INTERSECT', 'EXCEPT',
      ];
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        
        // 跳过空行
        if (trimmedLine.isEmpty) {
          formattedLines.add('');
          continue;
        }
        
        // 处理缩进级别
        if (trimmedLine.toUpperCase().startsWith('END') || 
            trimmedLine.toUpperCase().startsWith(')')) {
          indentLevel = indentLevel > 0 ? indentLevel - 1 : 0;
        }
        
        // 添加缩进
        final indent = '  ' * indentLevel;
        
        // 格式化SQL关键字
        String formattedLine = trimmedLine;
        for (final keyword in keywords) {
          final pattern = RegExp(r'\b' + keyword + r'\b', caseSensitive: false);
          formattedLine = formattedLine.replaceAllMapped(pattern, (match) => keyword.toUpperCase());
        }
        
        formattedLines.add('$indent$formattedLine');
        
        // 更新缩进级别
        if (trimmedLine.toUpperCase().contains('BEGIN') || 
            trimmedLine.endsWith('(')) {
          indentLevel++;
        }
      }
      
      return formattedLines.join('\n');
    } catch (e, stackTrace) {
      _logger.error('默认格式化失败', e, stackTrace);
      return code;
    }
  }
}

/// SQL格式化服务提供者
final sqlFormatterServiceProvider = Provider<SqlFormatterService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final settings = ref.watch(settingsServiceProvider);
  return SqlFormatterService(logger, settings);
}); 