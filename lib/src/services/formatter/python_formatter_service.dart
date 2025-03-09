import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/core/settings_service.dart';

/// Python代码格式化服务
class PythonFormatterService {
  final LoggerService _logger;
  final SettingsService _settings;
  
  /// 构造函数
  PythonFormatterService(this._logger, this._settings);
  
  /// 格式化Python代码
  Future<String> formatCode(String code) async {
    try {
      // 获取格式化工具设置
      final formatterTool = _settings.getStringValue('editor.python.formatter.tool', 'black');
      
      switch (formatterTool) {
        case 'black':
          return await _formatWithBlack(code);
        case 'yapf':
          return await _formatWithYapf(code);
        case 'autopep8':
          return await _formatWithAutopep8(code);
        default:
          _logger.warning('不支持的Python格式化工具: $formatterTool，使用默认格式化');
          return _defaultFormat(code);
      }
    } catch (e, stackTrace) {
      _logger.error('Python代码格式化失败', e, stackTrace);
      return code; // 出错时返回原始代码
    }
  }
  
  /// 使用Black格式化代码
  Future<String> _formatWithBlack(String code) async {
    try {
      // 检查black是否可用
      final result = await Process.run('black', ['--version']);
      if (result.exitCode != 0) {
        _logger.warning('black不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.py'));
      await tempFile.writeAsString(code);
      
      // 获取black配置
      final lineLength = _settings.getIntValue('editor.python.formatter.black.lineLength', 88);
      
      // 运行black
      final formatResult = await Process.run(
        'black',
        [
          '--quiet',
          '--line-length', '$lineLength',
          tempFile.path,
        ],
      );
      
      // 读取格式化后的文件
      final formattedCode = await tempFile.readAsString();
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('black执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formattedCode;
    } catch (e, stackTrace) {
      _logger.error('使用black格式化失败', e, stackTrace);
      return _defaultFormat(code);
    }
  }
  
  /// 使用YAPF格式化代码
  Future<String> _formatWithYapf(String code) async {
    try {
      // 检查yapf是否可用
      final result = await Process.run('yapf', ['--version']);
      if (result.exitCode != 0) {
        _logger.warning('yapf不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.py'));
      await tempFile.writeAsString(code);
      
      // 获取yapf配置
      final style = _settings.getStringValue('editor.python.formatter.yapf.style', 'pep8');
      
      // 运行yapf
      final formatResult = await Process.run(
        'yapf',
        [
          '--style=$style',
          tempFile.path,
        ],
      );
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('yapf执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formatResult.stdout as String;
    } catch (e, stackTrace) {
      _logger.error('使用yapf格式化失败', e, stackTrace);
      return _defaultFormat(code);
    }
  }
  
  /// 使用Autopep8格式化代码
  Future<String> _formatWithAutopep8(String code) async {
    try {
      // 检查autopep8是否可用
      final result = await Process.run('autopep8', ['--version']);
      if (result.exitCode != 0) {
        _logger.warning('autopep8不可用，使用默认格式化');
        return _defaultFormat(code);
      }
      
      // 创建临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.py'));
      await tempFile.writeAsString(code);
      
      // 获取autopep8配置
      final aggressive = _settings.getIntValue('editor.python.formatter.autopep8.aggressive', 1);
      final maxLineLength = _settings.getIntValue('editor.python.formatter.autopep8.maxLineLength', 79);
      
      // 构建参数
      final args = <String>[
        '--max-line-length', '$maxLineLength',
      ];
      
      // 添加激进程度
      for (int i = 0; i < aggressive; i++) {
        args.add('--aggressive');
      }
      
      // 添加文件路径
      args.add(tempFile.path);
      
      // 运行autopep8
      final formatResult = await Process.run('autopep8', args);
      
      // 删除临时文件
      await tempFile.delete();
      
      if (formatResult.exitCode != 0) {
        _logger.warning('autopep8执行失败: ${formatResult.stderr}');
        return _defaultFormat(code);
      }
      
      return formatResult.stdout as String;
    } catch (e, stackTrace) {
      _logger.error('使用autopep8格式化失败', e, stackTrace);
      return _defaultFormat(code);
    }
  }
  
  /// 默认格式化（简单的缩进和空行处理）
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
        if (trimmedLine.startsWith('return ') || 
            trimmedLine.startsWith('break') || 
            trimmedLine.startsWith('continue') || 
            trimmedLine.startsWith('raise ') || 
            trimmedLine.startsWith('pass')) {
          // 这些语句保持当前缩进级别
        } else if (trimmedLine.startsWith('elif ') || 
                   trimmedLine.startsWith('else:') || 
                   trimmedLine.startsWith('except ') || 
                   trimmedLine.startsWith('finally:')) {
          // 这些语句减少一级缩进
          indentLevel = indentLevel > 0 ? indentLevel - 1 : 0;
        } else if (trimmedLine.startsWith('def ') || 
                   trimmedLine.startsWith('class ') || 
                   trimmedLine.startsWith('if ') || 
                   trimmedLine.startsWith('for ') || 
                   trimmedLine.startsWith('while ') || 
                   trimmedLine.startsWith('try:')) {
          // 这些语句不改变当前行的缩进，但会增加下一行的缩进
        }
        
        // 添加缩进
        final indent = '    ' * indentLevel; // Python使用4个空格作为标准缩进
        formattedLines.add('$indent$trimmedLine');
        
        // 更新下一行的缩进级别
        if (trimmedLine.endsWith(':')) {
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

/// Python格式化服务提供者
final pythonFormatterServiceProvider = Provider<PythonFormatterService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final settings = ref.watch(settingsServiceProvider);
  return PythonFormatterService(logger, settings);
}); 