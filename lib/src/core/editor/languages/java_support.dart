import 'package:flutter/material.dart';
import '../language_support.dart';

class JavaLanguageSupport extends LanguageSupport {
  @override
  String get languageName => 'java';

  @override
  Map<String, Color> get defaultTheme => {
    'keyword': const Color(0xFF0000FF),     // 关键字
    'string': const Color(0xFF008000),      // 字符串
    'comment': const Color(0xFF808080),     // 注释
    'number': const Color(0xFF098658),      // 数字
    'function': const Color(0xFF795E26),    // 函数
    'class': const Color(0xFF267F99),       // 类
    'annotation': const Color(0xFF9932CC),  // 注解
    'type': const Color(0xFF0000FF),        // 类型
    'variable': const Color(0xFF001080),    // 变量
    'operator': const Color(0xFF000000),    // 运算符
  };

  @override
  Map<String, RegExp> get patterns => {
    'keyword': RegExp(
      r'\b(abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|extends|final|finally|float|for|if|implements|import|instanceof|int|interface|long|native|new|package|private|protected|public|return|short|static|strictfp|super|switch|synchronized|this|throw|throws|transient|try|void|volatile|while)\b'
    ),
    'string': RegExp(r'("(?:[^"\\]|\\.)*")'),
    'comment': RegExp(r'(//.*|/\*[\s\S]*?\*/)'),
    'number': RegExp(r'\b\d+\.?\d*[lLfF]?\b'),
    'function': RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\s*\('),
    'class': RegExp(r'class\s+([A-Z][a-zA-Z0-9_]*)'),
    'annotation': RegExp(r'@[a-zA-Z_][a-zA-Z0-9_]*'),
    'type': RegExp(r'\b(String|Integer|Boolean|Double|Float|List|Map|Set)\b'),
    'variable': RegExp(r'\b[a-z][a-zA-Z0-9_]*\b'),
    'operator': RegExp(r'[+\-*/%=<>!&|^~?:]'),
  };
} 