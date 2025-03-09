import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/core/settings_service.dart';

/// Dart代码格式化服务
class DartFormatterService {
  final LoggerService _logger;
  final SettingsService _settings;
  
  /// 构造函数
  DartFormatterService(this._logger, this._settings);
  
  /// 格式化Dart代码
  Future<String> formatCode(String code) async {
    try {
      // 获取格式化工具设置
      final formatterTool = _settings.getStringValue('editor.dart.formatter.tool', 'dart format');
      
      switch (formatterTool) {
        case 'dart format':
          return await _formatWithDartFormat(code);
        default:
          _logger.warning('不支持的Dart格式化工具: $formatterTool，使用默认格式化');
          return _defaultFormat(code);
      }
    } catch (e, stackTrace) {
      _logger.error('Dart代码格式化失败', e, stackTrace);
      return code; // 出错时返回原始代码
    }
  }
  
  /// 使用dart format格式化代码
  Future<String> _formatWithDartFormat(String code) async {
    try {
      // 检查dart是否可用
      final result = await Process.run('dart', ['--version']);
      if (result.exitCode != 0) {
        _logger.warning('dart不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.dart'));
      await tempFile.writeAsString(code);
      
      // 获取dart format配置
      final lineLength = _settings.getIntValue('editor.dart.formatter.lineLength', 80);
      
      // 运行dart format
      final formatResult = await Process.run(
        'dart',
        [
          'format',
          '--line-length=$lineLength',
          tempFile.path,
        ],
      );
      
      // 读取格式化后的文件
      final formattedCode = await tempFile.readAsString();
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('dart format执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formattedCode;
    } catch (e, stackTrace) {
      _logger.error('使用dart format格式化失败', e, stackTrace);
      return _defaultFormat(code);
    }
  }
  
  /// 默认格式化（简单的缩进和括号处理）
  String _defaultFormat(String code) {
    try {
      final lines = LineSplitter.split(code).toList();
      final formattedLines = <String>[];
      int indentLevel = 0;
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        
        // 跳过空行
        if (trimmedLine.isEmpty) {
          formattedLines.add('');
          continue;
        }
        
        // 处理缩进级别
        if (trimmedLine.startsWith('}') || 
            trimmedLine.startsWith(')')) {
          indentLevel = indentLevel > 0 ? indentLevel - 1 : 0;
        }
        
        // 添加缩进
        final indent = '  ' * indentLevel;
        formattedLines.add('$indent$trimmedLine');
        
        // 更新缩进级别
        if (trimmedLine.endsWith('{') || 
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

/// Dart格式化服务提供者
final dartFormatterServiceProvider = Provider<DartFormatterService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final settings = ref.watch(settingsServiceProvider);
  return DartFormatterService(logger, settings);
}); 