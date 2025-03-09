import 'package:flutter/material.dart';

abstract class LanguageSupportBase {
  String getLanguageName();
  List<String> getSupportedFileExtensions();
  
  String highlightCode(String code);
  List<String> getCompletionSuggestions(String code, int offset);
  List<String> getSnippets();
  String getAutoIndent(String code, int lineNumber);
  
  List<String> getImports(String code);
  List<String> getExports(String code);
  List<String> getClasses(String code);
  List<String> getFunctions(String code);
  List<String> getVariables(String code);
  
  bool isSourceFile(String fileName) {
    final extensions = getSupportedFileExtensions();
    return extensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }
  
  bool isConfigFile(String fileName) => false;
  
  Map<String, dynamic> getLanguageConfiguration() {
    return {
      'comments': {
        'lineComment': '//',
        'blockComment': ['/*', '*/'],
      },
      'brackets': [
        ['{', '}'],
        ['[', ']'],
        ['(', ')'],
      ],
      'autoClosingPairs': [
        {'open': '{', 'close': '}'},
        {'open': '[', 'close': ']'},
        {'open': '(', 'close': ')'},
        {'open': "'", 'close': "'"},
        {'open': '"', 'close': '"'},
      ],
    };
  }
  
  Map<String, dynamic> getTokenColors() {
    return {
      'keywords': {
        'foreground': '#569CD6',
        'fontStyle': 'bold',
      },
      'strings': {
        'foreground': '#CE9178',
      },
      'numbers': {
        'foreground': '#B5CEA8',
      },
      'comments': {
        'foreground': '#6A9955',
        'fontStyle': 'italic',
      },
      'functions': {
        'foreground': '#DCDCAA',
      },
      'classes': {
        'foreground': '#4EC9B0',
      },
      'variables': {
        'foreground': '#9CDCFE',
      },
    };
  }
} 