import 'package:flutter/material.dart';
import '../language_support.dart';

class HtmlLanguageSupport extends LanguageSupport {
  @override
  String get languageName => 'html';

  @override
  Map<String, Color> get defaultTheme => {
    'tag': const Color(0xFF800000),         // 标签
    'attribute': const Color(0xFF0000FF),   // 属性
    'string': const Color(0xFF008000),      // 字符串
    'comment': const Color(0xFF808080),     // 注释
    'doctype': const Color(0xFF808080),     // 文档类型
    'entity': const Color(0xFF098658),      // HTML实体
    'script': const Color(0xFF795E26),      // 脚本标签
    'style': const Color(0xFF267F99),       // 样式标签
    'css': const Color(0xFF0000FF),         // CSS样式
    'javascript': const Color(0xFF795E26),  // JavaScript代码
  };

  @override
  Map<String, RegExp> get patterns => {
    'tag': RegExp(r'<[!\/]?(?:[\w:-]+\s*)*>?'),
    'attribute': RegExp(r'\b([\w:-]+)(?:\s*=\s*(?:[^>\s]+|\s*"[^"]*"|\s*\'[^\']*\')?)?'),
    'string': RegExp(r'"[^"]*"|\'[^\']*\''),
    'comment': RegExp(r'<!--[\s\S]*?-->'),
    'doctype': RegExp(r'<!DOCTYPE[^>]*>'),
    'entity': RegExp(r'&[a-zA-Z0-9#]+;'),
    'script': RegExp(r'<script\b[^>]*>[\s\S]*?<\/script>'),
    'style': RegExp(r'<style\b[^>]*>[\s\S]*?<\/style>'),
    'css': RegExp(r'(?<=<style\b[^>]*>)[\s\S]*?(?=<\/style>)'),
    'javascript': RegExp(r'(?<=<script\b[^>]*>)[\s\S]*?(?=<\/script>)'),
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

        // 特殊处理脚本和样式内容
        Match match = matches[matchType]!;
        if (matchType == 'script' || matchType == 'style') {
          String content = match.group(0)!;
          // 这里可以调用JavaScript或CSS语言支持来处理内部内容
          spans.add(TextSpan(
            text: content,
            style: TextStyle(color: theme![matchType] ?? Colors.black),
          ));
        } else {
          spans.add(TextSpan(
            text: match.group(0),
            style: TextStyle(color: theme![matchType] ?? Colors.black),
          ));
        }
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