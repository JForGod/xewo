import 'package:flutter/material.dart';
import '../language_support.dart';

class CssLanguageSupport extends LanguageSupport {
  @override
  String get languageName => 'css';

  @override
  Map<String, Color> get defaultTheme => {
    'selector': const Color(0xFF800000),     // 选择器
    'property': const Color(0xFF0000FF),     // 属性
    'value': const Color(0xFF098658),        // 值
    'string': const Color(0xFF008000),       // 字符串
    'comment': const Color(0xFF808080),      // 注释
    'number': const Color(0xFF098658),       // 数字
    'unit': const Color(0xFF098658),         // 单位
    'color': const Color(0xFF811F3F),        // 颜色值
    'function': const Color(0xFF795E26),     // 函数
    'important': const Color(0xFF0000FF),    // !important
    'media': const Color(0xFF0000FF),        // @media
    'keyframes': const Color(0xFF0000FF),    // @keyframes
  };

  @override
  Map<String, RegExp> get patterns => {
    'selector': RegExp(r'[.#]?[\w-]+(?=\s*\{)|(?<=^|\{|\})\s*[\w-]+|\[[^\]]+\]|:{1,2}[\w-]+'),
    'property': RegExp(r'[\w-]+(?=\s*:)'),
    'value': RegExp(r':\s*[^;]+'),
    'string': RegExp(r'"[^"]*"|\'[^\']*\''),
    'comment': RegExp(r'/\*[\s\S]*?\*/'),
    'number': RegExp(r'\b\d+\.?\d*\b'),
    'unit': RegExp(r'(?<=\d)(px|em|rem|%|vh|vw|pt|pc|in|cm|mm|ex|ch|vmin|vmax|deg|rad|turn|s|ms|Hz|kHz|dpi|dpcm|dppx)\b'),
    'color': RegExp(r'#[a-fA-F0-9]{3,8}\b|rgba?\([^)]+\)|hsla?\([^)]+\)'),
    'function': RegExp(r'[\w-]+\([^)]*\)'),
    'important': RegExp(r'!important\b'),
    'media': RegExp(r'@media\b[^{]*\{'),
    'keyframes': RegExp(r'@keyframes\b[^{]*\{'),
  };

  @override
  TextSpan highlightText(String text, Map<String, Color>? theme) {
    theme ??= defaultTheme;
    List<TextSpan> spans = [];
    int currentPosition = 0;

    while (currentPosition < text.length) {
      Map<String, Match?> matches = {};
      int nextMatchPosition = text.length;
      String? matchType;

      // 查找所有模式的下一个匹配
      patterns.forEach((type, pattern) {
        matches[type] = pattern.matchAsPrefix(text.substring(currentPosition));
        if (matches[type] != null && 
            currentPosition + matches[type]!.start < nextMatchPosition) {
          nextMatchPosition = currentPosition + matches[type]!.start;
          matchType = type;
        }
      });

      if (matchType != null && matches[matchType] != null) {
        // 添加未匹配的文本
        if (currentPosition < nextMatchPosition) {
          spans.add(TextSpan(
            text: text.substring(currentPosition, nextMatchPosition),
            style: TextStyle(color: theme!['text'] ?? Colors.black),
          ));
        }

        // 添加匹配的文本
        Match match = matches[matchType]!;
        spans.add(TextSpan(
          text: match.group(0),
          style: TextStyle(color: theme![matchType] ?? Colors.black),
        ));
        currentPosition += match.end;
      } else {
        // 添加剩余的未匹配文本
        spans.add(TextSpan(
          text: text.substring(currentPosition),
          style: TextStyle(color: theme!['text'] ?? Colors.black),
        ));
        break;
      }
    }

    return TextSpan(children: spans);
  }
} 