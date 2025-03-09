import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/core/settings_service.dart';

/// 智能缩进服务
class IndentationService {
  final LoggerService _logger;
  final SettingsService _settings;
  
  /// 构造函数
  IndentationService(this._logger, this._settings);
  
  /// 获取缩进字符串
  String getIndentString() {
    final useSpaces = _settings.getBoolValue('editor.useSpaces', true);
    final tabSize = _settings.getIntValue('editor.tabSize', 2);
    
    return useSpaces ? ' ' * tabSize : '\t';
  }
  
  /// 计算行的缩进级别
  int calculateIndentLevel(String line, String language) {
    // 移除前导空格
    final trimmedLine = line.trimLeft();
    
    // 空行不改变缩进级别
    if (trimmedLine.isEmpty) {
      return 0;
    }
    
    // 根据语言选择缩进策略
    switch (language) {
      case 'dart':
      case 'java':
      case 'javascript':
      case 'typescript':
      case 'c':
      case 'cpp':
      case 'csharp':
        return _calculateCStyleIndentLevel(trimmedLine);
      case 'python':
        return _calculatePythonIndentLevel(trimmedLine);
      case 'html':
      case 'xml':
        return _calculateXmlIndentLevel(trimmedLine);
      default:
        return _calculateGenericIndentLevel(trimmedLine);
    }
  }
  
  /// 计算C风格语言的缩进级别
  int _calculateCStyleIndentLevel(String trimmedLine) {
    // 以大括号结尾的行增加下一行的缩进
    if (trimmedLine.endsWith('{')) {
      return 1;
    }
    
    // 以大括号开头的行减少当前行的缩进
    if (trimmedLine.startsWith('}')) {
      return -1;
    }
    
    // 以冒号结尾的case语句增加缩进
    if (trimmedLine.startsWith('case ') && trimmedLine.endsWith(':')) {
      return 1;
    }
    
    // 特殊关键字后的行增加缩进
    if (trimmedLine.startsWith('if ') || 
        trimmedLine.startsWith('else ') || 
        trimmedLine.startsWith('for ') || 
        trimmedLine.startsWith('while ') || 
        trimmedLine.startsWith('do ')) {
      // 如果这些语句后面没有大括号，也增加缩进
      if (!trimmedLine.contains('{') && !trimmedLine.endsWith(';')) {
        return 1;
      }
    }
    
    return 0;
  }
  
  /// 计算Python的缩进级别
  int _calculatePythonIndentLevel(String trimmedLine) {
    // 以冒号结尾的行增加下一行的缩进
    if (trimmedLine.endsWith(':')) {
      return 1;
    }
    
    // 特殊关键字可能减少缩进
    if (trimmedLine.startsWith('return ') || 
        trimmedLine.startsWith('break') || 
        trimmedLine.startsWith('continue') || 
        trimmedLine.startsWith('raise ') || 
        trimmedLine.startsWith('pass')) {
      return 0;
    }
    
    return 0;
  }
  
  /// 计算XML/HTML的缩进级别
  int _calculateXmlIndentLevel(String trimmedLine) {
    // 开始标签增加缩进
    if (trimmedLine.startsWith('<') && 
        !trimmedLine.startsWith('</') && 
        !trimmedLine.endsWith('/>') && 
        !trimmedLine.endsWith('</')) {
      return 1;
    }
    
    // 结束标签减少缩进
    if (trimmedLine.startsWith('</') || trimmedLine.endsWith('/>')) {
      return -1;
    }
    
    return 0;
  }
  
  /// 计算通用的缩进级别
  int _calculateGenericIndentLevel(String trimmedLine) {
    // 以大括号结尾的行增加下一行的缩进
    if (trimmedLine.endsWith('{')) {
      return 1;
    }
    
    // 以大括号开头的行减少当前行的缩进
    if (trimmedLine.startsWith('}')) {
      return -1;
    }
    
    return 0;
  }
  
  /// 获取行的当前缩进
  String getCurrentIndentation(String line) {
    final match = RegExp(r'^(\s*)').firstMatch(line);
    return match?.group(1) ?? '';
  }
  
  /// 应用智能缩进
  String applySmartIndentation(String text, int cursorPosition, String language) {
    try {
      final lines = text.split('\n');
      int lineIndex = 0;
      int currentPos = 0;
      
      // 找到光标所在行
      while (lineIndex < lines.length && currentPos + lines[lineIndex].length < cursorPosition) {
        currentPos += lines[lineIndex].length + 1; // +1 是换行符
        lineIndex++;
      }
      
      // 如果是最后一行，或者无法确定行，返回原文本
      if (lineIndex >= lines.length) {
        return text;
      }
      
      // 获取当前行和前一行
      final currentLine = lines[lineIndex];
      final previousLine = lineIndex > 0 ? lines[lineIndex - 1] : '';
      
      // 计算当前缩进
      final currentIndent = getCurrentIndentation(currentLine);
      final previousIndent = getCurrentIndentation(previousLine);
      
      // 计算前一行的缩进变化
      final indentChange = calculateIndentLevel(previousLine, language);
      
      // 计算新的缩进
      String newIndent;
      if (indentChange > 0) {
        // 增加缩进
        newIndent = previousIndent + getIndentString();
      } else if (indentChange < 0) {
        // 减少缩进
        final indentSize = getIndentString().length;
        newIndent = previousIndent.length > indentSize ? 
                    previousIndent.substring(0, previousIndent.length - indentSize) : 
                    '';
      } else {
        // 保持与前一行相同的缩进
        newIndent = previousIndent;
      }
      
      // 应用新的缩进
      final newLine = newIndent + currentLine.trimLeft();
      lines[lineIndex] = newLine;
      
      return lines.join('\n');
    } catch (e, stackTrace) {
      _logger.error('应用智能缩进失败', e, stackTrace);
      return text;
    }
  }
  
  /// 处理回车键按下事件
  String handleEnterPressed(String text, int cursorPosition, String language) {
    try {
      // 获取当前行的缩进
      final currentLine = _getCurrentLine(text, cursorPosition);
      final currentIndent = _getIndentation(currentLine);
      
      // 检查是否需要增加缩进
      final needsExtraIndent = _needsExtraIndentation(currentLine, language);
      
      // 插入新行和缩进
      final beforeCursor = text.substring(0, cursorPosition);
      final afterCursor = text.substring(cursorPosition);
      final newIndent = needsExtraIndent ? '$currentIndent  ' : currentIndent;
      
      return '$beforeCursor\n$newIndent$afterCursor';
    } catch (e, stackTrace) {
      _logger.error('处理回车键按下事件失败', e, stackTrace);
      return text.substring(0, cursorPosition) + '\n' + text.substring(cursorPosition);
    }
  }
  
  /// 检查是否在括号对之间
  bool _isBetweenBrackets(String before, String after) {
    // 检查常见的括号对
    return (before.endsWith('(') && after.startsWith(')')) ||
           (before.endsWith('[') && after.startsWith(']')) ||
           (before.endsWith('{') && after.startsWith('}'));
  }
  
  /// 处理Tab键按下事件
  String handleTabPressed(String text, int cursorPosition, bool shiftPressed) {
    try {
      if (shiftPressed) {
        // 减少缩进
        return _decreaseIndentation(text, cursorPosition);
      } else {
        // 增加缩进
        return _increaseIndentation(text, cursorPosition);
      }
    } catch (e, stackTrace) {
      _logger.error('处理Tab键按下事件失败', e, stackTrace);
      return shiftPressed ? text : text.substring(0, cursorPosition) + getIndentString() + text.substring(cursorPosition);
    }
  }
  
  /// 获取当前行
  String _getCurrentLine(String text, int cursorPosition) {
    final lineStart = text.lastIndexOf('\n', cursorPosition - 1) + 1;
    final lineEnd = text.indexOf('\n', cursorPosition);
    final end = lineEnd == -1 ? text.length : lineEnd;
    return text.substring(lineStart, end);
  }
  
  /// 获取缩进
  String _getIndentation(String line) {
    final match = RegExp(r'^(\s*)').firstMatch(line);
    return match?.group(1) ?? '';
  }
  
  /// 检查是否需要额外缩进
  bool _needsExtraIndentation(String line, String language) {
    switch (language.toLowerCase()) {
      case 'dart':
      case 'javascript':
      case 'js':
      case 'java':
      case 'c':
      case 'cpp':
      case 'c++':
      case 'csharp':
      case 'c#':
        // 检查是否以{结尾
        return line.trim().endsWith('{');
      case 'python':
      case 'py':
        // 检查是否以:结尾
        return line.trim().endsWith(':');
      default:
        return false;
    }
  }
  
  /// 增加缩进
  String _increaseIndentation(String text, int cursorPosition) {
    final beforeCursor = text.substring(0, cursorPosition);
    final afterCursor = text.substring(cursorPosition);
    return '$beforeCursor  $afterCursor';
  }
  
  /// 减少缩进
  String _decreaseIndentation(String text, int cursorPosition) {
    final lineStart = text.lastIndexOf('\n', cursorPosition - 1) + 1;
    final beforeLine = text.substring(0, lineStart);
    final line = _getCurrentLine(text, cursorPosition);
    final afterLine = text.substring(lineStart + line.length);
    
    // 如果行以空格开头，则删除最多2个空格
    if (line.startsWith('  ')) {
      return '$beforeLine${line.substring(2)}$afterLine';
    } else if (line.startsWith(' ')) {
      return '$beforeLine${line.substring(1)}$afterLine';
    }
    
    return text;
  }
}

/// 智能缩进服务提供者
final indentationServiceProvider = Provider<IndentationService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final settings = ref.watch(settingsServiceProvider);
  return IndentationService(logger, settings);
}); 