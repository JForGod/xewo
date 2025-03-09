import 'package:flutter/material.dart';

/// 语言支持基类
abstract class LanguageSupportBase {
  /// 语言名称
  String get languageName;
  
  /// 文件扩展名列表
  List<String> get fileExtensions;
  
  /// 语法高亮样式
  Map<String, TextStyle> get syntaxHighlighting;
  
  /// 关键字列表
  List<String> get keywords;
  
  /// 代码片段列表
  List<String> get snippets;
  
  /// 获取自动缩进
  String? getAutoIndent(String line);
  
  /// 解析导入语句
  List<String> parseImports(String code);
  
  /// 检查是否为有效标识符
  bool isValidIdentifier(String text) {
    return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(text);
  }
  
  /// 获取补全建议
  List<String> getCompletionSuggestions(String prefix) {
    final suggestions = <String>[];
    
    // 根据前缀过滤关键字
    final prefixLower = prefix.toLowerCase();
    suggestions.addAll(keywords.where(
      (k) => k.toLowerCase().startsWith(prefixLower)
    ));
    
    return suggestions;
  }
  
  /// 高亮代码
  TextSpan highlight(String text) {
    // 简单实现，实际项目中可能需要更复杂的解析
    final List<TextSpan> children = [];
    
    // 将文本分割为行
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // 处理每一行
      final lineSpans = _highlightLine(line);
      children.addAll(lineSpans);
      
      // 添加换行符，除了最后一行
      if (i < lines.length - 1) {
        children.add(const TextSpan(text: '\n'));
      }
    }
    
    return TextSpan(children: children);
  }
  
  /// 高亮单行代码
  List<TextSpan> _highlightLine(String line) {
    final List<TextSpan> spans = [];
    
    // 简单的词法分析
    final RegExp tokenPattern = RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*)|(\d+(?:\.\d+)?)|("(?:[^"\\]|\\.)*")|(\s+)|([^\w\s])');
    
    int lastMatchEnd = 0;
    for (final match in tokenPattern.allMatches(line)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: line.substring(lastMatchEnd, match.start)));
      }
      
      final String token = line.substring(match.start, match.end);
      TextStyle? style;
      
      if (match.group(1) != null) {
        // 标识符或关键字
        if (keywords.contains(token.toUpperCase()) || keywords.contains(token.toLowerCase())) {
          style = syntaxHighlighting['keyword'];
        } else {
          style = syntaxHighlighting['identifier'];
        }
      } else if (match.group(2) != null) {
        // 数字
        style = syntaxHighlighting['number'];
      } else if (match.group(3) != null) {
        // 字符串
        style = syntaxHighlighting['string'];
      } else if (match.group(4) != null) {
        // 空白
        style = null;
      } else if (match.group(5) != null) {
        // 标点符号
        style = syntaxHighlighting['punctuation'];
      }
      
      spans.add(TextSpan(text: token, style: style));
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastMatchEnd)));
    }
    
    return spans;
  }

  String getFileExtension();
  List<String> getSupportedFileExtensions();
  bool canHandle(String fileExtension);
  Map<String, dynamic> getLanguageConfiguration();
  Map<String, dynamic> getTokenColors();
  bool isSourceFile(String fileName);
  bool isConfigFile(String fileName);
  List<String> getImports(String code);
  List<String> getExports(String code);
  List<String> getClasses(String code);
  List<String> getFunctions(String code);
  List<String> getVariables(String code);
  bool isTestFile(String fileName);
  String getCommentStart();
  String getCommentEnd();
  String getBlockCommentStart();
  String getBlockCommentEnd();
  String getLineCommentStart();
  String getStringDelimiter();
  String getAlternativeStringDelimiter();
  String getTemplateStringDelimiter();
  bool isKeyword(String word);
  bool isOperator(String text);
  bool isTypeScript(String code);
} 