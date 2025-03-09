import 'package:flutter/material.dart';
import '../language_support.dart';

class CppLanguageSupport extends LanguageSupport {
  @override
  String get languageName => 'cpp';

  @override
  Map<String, Color> get defaultTheme => {
    'keyword': const Color(0xFF0000FF),     // 关键字
    'string': const Color(0xFF008000),      // 字符串
    'comment': const Color(0xFF808080),     // 注释
    'number': const Color(0xFF098658),      // 数字
    'function': const Color(0xFF795E26),    // 函数
    'class': const Color(0xFF267F99),       // 类
    'preprocessor': const Color(0xFF9932CC), // 预处理指令
    'type': const Color(0xFF0000FF),        // 类型
    'variable': const Color(0xFF001080),    // 变量
    'operator': const Color(0xFF000000),    // 运算符
  };

  @override
  Map<String, RegExp> get patterns => {
    'keyword': RegExp(
      r'\b(alignas|alignof|and|and_eq|asm|auto|bitand|bitor|bool|break|case|catch|char|char16_t|char32_t|class|compl|const|constexpr|const_cast|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|false|float|for|friend|goto|if|inline|int|long|mutable|namespace|new|noexcept|not|not_eq|nullptr|operator|or|or_eq|private|protected|public|register|reinterpret_cast|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|true|try|typedef|typeid|typename|union|unsigned|using|virtual|void|volatile|wchar_t|while|xor|xor_eq)\b'
    ),
    'string': RegExp(r'("(?:[^"\\]|\\.)*")'),
    'comment': RegExp(r'(//.*|/\*[\s\S]*?\*/)'),
    'number': RegExp(r'\b\d+\.?\d*[uUlLfF]?\b'),
    'function': RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\s*\('),
    'class': RegExp(r'class\s+([A-Z][a-zA-Z0-9_]*)'),
    'preprocessor': RegExp(r'#\w+'),
    'type': RegExp(r'\b(string|vector|map|set|queue|stack|pair|array|list|deque)\b'),
    'variable': RegExp(r'\b[a-z][a-zA-Z0-9_]*\b'),
    'operator': RegExp(r'[+\-*/%=<>!&|^~?:]|::|->|\.\*|->*'),
  };
} 