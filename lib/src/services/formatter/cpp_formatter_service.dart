import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/core/settings_service.dart';

/// C++代码格式化服务
class CppFormatterService {
  final LoggerService _logger;
  final SettingsService _settings;
  
  /// 构造函数
  CppFormatterService(this._logger, this._settings);
  
  /// 格式化C++代码
  Future<String> formatCode(String code) async {
    try {
      // 获取格式化工具设置
      final formatterTool = _settings.getStringValue('editor.cpp.formatter.tool', 'clang-format');
      
      switch (formatterTool) {
        case 'clang-format':
          return await _formatWithClangFormat(code);
        case 'astyle':
          return await _formatWithAStyle(code);
        default:
          _logger.warning('不支持的C++格式化工具: $formatterTool，使用默认格式化');
          return _defaultFormat(code);
      }
    } catch (e, stackTrace) {
      _logger.error('C++代码格式化失败', e, stackTrace);
      return code; // 出错时返回原始代码
    }
  }
  
  /// 使用clang-format格式化代码
  Future<String> _formatWithClangFormat(String code) async {
    try {
      // 检查clang-format是否可用
      final result = await Process.run('clang-format', ['--version']);
      if (result.exitCode != 0) {
        _logger.warning('clang-format不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 获取clang-format样式设置
      final style = _settings.getStringValue('editor.cpp.formatter.clangFormat.style', 'Google');
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.cpp'));
      await tempFile.writeAsString(code);
      
      // 运行clang-format
      final formatResult = await Process.run(
        'clang-format',
        ['-style=$style', tempFile.path],
      );
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('clang-format执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formatResult.stdout as String;
    } catch (e, stackTrace) {
      _logger.error('使用clang-format格式化失败', e, stackTrace);
      return _defaultFormat(code);
    }
  }
  
  /// 使用AStyle格式化代码
  Future<String> _formatWithAStyle(String code) async {
    try {
      // 检查astyle是否可用
      final result = await Process.run('astyle', ['--version']);
      if (result.exitCode != 0) {
        _logger.warning('astyle不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 获取astyle样式设置
      final style = _settings.getStringValue('editor.cpp.formatter.astyle.style', 'google');
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.cpp'));
      await tempFile.writeAsString(code);
      
      // 构建astyle参数
      final args = <String>[];
      
      // 添加样式
      switch (style) {
        case 'google':
          args.addAll(['--style=google']);
          break;
        case 'allman':
          args.addAll(['--style=allman']);
          break;
        case 'java':
          args.addAll(['--style=java']);
          break;
        case 'kr':
          args.addAll(['--style=kr']);
          break;
        case 'stroustrup':
          args.addAll(['--style=stroustrup']);
          break;
        case 'whitesmith':
          args.addAll(['--style=whitesmith']);
          break;
        case 'banner':
          args.addAll(['--style=banner']);
          break;
        case 'gnu':
          args.addAll(['--style=gnu']);
          break;
        case 'linux':
          args.addAll(['--style=linux']);
          break;
        case 'horstmann':
          args.addAll(['--style=horstmann']);
          break;
        case '1tbs':
          args.addAll(['--style=1tbs']);
          break;
        case 'pico':
          args.addAll(['--style=pico']);
          break;
        case 'lisp':
          args.addAll(['--style=lisp']);
          break;
        default:
          args.addAll(['--style=google']);
          break;
      }
      
      // 添加其他选项
      final indentSpaces = _settings.getIntValue('editor.cpp.formatter.astyle.indentSpaces', 2);
      args.add('--indent=spaces=$indentSpaces');
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.attachNamespaces', false)) {
        args.add('--attach-namespaces');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.attachClasses', false)) {
        args.add('--attach-classes');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.attachInlines', false)) {
        args.add('--attach-inlines');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.attachExternC', false)) {
        args.add('--attach-extern-c');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.indentCases', false)) {
        args.add('--indent-cases');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.indentNamespaces', false)) {
        args.add('--indent-namespaces');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.indentLabels', false)) {
        args.add('--indent-labels');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.indentPreprocessor', false)) {
        args.add('--indent-preprocessor');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.indentComments', true)) {
        args.add('--indent-col1-comments');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.breakBlocks', false)) {
        args.add('--break-blocks');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.padOperators', true)) {
        args.add('--pad-oper');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.padParentheses', false)) {
        args.add('--pad-paren');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.alignPointers', false)) {
        args.add('--align-pointer=name');
      }
      
      if (_settings.getBoolValue('editor.cpp.formatter.astyle.alignReferences', false)) {
        args.add('--align-reference=name');
      }
      
      // 添加文件路径
      args.add(tempFile.path);
      
      // 运行astyle
      final formatResult = await Process.run('astyle', args);
      
      // 读取格式化后的文件
      final formattedCode = await tempFile.readAsString();
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('astyle执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formattedCode;
    } catch (e, stackTrace) {
      _logger.error('使用astyle格式化失败', e, stackTrace);
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
            !trimmedLine.startsWith('catch')) {
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

/// C++格式化服务提供者
final cppFormatterServiceProvider = Provider<CppFormatterService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final settings = ref.watch(settingsServiceProvider);
  return CppFormatterService(logger, settings);
}); 