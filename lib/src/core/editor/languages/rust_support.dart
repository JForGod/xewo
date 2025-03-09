import 'package:flutter/material.dart';
import '../language_support.dart';

class RustLanguageSupport extends LanguageSupport {
  @override
  String get languageName => 'rust';

  @override
  Map<String, Color> get defaultTheme => {
    'keyword': const Color(0xFF0000FF),     // 关键字
    'string': const Color(0xFF008000),      // 字符串
    'comment': const Color(0xFF808080),     // 注释
    'number': const Color(0xFF098658),      // 数字
    'function': const Color(0xFF795E26),    // 函数
    'struct': const Color(0xFF267F99),      // 结构体
    'attribute': const Color(0xFF9932CC),   // 属性
    'type': const Color(0xFF0000FF),        // 类型
    'lifetime': const Color(0xFFD16969),    // 生命周期
    'macro': const Color(0xFF9932CC),       // 宏
    'variable': const Color(0xFF001080),    // 变量
    'operator': const Color(0xFF000000),    // 运算符
  };

  @override
  Map<String, RegExp> get patterns => {
    'keyword': RegExp(
      r'\b(as|async|await|break|const|continue|crate|dyn|else|enum|extern|false|fn|for|if|impl|in|let|loop|match|mod|move|mut|pub|ref|return|self|Self|static|struct|super|trait|true|type|unsafe|use|where|while|yield)\b'
    ),
    'string': RegExp(r'("(?:[^"\\]|\\.)*"|r#*"[\s\S]*?"#*)'),
    'comment': RegExp(r'(//.*|/\*[\s\S]*?\*/)'),
    'number': RegExp(r'\b\d+\.?\d*[uif]?(8|16|32|64|128|size)?\b'),
    'function': RegExp(r'\bfn\s+([a-zA-Z_][a-zA-Z0-9_]*)\b'),
    'struct': RegExp(r'\b(struct|enum|trait|impl)\s+([A-Z][a-zA-Z0-9_]*)\b'),
    'attribute': RegExp(r'#\[[\s\S]*?\]'),
    'type': RegExp(r'\b[A-Z][a-zA-Z0-9_]*\b'),
    'lifetime': RegExp(r"'[a-zA-Z_][a-zA-Z0-9_]*\b"),
    'macro': RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*!'),
    'variable': RegExp(r'\b[a-z][a-zA-Z0-9_]*\b'),
    'operator': RegExp(r'[+\-*/%=<>!&|^~?:]+|->|=>'),
  };
} 