import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/core/settings_service.dart';
import 'package:xewo/src/services/formatter/dart_formatter_service.dart';
import 'package:xewo/src/services/formatter/json_formatter_service.dart';
import 'package:xewo/src/services/formatter/cpp_formatter_service.dart';
import 'package:xewo/src/services/formatter/python_formatter_service.dart';
import 'package:xewo/src/services/formatter/javascript_formatter_service.dart';
import 'package:xewo/src/services/formatter/html_formatter_service.dart';
import 'package:xewo/src/services/formatter/css_formatter_service.dart';
import 'package:xewo/src/services/formatter/sql_formatter_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// 格式化配置
class FormatterConfig {
  final bool formatOnSave;
  final bool formatOnPaste;
  final bool formatOnType;
  final int indentSize;
  final bool useSpaces;
  final bool semicolons;
  final bool singleQuote;
  final int printWidth;

  const FormatterConfig({
    this.formatOnSave = true,
    this.formatOnPaste = false,
    this.formatOnType = false,
    this.indentSize = 2,
    this.useSpaces = true,
    this.semicolons = true,
    this.singleQuote = true,
    this.printWidth = 80,
  });
  
  /// 从设置服务创建配置
  factory FormatterConfig.fromSettings(SettingsService settings) {
    return FormatterConfig(
      formatOnSave: settings.getBoolValue('editor.formatOnSave', true),
      formatOnPaste: settings.getBoolValue('editor.formatOnPaste', false),
      formatOnType: settings.getBoolValue('editor.formatOnType', false),
      indentSize: settings.getIntValue('editor.indentSize', 2),
      useSpaces: settings.getBoolValue('editor.useSpaces', true),
      semicolons: settings.getBoolValue('editor.semicolons', true),
      singleQuote: settings.getBoolValue('editor.singleQuote', true),
      printWidth: settings.getIntValue('editor.printWidth', 80),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'formatOnSave': formatOnSave,
      'formatOnPaste': formatOnPaste,
      'formatOnType': formatOnType,
      'indentSize': indentSize,
      'useSpaces': useSpaces,
      'semicolons': semicolons,
      'singleQuote': singleQuote,
      'printWidth': printWidth,
    };
  }
  
  /// 创建配置副本
  FormatterConfig copyWith({
    bool? formatOnSave,
    bool? formatOnPaste,
    bool? formatOnType,
    int? indentSize,
    bool? useSpaces,
    bool? semicolons,
    bool? singleQuote,
    int? printWidth,
  }) {
    return FormatterConfig(
      formatOnSave: formatOnSave ?? this.formatOnSave,
      formatOnPaste: formatOnPaste ?? this.formatOnPaste,
      formatOnType: formatOnType ?? this.formatOnType,
      indentSize: indentSize ?? this.indentSize,
      useSpaces: useSpaces ?? this.useSpaces,
      semicolons: semicolons ?? this.semicolons,
      singleQuote: singleQuote ?? this.singleQuote,
      printWidth: printWidth ?? this.printWidth,
    );
  }
}

/// 格式化服务管理器
class FormatterManager {
  /// 格式化配置
  final FormatterConfig _config = const FormatterConfig();

  /// 构造函数
  FormatterManager();
  
  /// 获取格式化配置
  FormatterConfig get config => _config;

  /// 是否在保存时格式化
  bool get formatOnSave => _config.formatOnSave;
  
  /// 是否在粘贴时格式化
  bool get formatOnPaste => _config.formatOnPaste;
  
  /// 是否在输入时格式化
  bool get formatOnType => _config.formatOnType;
  
  /// 格式化代码
  Future<String> formatCode(String code, String language) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        return _formatCodeInWeb(code, language);
      } else {
        // 桌面平台实现
        return await _formatCodeInDesktop(code, language);
      }
    } catch (e) {
      throw Exception('格式化代码失败: $e');
    }
  }

  /// Web平台格式化代码
  String _formatCodeInWeb(String code, String language) {
    // Web平台暂时只进行简单的缩进处理
    return _simpleFormat(code, language);
  }

  /// 桌面平台格式化代码
  Future<String> _formatCodeInDesktop(String code, String language) async {
    switch (language) {
      case 'dart':
        return await _formatDartCode(code);
      case 'javascript':
      case 'typescript':
      case 'json':
        return await _formatJsCode(code);
      case 'html':
      case 'xml':
        return await _formatHtmlCode(code);
      case 'css':
        return await _formatCssCode(code);
      case 'python':
        return await _formatPythonCode(code);
      default:
        return _simpleFormat(code, language);
    }
  }

  /// 格式化Dart代码
  Future<String> _formatDartCode(String code) async {
    try {
      // 创建临时文件
      final tempDir = await Directory.systemTemp.createTemp('dart_format_');
      final tempFile = File(path.join(tempDir.path, 'temp.dart'));
      await tempFile.writeAsString(code);

      // 使用dart format命令格式化代码
      final result = await Process.run('dart', ['format', tempFile.path]);
      
      if (result.exitCode != 0) {
        throw Exception('Dart格式化失败: ${result.stderr}');
      }
      
      // 读取格式化后的代码
      final formattedCode = await tempFile.readAsString();
      
      // 清理临时文件
      await tempFile.delete();
      await tempDir.delete(recursive: true);
      
      return formattedCode;
    } catch (e) {
      // 如果外部命令失败，使用简单格式化
      return _simpleFormat(code, 'dart');
    }
  }

  /// 格式化JavaScript/TypeScript代码
  Future<String> _formatJsCode(String code) async {
    try {
      // 创建临时文件
      final tempDir = await Directory.systemTemp.createTemp('js_format_');
      final tempFile = File(path.join(tempDir.path, 'temp.js'));
      await tempFile.writeAsString(code);

      // 尝试使用prettier格式化代码
      final result = await Process.run('npx', ['prettier', '--write', tempFile.path]);
      
      if (result.exitCode != 0) {
        throw Exception('JavaScript格式化失败: ${result.stderr}');
      }
      
      // 读取格式化后的代码
      final formattedCode = await tempFile.readAsString();
      
      // 清理临时文件
      await tempFile.delete();
      await tempDir.delete(recursive: true);
      
      return formattedCode;
    } catch (e) {
      // 如果外部命令失败，使用简单格式化
      return _simpleFormat(code, 'javascript');
    }
  }

  /// 格式化HTML代码
  Future<String> _formatHtmlCode(String code) async {
    try {
      // 创建临时文件
      final tempDir = await Directory.systemTemp.createTemp('html_format_');
      final tempFile = File(path.join(tempDir.path, 'temp.html'));
      await tempFile.writeAsString(code);

      // 尝试使用prettier格式化代码
      final result = await Process.run('npx', ['prettier', '--write', tempFile.path]);
      
      if (result.exitCode != 0) {
        throw Exception('HTML格式化失败: ${result.stderr}');
      }
      
      // 读取格式化后的代码
      final formattedCode = await tempFile.readAsString();
      
      // 清理临时文件
      await tempFile.delete();
      await tempDir.delete(recursive: true);
      
      return formattedCode;
    } catch (e) {
      // 如果外部命令失败，使用简单格式化
      return _simpleFormat(code, 'html');
    }
  }

  /// 格式化CSS代码
  Future<String> _formatCssCode(String code) async {
    try {
      // 创建临时文件
      final tempDir = await Directory.systemTemp.createTemp('css_format_');
      final tempFile = File(path.join(tempDir.path, 'temp.css'));
      await tempFile.writeAsString(code);

      // 尝试使用prettier格式化代码
      final result = await Process.run('npx', ['prettier', '--write', tempFile.path]);
      
      if (result.exitCode != 0) {
        throw Exception('CSS格式化失败: ${result.stderr}');
      }
      
      // 读取格式化后的代码
      final formattedCode = await tempFile.readAsString();
      
      // 清理临时文件
      await tempFile.delete();
      await tempDir.delete(recursive: true);
      
      return formattedCode;
    } catch (e) {
      // 如果外部命令失败，使用简单格式化
      return _simpleFormat(code, 'css');
    }
  }

  /// 格式化Python代码
  Future<String> _formatPythonCode(String code) async {
    try {
      // 创建临时文件
      final tempDir = await Directory.systemTemp.createTemp('python_format_');
      final tempFile = File(path.join(tempDir.path, 'temp.py'));
      await tempFile.writeAsString(code);

      // 尝试使用black格式化代码
      final result = await Process.run('black', [tempFile.path]);
      
      if (result.exitCode != 0) {
        throw Exception('Python格式化失败: ${result.stderr}');
      }
      
      // 读取格式化后的代码
      final formattedCode = await tempFile.readAsString();
      
      // 清理临时文件
      await tempFile.delete();
      await tempDir.delete(recursive: true);
      
      return formattedCode;
    } catch (e) {
      // 如果外部命令失败，使用简单格式化
      return _simpleFormat(code, 'python');
    }
  }

  /// 简单格式化代码（当外部工具不可用时）
  String _simpleFormat(String code, String language) {
    // 按行分割代码
    final lines = LineSplitter.split(code).toList();
    final formattedLines = <String>[];
    
    int indentLevel = 0;
    final indentSize = 2;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // 跳过空行
      if (trimmedLine.isEmpty) {
        formattedLines.add('');
        continue;
      }
      
      // 根据语言特性调整缩进
      if (_shouldDecreaseIndent(trimmedLine, language)) {
        indentLevel = indentLevel > 0 ? indentLevel - 1 : 0;
      }
      
      // 添加缩进后的行
      final indent = ' ' * (indentLevel * indentSize);
      formattedLines.add('$indent$trimmedLine');
      
      // 根据语言特性增加缩进
      if (_shouldIncreaseIndent(trimmedLine, language)) {
        indentLevel++;
      }
    }
    
    return formattedLines.join('\n');
  }

  /// 判断是否应该减少缩进
  bool _shouldDecreaseIndent(String line, String language) {
    switch (language) {
      case 'dart':
      case 'javascript':
      case 'typescript':
      case 'java':
      case 'c':
      case 'cpp':
      case 'csharp':
        return line.startsWith('}') || line.startsWith(')');
      case 'python':
        return line.startsWith('return') || 
               line.startsWith('break') || 
               line.startsWith('continue') || 
               line.startsWith('pass') ||
               line.startsWith('else:') ||
               line.startsWith('elif ');
      case 'html':
      case 'xml':
        return line.startsWith('</') || line.endsWith('/>');
      default:
        return false;
    }
  }

  /// 判断是否应该增加缩进
  bool _shouldIncreaseIndent(String line, String language) {
    switch (language) {
      case 'dart':
      case 'javascript':
      case 'typescript':
      case 'java':
      case 'c':
      case 'cpp':
      case 'csharp':
        return line.endsWith('{') || 
               (line.endsWith('(') && !line.startsWith('('));
      case 'python':
        return line.endsWith(':');
      case 'html':
      case 'xml':
        return line.startsWith('<') && 
               !line.startsWith('</') && 
               !line.endsWith('/>') && 
               !line.endsWith('>');
      default:
        return false;
    }
  }
  
  /// 根据文件扩展名格式化代码
  Future<String> formatByFileExtension(String code, String filePath) async {
    final extension = filePath.split('.').last.toLowerCase();
    return formatCode(code, extension);
  }
  
  /// 获取支持的语言列表
  List<String> getSupportedLanguages() {
    return [
      'dart',
      'json',
      'cpp', 'c', 'cc', 'cxx', 'h', 'hpp', 'hxx',
      'python', 'py',
      'javascript', 'js', 'typescript', 'ts', 'jsx', 'tsx',
      'html', 'xml', 'svg',
      'css', 'scss', 'less',
      'sql',
    ];
  }
  
  /// 检查语言是否支持格式化
  bool isLanguageSupported(String language) {
    return getSupportedLanguages().contains(language.toLowerCase());
  }
}

/// 格式化服务管理器提供者
final formatterManagerProvider = Provider<FormatterManager>((ref) {
  return FormatterManager();
});

/// 格式化服务提供者
final formatterProvider = Provider<FormatterManager>((ref) {
  return ref.watch(formatterManagerProvider);
}); 