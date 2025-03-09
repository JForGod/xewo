import 'package:flutter/material.dart';
import '../language_support_base.dart';

/// Python语言支持
class PythonSupport extends LanguageSupportBase {
  @override
  String getLanguageName() => 'Python';
  
  @override
  List<String> getSupportedFileExtensions() => ['.py'];
  
  @override
  Map<String, TextStyle> get syntaxHighlighting => {
    'keyword': const TextStyle(
      color: Color(0xFF0000FF),
      fontWeight: FontWeight.bold,
    ),
    'string': const TextStyle(
      color: Color(0xFF008000),
    ),
    'comment': const TextStyle(
      color: Color(0xFF008000),
      fontStyle: FontStyle.italic,
    ),
    'number': const TextStyle(
      color: Color(0xFF098658),
    ),
    'identifier': const TextStyle(
      color: Color(0xFF267F99),
    ),
    'punctuation': const TextStyle(
      color: Color(0xFF000000),
    ),
    'decorator': const TextStyle(
      color: Color(0xFF646464),
    ),
  };
  
  @override
  List<String> get keywords => [
    'and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue',
    'def', 'del', 'elif', 'else', 'except', 'False', 'finally', 'for',
    'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'None',
    'nonlocal', 'not', 'or', 'pass', 'raise', 'return', 'True', 'try',
    'while', 'with', 'yield',
  ];
  
  @override
  List<String> getSnippets() {
    // 返回常用代码片段
    return [
      'def function_name():\n    pass',
      'class ClassName:\n    def __init__(self):\n        pass',
      'if condition:\n    pass\nelse:\n    pass',
      'for item in items:\n    pass',
      'try:\n    pass\nexcept Exception as e:\n    pass',
      'import module_name',
      'from module_name import function_name',
      'with open("filename", "r") as file:\n    content = file.read()',
    ];
  }
  
  @override
  String getAutoIndent(String code, int lineNumber) {
    // 实现自动缩进逻辑
    if (code.endsWith(':')) {
      return '    ';
    }
    return '';
  }
  
  @override
  List<String> getImports(String code) {
    final imports = <String>[];
    final regex = RegExp(r'(?:from\s+(\w+(?:\.\w+)*)\s+)?import\s+([^#\n]+)');
    
    for (final match in regex.allMatches(code)) {
      final fromModule = match.group(1);
      final importNames = match.group(2);
      
      if (importNames != null) {
        if (fromModule != null) {
          imports.add('$fromModule.$importNames');
        } else {
          imports.add(importNames.trim());
        }
      }
    }
    
    return imports;
  }
  
  @override
  List<String> getExports(String code) {
    // Python没有显式的导出语句
    return [];
  }
  
  @override
  List<String> getClasses(String code) {
    final classes = <String>[];
    final regex = RegExp(r'class\s+(\w+)(?:\([^)]*\))?:');
    
    for (final match in regex.allMatches(code)) {
      final className = match.group(1);
      if (className != null) {
        classes.add(className);
      }
    }
    
    return classes;
  }
  
  @override
  List<String> getFunctions(String code) {
    final functions = <String>[];
    final regex = RegExp(r'def\s+(\w+)\s*\([^)]*\)\s*:');
    
    for (final match in regex.allMatches(code)) {
      final functionName = match.group(1);
      if (functionName != null) {
        functions.add(functionName);
      }
    }
    
    return functions;
  }
  
  @override
  List<String> getVariables(String code) {
    final variables = <String>[];
    final regex = RegExp(r'(\w+)\s*=\s*[^=]');
    
    for (final match in regex.allMatches(code)) {
      final variableName = match.group(1);
      if (variableName != null && 
          !variableName.startsWith('_') && // 忽略私有变量
          !_isKeyword(variableName)) {     // 忽略关键字
        variables.add(variableName);
      }
    }
    
    return variables;
  }
  
  bool _isKeyword(String word) {
    const keywords = {
      'False', 'None', 'True', 'and', 'as', 'assert', 'async', 'await',
      'break', 'class', 'continue', 'def', 'del', 'elif', 'else', 'except',
      'finally', 'for', 'from', 'global', 'if', 'import', 'in', 'is',
      'lambda', 'nonlocal', 'not', 'or', 'pass', 'raise', 'return',
      'try', 'while', 'with', 'yield'
    };
    return keywords.contains(word);
  }
  
  @override
  String highlightCode(String code) {
    // 简单实现，实际应用中应该使用更复杂的语法高亮逻辑
    return code;
  }
  
  @override
  List<String> getCompletionSuggestions(String code, int offset) {
    // 简单实现，返回关键字作为建议
    return keywords;
  }
} 