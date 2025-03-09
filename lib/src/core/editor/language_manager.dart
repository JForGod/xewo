import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'language_support_base.dart';
import 'languages/dart_support.dart';
import 'languages/javascript_support.dart';
import 'languages/python_support.dart';
import 'languages/sql_support.dart';

/// 语言管理器
class LanguageManager {
  final Map<String, LanguageSupportBase> _languages = {};
  
  LanguageManager() {
    _registerLanguages();
  }
  
  /// 注册语言支持
  void _registerLanguages() {
    _registerLanguage(DartSupport());
    _registerLanguage(JavaScriptSupport());
    _registerLanguage(PythonSupport());
    _registerLanguage(SqlSupport());
  }
  
  /// 注册语言
  void _registerLanguage(LanguageSupportBase language) {
    _languages[language.getLanguageName().toLowerCase()] = language;
  }
  
  /// 获取语言支持
  LanguageSupportBase? getLanguageSupport(String language) {
    return _languages[language.toLowerCase()];
  }
  
  /// 获取所有支持的语言
  List<String> getSupportedLanguages() {
    return _languages.keys.toList();
  }
  
  /// 根据文件名获取语言支持
  LanguageSupportBase? getLanguageForFile(String fileName) {
    for (final language in _languages.values) {
      if (language.isSourceFile(fileName)) {
        return language;
      }
    }
    return null;
  }
  
  /// 根据文件扩展名获取语言支持
  LanguageSupportBase? getLanguageForExtension(String extension) {
    for (final language in _languages.values) {
      if (language.getSupportedFileExtensions().contains(extension)) {
        return language;
      }
    }
    return null;
  }
  
  /// 判断是否支持该语言
  bool supportsLanguage(String language) {
    return _languages.containsKey(language.toLowerCase());
  }
  
  /// 判断是否支持该文件类型
  bool supportsFile(String fileName) {
    return getLanguageForFile(fileName) != null;
  }
  
  /// 判断是否支持该文件扩展名
  bool supportsExtension(String extension) {
    return getLanguageForExtension(extension) != null;
  }
}

/// 语言管理器提供者
final languageManagerProvider = Provider<LanguageManager>((ref) {
  return LanguageManager();
}); 