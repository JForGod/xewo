import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/core/settings_service.dart';

/// HTML代码格式化服务
class HtmlFormatterService {
  final LoggerService _logger;
  final SettingsService _settings;
  
  /// 构造函数
  HtmlFormatterService(this._logger, this._settings);
  
  /// 格式化HTML代码
  Future<String> formatCode(String code) async {
    try {
      // 获取格式化工具设置
      final formatterTool = _settings.getStringValue('editor.html.formatter.tool', 'prettier');
      
      switch (formatterTool) {
        case 'prettier':
          return await _formatWithPrettier(code);
        case 'html-beautify':
          return await _formatWithHtmlBeautify(code);
        default:
          _logger.warning('不支持的HTML格式化工具: $formatterTool，使用默认格式化');
          return _defaultFormat(code);
      }
    } catch (e, stackTrace) {
      _logger.error('HTML代码格式化失败', e, stackTrace);
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
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.html'));
      await tempFile.writeAsString(code);
      
      // 获取prettier配置
      final printWidth = _settings.getIntValue('editor.html.formatter.prettier.printWidth', 80);
      final tabWidth = _settings.getIntValue('editor.html.formatter.prettier.tabWidth', 2);
      final useTabs = _settings.getBoolValue('editor.html.formatter.prettier.useTabs', false);
      
      // 运行prettier
      final formatResult = await Process.run(
        'npx',
        [
          'prettier',
          '--print-width', '$printWidth',
          '--tab-width', '$tabWidth',
          useTabs ? '--use-tabs' : '--no-use-tabs',
          '--parser', 'html',
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
  
  /// 使用html-beautify格式化代码
  Future<String> _formatWithHtmlBeautify(String code) async {
    try {
      // 检查html-beautify是否可用
      final result = await Process.run('npx', ['html-beautify', '--version']);
      if (result.exitCode != 0) {
        _logger.warning('html-beautify不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.html'));
      await tempFile.writeAsString(code);
      
      // 获取html-beautify配置
      final indentSize = _settings.getIntValue('editor.html.formatter.htmlBeautify.indentSize', 2);
      final maxPreserveNewlines = _settings.getIntValue('editor.html.formatter.htmlBeautify.maxPreserveNewlines', 1);
      final wrapLineLength = _settings.getIntValue('editor.html.formatter.htmlBeautify.wrapLineLength', 0);
      final unformattedTags = _settings.getStringValue('editor.html.formatter.htmlBeautify.unformattedTags', 'pre,code');
      
      // 运行html-beautify
      final formatResult = await Process.run(
        'npx',
        [
          'html-beautify',
          '--indent-size', '$indentSize',
          '--max-preserve-newlines', '$maxPreserveNewlines',
          '--wrap-line-length', '$wrapLineLength',
          '--unformatted', unformattedTags,
          '-r',
          tempFile.path,
        ],
      );
      
      // 读取格式化后的文件
      final formattedCode = await tempFile.readAsString();
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('html-beautify执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formattedCode;
    } catch (e, stackTrace) {
      _logger.error('使用html-beautify格式化失败', e, stackTrace);
      return _defaultFormat(code);
    }
  }
  
  /// 默认格式化（简单的缩进和标签处理）
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
        if (trimmedLine.startsWith('</') || 
            trimmedLine.startsWith('<!--') || 
            trimmedLine.endsWith('-->')) {
          // 结束标签或注释不改变缩进
        } else if (_isClosingTag(trimmedLine)) {
          indentLevel = indentLevel > 0 ? indentLevel - 1 : 0;
        }
        
        // 添加缩进
        final indent = '  ' * indentLevel;
        formattedLines.add('$indent$trimmedLine');
        
        // 更新下一行的缩进级别
        if (_isOpeningTag(trimmedLine) && !_isSelfClosingTag(trimmedLine)) {
          indentLevel++;
        }
      }
      
      return formattedLines.join('\n');
    } catch (e, stackTrace) {
      _logger.error('默认格式化失败', e, stackTrace);
      return code;
    }
  }
  
  /// 检查是否是开始标签
  bool _isOpeningTag(String line) {
    return RegExp(r'<[a-zA-Z][^>]*>').hasMatch(line) && !line.startsWith('</');
  }
  
  /// 检查是否是结束标签
  bool _isClosingTag(String line) {
    return line.startsWith('</') || line.contains('</');
  }
  
  /// 检查是否是自闭合标签
  bool _isSelfClosingTag(String line) {
    return line.endsWith('/>') || 
           RegExp(r'<(area|base|br|col|embed|hr|img|input|link|meta|param|source|track|wbr)[^>]*>').hasMatch(line);
  }
}

/// HTML格式化服务提供者
final htmlFormatterServiceProvider = Provider<HtmlFormatterService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final settings = ref.watch(settingsServiceProvider);
  return HtmlFormatterService(logger, settings);
}); 