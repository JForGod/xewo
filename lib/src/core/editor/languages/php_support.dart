import 'package:flutter/material.dart';
import '../language_support.dart';

class PhpLanguageSupport extends LanguageSupport {
  @override
  String get languageName => 'php';

  @override
  Map<String, Color> get defaultTheme => {
    'keyword': const Color(0xFF0000FF),     // 关键字
    'string': const Color(0xFF008000),      // 字符串
    'comment': const Color(0xFF808080),     // 注释
    'number': const Color(0xFF098658),      // 数字
    'function': const Color(0xFF795E26),    // 函数
    'class': const Color(0xFF267F99),       // 类
    'variable': const Color(0xFF001080),    // 变量
    'operator': const Color(0xFF000000),    // 运算符
    'tag': const Color(0xFF800000),         // PHP标签
    'builtin': const Color(0xFF0000FF),     // 内置函数
  };

  @override
  Map<String, RegExp> get patterns => {
    'keyword': RegExp(
      r'\b(abstract|and|array|as|break|callable|case|catch|class|clone|const|continue|declare|default|die|do|echo|else|elseif|empty|enddeclare|endfor|endforeach|endif|endswitch|endwhile|eval|exit|extends|final|finally|fn|for|foreach|function|global|goto|if|implements|include|include_once|instanceof|insteadof|interface|isset|list|match|namespace|new|or|print|private|protected|public|require|require_once|return|static|switch|throw|trait|try|unset|use|var|while|yield|yield from)\b'
    ),
    'string': RegExp(r'(\'(?:[^\'\\]|\\.)*\'|"(?:[^"\\]|\\.)*")'),
    'comment': RegExp(r'(//.*|#.*|/\*[\s\S]*?\*/)'),
    'number': RegExp(r'\b\d+\.?\d*\b'),
    'function': RegExp(r'\bfunction\s+([a-zA-Z_][a-zA-Z0-9_]*)\b'),
    'class': RegExp(r'\bclass\s+([A-Z][a-zA-Z0-9_]*)\b'),
    'variable': RegExp(r'(\$[a-zA-Z_][a-zA-Z0-9_]*)'),
    'operator': RegExp(r'[+\-*/%=<>!&|^~?:]+|=>|->|\?\?'),
    'tag': RegExp(r'(<\?php\b|\?>)'),
    'builtin': RegExp(
      r'\b(array|isset|unset|empty|eval|die|exit|include|include_once|require|require_once|print|echo|list|isset|unset|empty|count|sizeof|in_array|array_key_exists|is_array|is_string|is_int|is_integer|is_float|is_bool|is_null|is_object|is_resource|is_scalar|is_numeric|is_callable)\b'
    ),
  };
} 