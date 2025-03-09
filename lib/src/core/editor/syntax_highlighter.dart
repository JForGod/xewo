import 'package:flutter/material.dart';

class SyntaxHighlighter {
  static const Map<String, Color> _defaultTheme = {
    'keyword': Color(0xFF0000FF),    // 关键字
    'string': Color(0xFF008000),     // 字符串
    'comment': Color(0xFF808080),    // 注释
    'number': Color(0xFF098658),     // 数字
    'function': Color(0xFF795E26),   // 函数
    'type': Color(0xFF267F99),       // 类型
    'variable': Color(0xFF001080),   // 变量
    'operator': Color(0xFF000000),   // 运算符
  };

  static TextSpan highlightDart(String text) {
    final List<TextSpan> spans = [];
    final RegExp pattern = RegExp(
      r'(class|void|var|final|const|static|if|else|for|while|do|switch|case|break|continue|return|try|catch|throw|new|this|super|extends|implements|import|export|library|part|as|show|hide|\b[A-Z][a-zA-Z0-9_]*\b|\b[a-z][a-zA-Z0-9_]*\b|\/\/[^\n]*|\/\*[\s\S]*?\*\/|\d+|\W+)',
    );

    int lastMatch = 0;
    for (final Match match in pattern.allMatches(text)) {
      final String token = match.group(0)!;
      
      if (match.start > lastMatch) {
        spans.add(TextSpan(text: text.substring(lastMatch, match.start)));
      }

      Color? color;
      if (_isKeyword(token)) {
        color = _defaultTheme['keyword'];
      } else if (_isString(token)) {
        color = _defaultTheme['string'];
      } else if (_isComment(token)) {
        color = _defaultTheme['comment'];
      } else if (_isNumber(token)) {
        color = _defaultTheme['number'];
      } else if (_isType(token)) {
        color = _defaultTheme['type'];
      } else if (_isFunction(token)) {
        color = _defaultTheme['function'];
      } else if (_isVariable(token)) {
        color = _defaultTheme['variable'];
      } else if (_isOperator(token)) {
        color = _defaultTheme['operator'];
      }

      spans.add(TextSpan(
        text: token,
        style: TextStyle(color: color),
      ));

      lastMatch = match.end;
    }

    if (lastMatch < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatch)));
    }

    return TextSpan(
      style: const TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 14,
      ),
      children: spans,
    );
  }

  static bool _isKeyword(String token) {
    const keywords = {
      'class', 'void', 'var', 'final', 'const', 'static',
      'if', 'else', 'for', 'while', 'do', 'switch', 'case',
      'break', 'continue', 'return', 'try', 'catch', 'throw',
      'new', 'this', 'super', 'extends', 'implements',
      'import', 'export', 'library', 'part', 'as', 'show', 'hide',
    };
    return keywords.contains(token);
  }

  static bool _isString(String token) {
    return token.startsWith("'") || token.startsWith('"');
  }

  static bool _isComment(String token) {
    return token.startsWith('//') || token.startsWith('/*');
  }

  static bool _isNumber(String token) {
    return double.tryParse(token) != null;
  }

  static bool _isType(String token) {
    return token.length > 1 && token[0].toUpperCase() == token[0];
  }

  static bool _isFunction(String token) {
    return token.endsWith('()');
  }

  static bool _isVariable(String token) {
    return token.length > 1 && token[0].toLowerCase() == token[0];
  }

  static bool _isOperator(String token) {
    const operators = {'+', '-', '*', '/', '=', '==', '!=', '>', '<', '>=', '<='};
    return operators.contains(token);
  }
} 