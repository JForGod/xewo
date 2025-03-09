import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/editor/language_support_base.dart';
import '../../core/editor/languages/dart_support.dart';
import '../../core/editor/languages/javascript_support.dart';
import '../../core/editor/languages/python_support.dart';
import '../../core/editor/languages/sql_support.dart';

/// 语言支持服务提供者
final languageSupportProvider = Provider<LanguageSupport>((ref) {
  return LanguageSupport();
});

/// 语言支持服务
class LanguageSupport {
  final Map<String, LanguageSupportBase> _languages = {};
  
  LanguageSupport() {
    // 注册语言支持
    _registerLanguage(DartSupport());
    _registerLanguage(JavaScriptSupport());
    _registerLanguage(PythonSupport());
    _registerLanguage(SqlSupport());
  }
  
  /// 注册语言支持
  void _registerLanguage(LanguageSupportBase language) {
    _languages[language.getLanguageName().toLowerCase()] = language;
  }
  
  /// 获取语言支持
  LanguageSupportBase? getLanguageSupport(String languageName) {
    return _languages[languageName.toLowerCase()];
  }
  
  /// 根据文件扩展名获取语言
  String? getLanguageByExtension(String extension) {
    for (var language in _languages.values) {
      if (language.getSupportedFileExtensions().contains(extension.toLowerCase())) {
        return language.getLanguageName();
      }
    }
    return null;
  }
  
  /// 高亮代码
  TextSpan highlightCode(String code, String language) {
    final languageSupport = getLanguageSupport(language);
    if (languageSupport != null) {
      return TextSpan(text: languageSupport.highlightCode(code));
    }
    
    // 如果没有找到语言支持，返回普通文本
    return TextSpan(text: code);
  }
  
  /// 获取代码补全建议
  List<String> getCompletionSuggestions(String code, int offset, String language) {
    final languageSupport = getLanguageSupport(language);
    if (languageSupport != null) {
      return languageSupport.getCompletionSuggestions(code, offset);
    }
    
    return [];
  }
  
  /// 获取代码片段
  List<String> getSnippets(String language) {
    final languageSupport = getLanguageSupport(language);
    if (languageSupport != null) {
      return languageSupport.getSnippets();
    }
    
    return [];
  }
  
  /// 获取自动缩进
  String? getAutoIndent(String code, int lineNumber, String language) {
    final languageSupport = getLanguageSupport(language);
    if (languageSupport != null) {
      return languageSupport.getAutoIndent(code, lineNumber);
    }
    
    return null;
  }

  /// 获取文件扩展名
  String getFileExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1) return '';
    return filePath.substring(lastDot);
  }

  /// 从代码内容获取语言类型
  String getLanguageFromCode(String code) {
    // 根据代码特征判断语言类型
    if (code.contains('import { ') || code.contains('export interface ')) {
      return '.ts';
    } else if (code.contains('import React') || code.contains('className=')) {
      return '.jsx';
    } else if (code.contains('import ') && code.contains('dart:')) {
      return '.dart';
    } else if (code.contains('def ') || code.contains('import ') && code.contains('from ')) {
      return '.py';
    } else if (code.contains('#include') || code.contains('std::')) {
      return '.cpp';
    }
    return '.js';
  }

  /// 获取语言名称
  String getLanguageName(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return 'Dart';
      case '.js':
        return 'JavaScript';
      case '.jsx':
        return 'JavaScript (JSX)';
      case '.ts':
        return 'TypeScript';
      case '.tsx':
        return 'TypeScript (JSX)';
      case '.py':
        return 'Python';
      case '.cpp':
      case '.cc':
      case '.cxx':
        return 'C++';
      case '.h':
      case '.hpp':
      case '.hxx':
        return 'C++ Header';
      case '.sql':
        return 'SQL';
      case '.json':
        return 'JSON';
      case '.html':
      case '.htm':
        return 'HTML';
      case '.css':
        return 'CSS';
      case '.md':
        return 'Markdown';
      default:
        return 'Plain Text';
    }
  }

  /// 获取语言图标
  String getLanguageIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return 'assets/icons/languages/dart.png';
      case '.js':
      case '.jsx':
        return 'assets/icons/languages/javascript.png';
      case '.ts':
      case '.tsx':
        return 'assets/icons/languages/typescript.png';
      case '.py':
        return 'assets/icons/languages/python.png';
      case '.cpp':
      case '.cc':
      case '.cxx':
      case '.h':
      case '.hpp':
      case '.hxx':
        return 'assets/icons/languages/cpp.png';
      case '.sql':
        return 'assets/icons/languages/sql.png';
      case '.json':
        return 'assets/icons/languages/json.png';
      case '.html':
      case '.htm':
        return 'assets/icons/languages/html.png';
      case '.css':
        return 'assets/icons/languages/css.png';
      case '.md':
        return 'assets/icons/languages/markdown.png';
      default:
        return 'assets/icons/languages/text.png';
    }
  }
} 