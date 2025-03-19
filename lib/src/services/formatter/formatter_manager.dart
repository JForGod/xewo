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
import 'package:path/path.dart' as path;

/// 格式化规则配置
class FormatterConfig {
  /// 是否在保存时自动格式化
  final bool formatOnSave;
  
  /// 是否在粘贴时自动格式化
  final bool formatOnPaste;
  
  /// 是否在输入时自动格式化
  final bool formatOnType;
  
  /// 缩进大小
  final int indentSize;
  
  /// 使用空格而不是制表符
  final bool useSpaces;
  
  /// 行尾分号
  final bool semicolons;
  
  /// 单引号或双引号
  final bool singleQuote;
  
  /// 行宽限制
  final int printWidth;
  
  /// 构造函数
  FormatterConfig({
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
  final LoggerService _logger;
  final SettingsService _settings;
  final DartFormatterService _dartFormatter;
  final JsonFormatterService _jsonFormatter;
  final CppFormatterService _cppFormatter;
  final PythonFormatterService _pythonFormatter;
  final JavaScriptFormatterService _javascriptFormatter;
  final HtmlFormatterService _htmlFormatter;
  final CssFormatterService _cssFormatter;
  final SqlFormatterService _sqlFormatter;
  
  /// 格式化配置
  late FormatterConfig _config;
  
  /// 构造函数
  FormatterManager(
    this._logger,
    this._settings,
    this._dartFormatter,
    this._jsonFormatter,
    this._cppFormatter,
    this._pythonFormatter,
    this._javascriptFormatter,
    this._htmlFormatter,
    this._cssFormatter,
    this._sqlFormatter,
  ) {
    _config = FormatterConfig.fromSettings(_settings);
  }
  
  /// 获取格式化配置
  FormatterConfig get config => _config;
  
  /// 更新格式化配置
  void updateConfig(FormatterConfig newConfig) {
    _config = newConfig;
    
    // 保存配置到设置
    _settings.setBoolValue('editor.formatOnSave', newConfig.formatOnSave);
    _settings.setBoolValue('editor.formatOnPaste', newConfig.formatOnPaste);
    _settings.setBoolValue('editor.formatOnType', newConfig.formatOnType);
    _settings.setIntValue('editor.indentSize', newConfig.indentSize);
    _settings.setBoolValue('editor.useSpaces', newConfig.useSpaces);
    _settings.setBoolValue('editor.semicolons', newConfig.semicolons);
    _settings.setBoolValue('editor.singleQuote', newConfig.singleQuote);
    _settings.setIntValue('editor.printWidth', newConfig.printWidth);
  }
  
  /// 格式化代码
  Future<String> formatCode(String code, String language) async {
    switch (language.toLowerCase()) {
      case 'dart':
        return await _formatDartCode(code);
      case 'json':
        return _formatJsonCode(code);
      case 'javascript':
      case 'js':
        return await _formatJavaScriptCode(code);
      case 'typescript':
      case 'ts':
        return await _formatTypeScriptCode(code);
      case 'html':
        return await _formatHtmlCode(code);
      case 'css':
        return await _formatCssCode(code);
      case 'python':
      case 'py':
        return await _formatPythonCode(code);
      default:
        // 如果不支持该语言的格式化，则返回原始代码
        return code;
    }
  }
  
  /// 根据文件扩展名格式化代码
  Future<String> formatByFileExtension(String code, String filePath) async {
    final extension = filePath.split('.').last.toLowerCase();
    return formatCode(code, extension);
  }
  
  /// 检查是否应该在保存时格式化
  bool shouldFormatOnSave() {
    return _config.formatOnSave;
  }
  
  /// 检查是否应该在粘贴时格式化
  bool shouldFormatOnPaste() {
    return _config.formatOnPaste;
  }
  
  /// 检查是否应该在输入时格式化
  bool shouldFormatOnType() {
    return _config.formatOnType;
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

  Future<String> _formatDartCode(String code) async {
    try {
      // 创建临时文件
      final tempFile = File('${Directory.systemTemp.path}/temp_format.dart');
      await tempFile.writeAsString(code);
      
      // 使用dart format命令格式化代码
      final result = await Process.run('dart', ['format', tempFile.path]);
      if (result.exitCode == 0) {
        final formatted = await tempFile.readAsString();
        await tempFile.delete();
        return formatted;
      }
      await tempFile.delete();
      throw Exception(result.stderr);
    } catch (e) {
      return code;
    }
  }

  String _formatJsonCode(String code) {
    try {
      final jsonObject = json.decode(code);
      return JsonEncoder.withIndent('  ').convert(jsonObject);
    } catch (e) {
      // 如果解析失败，返回原始代码
      return code;
    }
  }

  Future<String> _formatJavaScriptCode(String code) async {
    // Implementation of _formatJavaScriptCode method
    return code; // Placeholder return, actual implementation needed
  }

  Future<String> _formatTypeScriptCode(String code) async {
    // Implementation of _formatTypeScriptCode method
    return code; // Placeholder return, actual implementation needed
  }

  Future<String> _formatHtmlCode(String code) async {
    // Implementation of _formatHtmlCode method
    return code; // Placeholder return, actual implementation needed
  }

  Future<String> _formatCssCode(String code) async {
    // Implementation of _formatCssCode method
    return code; // Placeholder return, actual implementation needed
  }

  Future<String> _formatPythonCode(String code) async {
    // Implementation of _formatPythonCode method
    return code; // Placeholder return, actual implementation needed
  }
}

/// 格式化服务管理器提供者
final formatterManagerProvider = Provider<FormatterManager>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final settings = ref.watch(settingsServiceProvider);
  final dartFormatter = ref.watch(dartFormatterServiceProvider);
  final jsonFormatter = ref.watch(jsonFormatterServiceProvider);
  final cppFormatter = ref.watch(cppFormatterServiceProvider);
  final pythonFormatter = ref.watch(pythonFormatterServiceProvider);
  final javascriptFormatter = ref.watch(javascriptFormatterServiceProvider);
  final htmlFormatter = ref.watch(htmlFormatterServiceProvider);
  final cssFormatter = ref.watch(cssFormatterServiceProvider);
  final sqlFormatter = ref.watch(sqlFormatterServiceProvider);
  
  return FormatterManager(
    logger,
    settings,
    dartFormatter,
    jsonFormatter,
    cppFormatter,
    pythonFormatter,
    javascriptFormatter,
    htmlFormatter,
    cssFormatter,
    sqlFormatter,
  );
});

/// 格式化服务提供者
final formatterProvider = Provider<FormatterManager>((ref) {
  return ref.watch(formatterManagerProvider);
}); 