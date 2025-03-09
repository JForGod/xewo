import 'package:flutter/material.dart';

abstract class LanguageSupport {
  /// 获取语言名称
  String get languageName;

  /// 获取默认主题配色
  Map<String, Color> get defaultTheme;

  /// 获取语法模式匹配规则
  Map<String, RegExp> get patterns;

  /// 高亮文本
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

  /// 获取文件扩展名列表
  List<String> get fileExtensions {
    switch (languageName) {
      case 'javascript':
        return ['.js', '.jsx', '.mjs'];
      case 'typescript':
        return ['.ts', '.tsx'];
      case 'python':
        return ['.py', '.pyw'];
      case 'java':
        return ['.java'];
      case 'cpp':
        return ['.cpp', '.cc', '.cxx', '.h', '.hpp'];
      case 'rust':
        return ['.rs'];
      case 'go':
        return ['.go'];
      case 'php':
        return ['.php'];
      case 'html':
        return ['.html', '.htm'];
      case 'css':
        return ['.css'];
      case 'sql':
        return ['.sql'];
      case 'dart':
        return ['.dart'];
      default:
        return [];
    }
  }

  /// 根据文件扩展名判断是否支持该语言
  bool supportsFile(String filename) {
    String ext = filename.substring(filename.lastIndexOf('.'));
    return fileExtensions.contains(ext.toLowerCase());
  }
} 