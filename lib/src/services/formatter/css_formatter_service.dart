import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/core/settings_service.dart';

/// CSS代码格式化服务
class CssFormatterService {
  final LoggerService _logger;
  final SettingsService _settings;
  
  /// 构造函数
  CssFormatterService(this._logger, this._settings);
  
  /// 格式化CSS代码
  Future<String> formatCode(String code) async {
    try {
      // 获取格式化工具设置
      final formatterTool = _settings.getStringValue('editor.css.formatter.tool', 'prettier');
      
      switch (formatterTool) {
        case 'prettier':
          return await _formatWithPrettier(code);
        case 'stylelint':
          return await _formatWithStylelint(code);
        default:
          _logger.warning('不支持的CSS格式化工具: $formatterTool，使用默认格式化');
          return _defaultFormat(code);
      }
    } catch (e, stackTrace) {
      _logger.error('CSS代码格式化失败', e, stackTrace);
      return code; // 出错时返回原始代码
    }
  }
  
  /// 使用Prettier格式化代码
  Future<String> _formatWithPrettier(String code) async {
    try {
      // 检查prettier是否可用
      final result = await Process.run('npx', ['prettier', '--version']);
      if (result.exitCode != 0) {
        _logger.warning('prettier不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.css'));
      await tempFile.writeAsString(code);
      
      // 获取prettier配置
      final printWidth = _settings.getIntValue('editor.css.formatter.prettier.printWidth', 80);
      final tabWidth = _settings.getIntValue('editor.css.formatter.prettier.tabWidth', 2);
      final useTabs = _settings.getBoolValue('editor.css.formatter.prettier.useTabs', false);
      
      // 运行prettier
      final formatResult = await Process.run(
        'npx',
        [
          'prettier',
          '--print-width', '$printWidth',
          '--tab-width', '$tabWidth',
          useTabs ? '--use-tabs' : '--no-use-tabs',
          '--parser', 'css',
          '--write',
          tempFile.path,
        ],
      );
      
      // 读取格式化后的文件
      final formattedCode = await tempFile.readAsString();
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('prettier执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formattedCode;
    } catch (e, stackTrace) {
      _logger.error('使用prettier格式化失败', e, stackTrace);
      return _defaultFormat(code);
    }
  }
  
  /// 使用Stylelint格式化代码
  Future<String> _formatWithStylelint(String code) async {
    try {
      // 检查stylelint是否可用
      final result = await Process.run('npx', ['stylelint', '--version']);
      if (result.exitCode != 0) {
        _logger.warning('stylelint不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.css'));
      await tempFile.writeAsString(code);
      
      // 运行stylelint
      final formatResult = await Process.run(
        'npx',
        [
          'stylelint',
          '--fix',
          tempFile.path,
        ],
      );
      
      // 读取格式化后的文件
      final formattedCode = await tempFile.readAsString();
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('stylelint执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formattedCode;
    } catch (e, stackTrace) {
      _logger.error('使用stylelint格式化失败', e, stackTrace);
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
        if (trimmedLine.startsWith('}')) {
          indentLevel = indentLevel > 0 ? indentLevel - 1 : 0;
        }
        
        // 添加缩进
        final indent = '  ' * indentLevel;
        formattedLines.add('$indent$trimmedLine');
        
        // 更新缩进级别
        if (trimmedLine.endsWith('{')) {
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

/// CSS格式化服务提供者
final cssFormatterServiceProvider = Provider<CssFormatterService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final settings = ref.watch(settingsServiceProvider);
  return CssFormatterService(logger, settings);
}); 