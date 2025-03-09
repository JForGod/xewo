import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/core/settings_service.dart';

/// JavaScript/TypeScript代码格式化服务
class JavaScriptFormatterService {
  final LoggerService _logger;
  final SettingsService _settings;
  
  /// 构造函数
  JavaScriptFormatterService(this._logger, this._settings);
  
  /// 格式化JavaScript/TypeScript代码
  Future<String> formatCode(String code) async {
    try {
      // 获取格式化工具设置
      final formatterTool = _settings.getStringValue('editor.javascript.formatter.tool', 'prettier');
      
      switch (formatterTool) {
        case 'prettier':
          return await _formatWithPrettier(code);
        case 'eslint':
          return await _formatWithEslint(code);
        default:
          _logger.warning('不支持的JavaScript/TypeScript格式化工具: $formatterTool，使用默认格式化');
          return _defaultFormat(code);
      }
    } catch (e, stackTrace) {
      _logger.error('JavaScript/TypeScript代码格式化失败', e, stackTrace);
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
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.js'));
      await tempFile.writeAsString(code);
      
      // 获取prettier配置
      final printWidth = _settings.getIntValue('editor.javascript.formatter.prettier.printWidth', 80);
      final tabWidth = _settings.getIntValue('editor.javascript.formatter.prettier.tabWidth', 2);
      final useTabs = _settings.getBoolValue('editor.javascript.formatter.prettier.useTabs', false);
      final semi = _settings.getBoolValue('editor.javascript.formatter.prettier.semi', true);
      final singleQuote = _settings.getBoolValue('editor.javascript.formatter.prettier.singleQuote', false);
      final trailingComma = _settings.getStringValue('editor.javascript.formatter.prettier.trailingComma', 'es5');
      final bracketSpacing = _settings.getBoolValue('editor.javascript.formatter.prettier.bracketSpacing', true);
      
      // 运行prettier
      final formatResult = await Process.run(
        'npx',
        [
          'prettier',
          '--print-width', '$printWidth',
          '--tab-width', '$tabWidth',
          useTabs ? '--use-tabs' : '--no-use-tabs',
          semi ? '--semi' : '--no-semi',
          singleQuote ? '--single-quote' : '--no-single-quote',
          '--trailing-comma', trailingComma,
          bracketSpacing ? '--bracket-spacing' : '--no-bracket-spacing',
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
  
  /// 使用ESLint格式化代码
  Future<String> _formatWithEslint(String code) async {
    try {
      // 检查eslint是否可用
      final result = await Process.run('npx', ['eslint', '--version']);
      if (result.exitCode != 0) {
        _logger.warning('eslint不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.js'));
      await tempFile.writeAsString(code);
      
      // 运行eslint
      final formatResult = await Process.run(
        'npx',
        [
          'eslint',
          '--fix',
          tempFile.path,
        ],
      );
      
      // 读取格式化后的文件
      final formattedCode = await tempFile.readAsString();
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('eslint执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formattedCode;
    } catch (e, stackTrace) {
      _logger.error('使用eslint格式化失败', e, stackTrace);
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
            trimmedLine.startsWith(')') || 
            trimmedLine.startsWith(']')) {
          indentLevel = indentLevel > 0 ? indentLevel - 1 : 0;
        }
        
        // 添加缩进
        final indent = '  ' * indentLevel;
        formattedLines.add('$indent$trimmedLine');
        
        // 更新缩进级别
        if (trimmedLine.endsWith('{') || 
            trimmedLine.endsWith('(') || 
            trimmedLine.endsWith('[')) {
          indentLevel++;
        }
        
        // 处理行尾的大括号
        if (trimmedLine.endsWith('}') && 
            !trimmedLine.startsWith('}') && 
            !trimmedLine.startsWith('else') && 
            !trimmedLine.startsWith('try') && 
            !trimmedLine.startsWith('catch') && 
            !trimmedLine.startsWith('finally')) {
          indentLevel = indentLevel > 0 ? indentLevel - 1 : 0;
        }
      }
      
      return formattedLines.join('\n');
    } catch (e, stackTrace) {
      _logger.error('默认格式化失败', e, stackTrace);
      return code;
    }
  }
}

/// JavaScript/TypeScript格式化服务提供者
final javascriptFormatterServiceProvider = Provider<JavaScriptFormatterService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final settings = ref.watch(settingsServiceProvider);
  return JavaScriptFormatterService(logger, settings);
}); 