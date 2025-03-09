import 'package:flutter/material.dart';
import '../language_support_base.dart';

/// SQL语言支持
class SqlSupport extends LanguageSupportBase {
  @override
  String getLanguageName() => 'SQL';
  
  @override
  List<String> getSupportedFileExtensions() => ['.sql'];
  
  @override
  Map<String, TextStyle> get syntaxHighlighting => {
    'keyword': const TextStyle(
      color: Color(0xFF0000FF),
      fontWeight: FontWeight.bold,
    ),
    'function': const TextStyle(
      color: Color(0xFF795E26),
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
    'operator': const TextStyle(
      color: Color(0xFF000000),
      fontWeight: FontWeight.bold,
    ),
  };
  
  @override
  List<String> get keywords => [
    'SELECT', 'FROM', 'WHERE', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'ALTER', 'DROP',
    'TABLE', 'VIEW', 'INDEX', 'TRIGGER', 'PROCEDURE', 'FUNCTION', 'DATABASE', 'SCHEMA',
    'JOIN', 'INNER', 'LEFT', 'RIGHT', 'OUTER', 'FULL', 'ON', 'GROUP', 'ORDER', 'BY',
    'HAVING', 'LIMIT', 'OFFSET', 'AS', 'DISTINCT', 'AND', 'OR', 'NOT', 'IN', 'BETWEEN',
    'LIKE', 'IS', 'NULL', 'ASC', 'DESC', 'UNION', 'ALL', 'INTO', 'VALUES', 'SET',
    'PRIMARY', 'KEY', 'FOREIGN', 'REFERENCES', 'CONSTRAINT', 'DEFAULT', 'AUTO_INCREMENT',
  ];
  
  @override
  List<String> getSnippets() {
    // 返回常用代码片段
    return [
      'SELECT * FROM table_name',
      'SELECT column1, column2 FROM table_name WHERE condition',
      'INSERT INTO table_name (column1, column2) VALUES (value1, value2)',
      'UPDATE table_name SET column1 = value1 WHERE condition',
      'DELETE FROM table_name WHERE condition',
      'CREATE TABLE table_name (\n  column1 datatype,\n  column2 datatype\n)',
      'ALTER TABLE table_name ADD column_name datatype',
      'DROP TABLE table_name',
      'SELECT column1, column2 FROM table1 JOIN table2 ON table1.column = table2.column',
    ];
  }
  
  @override
  String getAutoIndent(String code, int lineNumber) {
    // 实现自动缩进逻辑
    if (code.contains('(') && !code.contains(')')) {
      return '  ';
    }
    return '';
  }
  
  @override
  List<String> getImports(String code) {
    // SQL没有导入语句
    return [];
  }
  
  @override
  List<String> getExports(String code) {
    // SQL没有导出语句
    return [];
  }
  
  @override
  List<String> getClasses(String code) {
    // SQL没有类定义
    return [];
  }
  
  @override
  List<String> getFunctions(String code) {
    // 查找存储过程和函数定义
    final functions = <String>[];
    final regex = RegExp(r'CREATE\s+(?:PROCEDURE|FUNCTION)\s+(\w+)', caseSensitive: false);
    
    for (final match in regex.allMatches(code)) {
      final name = match.group(1);
      if (name != null) {
        functions.add(name);
      }
    }
    
    return functions;
  }
  
  @override
  List<String> getVariables(String code) {
    // 查找变量声明
    final variables = <String>[];
    final regex = RegExp(r'DECLARE\s+(\w+)', caseSensitive: false);
    
    for (final match in regex.allMatches(code)) {
      final name = match.group(1);
      if (name != null) {
        variables.add(name);
      }
    }
    
    return variables;
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