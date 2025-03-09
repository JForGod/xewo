import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/markdown.dart';

/// 语法高亮主题
class SyntaxTheme {
  final String name;
  final Map<String, TextStyle> styles;
  
  const SyntaxTheme({
    required this.name,
    required this.styles,
  });
  
  /// 获取指定类型的样式
  TextStyle? getStyle(String type) => styles[type];
  
  /// 获取默认样式
  TextStyle get defaultStyle => styles['root'] ?? const TextStyle();
  
  /// 获取字符串样式
  TextStyle get string => styles['string'] ?? defaultStyle;
  
  /// 获取关键字样式
  TextStyle get keyword => styles['keyword'] ?? defaultStyle;
  
  /// 获取常量样式
  TextStyle get constant => styles['constant'] ?? defaultStyle;
  
  /// 获取注释样式
  TextStyle get comment => styles['comment'] ?? defaultStyle;
  
  /// 获取注解样式
  TextStyle get annotation => styles['annotation'] ?? defaultStyle;
  
  /// 获取数字样式
  TextStyle get number => styles['number'] ?? defaultStyle;
  
  /// 获取运算符样式
  TextStyle get operator => styles['operator'] ?? defaultStyle;
  
  /// 获取标点符号样式
  TextStyle get punctuation => styles['punctuation'] ?? defaultStyle;
}

/// 语法高亮服务
class SyntaxHighlightService {
  final Map<String, Mode> _languages;
  final Map<String, SyntaxTheme> _themes;
  late final SyntaxTheme _defaultTheme;
  
  SyntaxHighlightService({
    Map<String, Mode>? languages,
    Map<String, SyntaxTheme>? themes,
  }) : _languages = languages ?? {
    'dart': dart,
    'javascript': javascript,
    'python': python,
    'typescript': typescript,
    'yaml': yaml,
    'json': json,
    'markdown': markdown,
  }, _themes = themes ?? {
    'vs': const SyntaxTheme(
      name: 'Visual Studio',
      styles: {
        'root': TextStyle(color: Color(0xFF000000)),
        'keyword': TextStyle(color: Color(0xFF0000FF)),
        'built_in': TextStyle(color: Color(0xFF0000FF)),
        'type': TextStyle(color: Color(0xFF267F99)),
        'literal': TextStyle(color: Color(0xFF0000FF)),
        'number': TextStyle(color: Color(0xFF098658)),
        'regexp': TextStyle(color: Color(0xFF811F3F)),
        'string': TextStyle(color: Color(0xFFA31515)),
        'subst': TextStyle(color: Color(0xFF000000)),
        'symbol': TextStyle(color: Color(0xFF000000)),
        'class': TextStyle(color: Color(0xFF267F99)),
        'function': TextStyle(color: Color(0xFF795E26)),
        'title': TextStyle(color: Color(0xFF795E26)),
        'params': TextStyle(color: Color(0xFF000000)),
        'comment': TextStyle(color: Color(0xFF008000)),
        'doctag': TextStyle(color: Color(0xFF808080)),
        'meta': TextStyle(color: Color(0xFF808080)),
        'meta-keyword': TextStyle(color: Color(0xFF0000FF)),
        'meta-string': TextStyle(color: Color(0xFFA31515)),
      },
    ),
    'monokai': const SyntaxTheme(
      name: 'Monokai',
      styles: {
        'root': TextStyle(color: Color(0xFFF8F8F2)),
        'keyword': TextStyle(color: Color(0xFFF92672)),
        'built_in': TextStyle(color: Color(0xFF66D9EF)),
        'type': TextStyle(color: Color(0xFF66D9EF)),
        'literal': TextStyle(color: Color(0xFFAE81FF)),
        'number': TextStyle(color: Color(0xFFAE81FF)),
        'regexp': TextStyle(color: Color(0xFFE6DB74)),
        'string': TextStyle(color: Color(0xFFE6DB74)),
        'subst': TextStyle(color: Color(0xFFF8F8F2)),
        'symbol': TextStyle(color: Color(0xFFAE81FF)),
        'class': TextStyle(color: Color(0xFFA6E22E)),
        'function': TextStyle(color: Color(0xFFA6E22E)),
        'title': TextStyle(color: Color(0xFFA6E22E)),
        'params': TextStyle(color: Color(0xFFF8F8F2)),
        'comment': TextStyle(color: Color(0xFF75715E)),
        'doctag': TextStyle(color: Color(0xFF75715E)),
        'meta': TextStyle(color: Color(0xFF75715E)),
        'meta-keyword': TextStyle(color: Color(0xFFF92672)),
        'meta-string': TextStyle(color: Color(0xFFE6DB74)),
      },
    ),
  } {
    _defaultTheme = _themes['vs']!;
  }
  
  /// 获取支持的语言列表
  List<String> get supportedLanguages => _languages.keys.toList();
  
  /// 获取支持的主题列表
  List<String> get supportedThemes => _themes.keys.toList();
  
  /// 获取指定语言的高亮器
  Mode? getLanguage(String? language) =>
      language == null ? null : _languages[language];
  
  /// 获取指定主题
  SyntaxTheme getTheme(String? theme) =>
      theme == null ? _defaultTheme : _themes[theme] ?? _defaultTheme;
  
  /// 高亮代码
  List<TextSpan> highlight(String code, {String? language, String? theme}) {
    try {
      final lang = getLanguage(language);
      if (lang == null) {
        return [TextSpan(text: code)];
      }
      
      final highlighter = Highlight();
      final result = highlighter.parse(
        code,
        language: language,
        autoDetection: false,
      );
      
      final syntaxTheme = getTheme(theme);
      return _convertNodes(result.nodes!, syntaxTheme);
    } catch (e) {
      print('语法高亮错误: $e');
      return [TextSpan(text: code)];
    }
  }
  
  /// 将高亮节点转换为TextSpan
  List<TextSpan> _convertNodes(
    List<Node> nodes,
    SyntaxTheme theme,
  ) {
    final spans = <TextSpan>[];
    
    for (final node in nodes) {
      if (node.value != null) {
        spans.add(TextSpan(
          text: node.value,
          style: theme.getStyle(node.className ?? 'root') ?? theme.defaultStyle,
        ));
      }
      
      if (node.children != null) {
        spans.addAll(_convertNodes(node.children!, theme));
      }
    }
    
    return spans;
  }
}

/// 语法高亮服务提供者
final syntaxHighlightServiceProvider = Provider<SyntaxHighlightService>((ref) {
  return SyntaxHighlightService();
}); 