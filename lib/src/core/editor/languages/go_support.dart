import 'package:flutter/material.dart';
import '../language_support.dart';

class GoLanguageSupport extends LanguageSupport {
  @override
  String get languageName => 'go';

  @override
  Map<String, Color> get defaultTheme => {
    'keyword': const Color(0xFF0000FF),     // 关键字
    'string': const Color(0xFF008000),      // 字符串
    'comment': const Color(0xFF808080),     // 注释
    'number': const Color(0xFF098658),      // 数字
    'function': const Color(0xFF795E26),    // 函数
    'type': const Color(0xFF267F99),        // 类型
    'builtin': const Color(0xFF0000FF),     // 内置函数
    'package': const Color(0xFF001080),     // 包名
    'variable': const Color(0xFF001080),    // 变量
    'operator': const Color(0xFF000000),    // 运算符
  };

  @override
  Map<String, RegExp> get patterns => {
    'keyword': RegExp(
      r'\b(break|case|chan|const|continue|default|defer|else|fallthrough|for|func|go|goto|if|import|interface|map|package|range|return|select|struct|switch|type|var)\b'
    ),
    'string': RegExp(r'(`[\s\S]*?`|"(?:[^"\\]|\\.)*")'),
    'comment': RegExp(r'(//.*|/\*[\s\S]*?\*/)'),
    'number': RegExp(r'\b\d+\.?\d*\b'),
    'function': RegExp(r'\bfunc\s+([a-zA-Z_][a-zA-Z0-9_]*)\b'),
    'type': RegExp(r'\b(bool|byte|complex64|complex128|error|float32|float64|int|int8|int16|int32|int64|rune|string|uint|uint8|uint16|uint32|uint64|uintptr|true|false|iota|nil)\b'),
    'builtin': RegExp(r'\b(append|cap|close|complex|copy|delete|imag|len|make|new|panic|print|println|real|recover)\b'),
    'package': RegExp(r'\bpackage\s+([a-zA-Z_][a-zA-Z0-9_]*)\b'),
    'variable': RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b'),
    'operator': RegExp(r'[+\-*/%=<>!&|^~?:]+|:=|<-'),
  };
} 