import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';

/// 补全项类型
enum CompletionItemKind {
  keyword,
  table,
  column,
  function,
  operator,
  snippet,
}

/// 补全项
class CompletionItem {
  final String label;
  final String insertText;
  final CompletionItemKind kind;
  final String? detail;
  final String? documentation;
  final List<String>? parameters;

  const CompletionItem({
    required this.label,
    String? insertText,
    required this.kind,
    this.detail,
    this.documentation,
    this.parameters,
  }) : insertText = insertText ?? label;
}

/// SQL补全服务
class SqlCompletionService {
  final DatabaseService _databaseService;
  Map<String, List<String>> _tableColumns = {};
  final _keywords = const [
    // DML
    'SELECT', 'INSERT', 'UPDATE', 'DELETE',
    'FROM', 'WHERE', 'GROUP BY', 'HAVING',
    'ORDER BY', 'LIMIT', 'OFFSET',
    'VALUES', 'SET',
    
    // JOIN
    'JOIN', 'INNER JOIN', 'LEFT JOIN',
    'RIGHT JOIN', 'FULL JOIN', 'CROSS JOIN',
    'ON', 'USING',
    
    // DDL
    'CREATE', 'ALTER', 'DROP', 'TRUNCATE',
    'TABLE', 'VIEW', 'INDEX', 'SEQUENCE',
    'DATABASE', 'SCHEMA',
    
    // 条件
    'AND', 'OR', 'NOT', 'IN', 'EXISTS',
    'BETWEEN', 'LIKE', 'IS NULL', 'IS NOT NULL',
    
    // 函数
    'COUNT', 'SUM', 'AVG', 'MIN', 'MAX',
    'UPPER', 'LOWER', 'TRIM', 'SUBSTRING',
    'DATE', 'NOW', 'COALESCE', 'NULLIF',
    
    // 其他
    'AS', 'DISTINCT', 'ALL', 'ANY', 'SOME',
    'UNION', 'INTERSECT', 'EXCEPT',
    'ASC', 'DESC', 'CASE', 'WHEN', 'THEN', 'ELSE', 'END',
  ];

  final _operators = const [
    '=', '<>', '>', '<', '>=', '<=',
    '+', '-', '*', '/',
    '||', '&&', '!',
  ];

  final _snippets = const [
    CompletionItem(
      label: 'SELECT',
      insertText: 'SELECT \$1\nFROM \$2\nWHERE \$3',
      kind: CompletionItemKind.snippet,
      detail: '基本查询',
      documentation: '创建基本的SELECT查询',
    ),
    CompletionItem(
      label: 'INSERT',
      insertText: 'INSERT INTO \$1 (\$2)\nVALUES (\$3)',
      kind: CompletionItemKind.snippet,
      detail: '插入数据',
      documentation: '创建INSERT语句',
    ),
    CompletionItem(
      label: 'UPDATE',
      insertText: 'UPDATE \$1\nSET \$2\nWHERE \$3',
      kind: CompletionItemKind.snippet,
      detail: '更新数据',
      documentation: '创建UPDATE语句',
    ),
    CompletionItem(
      label: 'DELETE',
      insertText: 'DELETE FROM \$1\nWHERE \$2',
      kind: CompletionItemKind.snippet,
      detail: '删除数据',
      documentation: '创建DELETE语句',
    ),
    CompletionItem(
      label: 'CREATE TABLE',
      insertText: '''CREATE TABLE \$1 (
  \$2 \$3,
  \$4
)''',
      kind: CompletionItemKind.snippet,
      detail: '创建表',
      documentation: '创建CREATE TABLE语句',
    ),
    CompletionItem(
      label: 'JOIN',
      insertText: '''SELECT \$1
FROM \$2
JOIN \$3 ON \$4''',
      kind: CompletionItemKind.snippet,
      detail: '表连接',
      documentation: '创建JOIN查询',
    ),
    CompletionItem(
      label: 'GROUP BY',
      insertText: '''SELECT \$1, \$2(\$3)
FROM \$4
GROUP BY \$1
HAVING \$5''',
      kind: CompletionItemKind.snippet,
      detail: '分组查询',
      documentation: '创建GROUP BY查询',
    ),
  ];

  SqlCompletionService(this._databaseService);

  /// 获取补全建议
  Future<List<CompletionItem>> getCompletions({
    required String connectionName,
    required String text,
    required int offset,
  }) async {
    final prefix = _getPrefix(text, offset);
    final suggestions = <CompletionItem>[];

    // 获取表和列信息
    await _updateSchema(connectionName);

    // 添加关键字建议
    suggestions.addAll(_getKeywordCompletions(prefix));

    // 添加表名建议
    suggestions.addAll(_getTableCompletions(prefix));

    // 添加列名建议
    suggestions.addAll(_getColumnCompletions(prefix, text));

    // 添加函数建议
    suggestions.addAll(_getFunctionCompletions(prefix));

    // 添加运算符建议
    suggestions.addAll(_getOperatorCompletions(prefix));

    // 添加代码片段建议
    suggestions.addAll(_getSnippetCompletions(prefix));

    return suggestions;
  }

  /// 获取前缀
  String _getPrefix(String text, int offset) {
    if (offset <= 0) return '';
    
    var start = offset - 1;
    while (start >= 0) {
      final char = text[start];
      if (!_isIdentifierChar(char)) break;
      start--;
    }
    
    return text.substring(start + 1, offset);
  }

  /// 更新数据库模式信息
  Future<void> _updateSchema(String connectionName) async {
    try {
      final schema = await _databaseService.getSchema(connectionName);
      _tableColumns = {};
      
      for (final table in schema.entries) {
        final columns = (table.value as List)
            .map((col) => col['name'] as String)
            .toList();
        _tableColumns[table.key] = columns;
      }
    } catch (e) {
      debugPrint('Failed to update schema: $e');
    }
  }

  /// 获取关键字建议
  List<CompletionItem> _getKeywordCompletions(String prefix) {
    final upperPrefix = prefix.toUpperCase();
    return _keywords
        .where((keyword) => keyword.startsWith(upperPrefix))
        .map((keyword) => CompletionItem(
              label: keyword,
              kind: CompletionItemKind.keyword,
            ))
        .toList();
  }

  /// 获取表名建议
  List<CompletionItem> _getTableCompletions(String prefix) {
    final lowerPrefix = prefix.toLowerCase();
    return _tableColumns.keys
        .where((table) => table.toLowerCase().startsWith(lowerPrefix))
        .map((table) => CompletionItem(
              label: table,
              kind: CompletionItemKind.table,
              detail: '表',
              documentation: '包含 ${_tableColumns[table]?.length ?? 0} 列',
            ))
        .toList();
  }

  /// 获取列名建议
  List<CompletionItem> _getColumnCompletions(String prefix, String text) {
    final suggestions = <CompletionItem>[];
    final lowerPrefix = prefix.toLowerCase();
    
    // 从当前上下文确定可能的表
    final tables = _extractTablesFromContext(text);
    
    for (final table in tables) {
      final columns = _tableColumns[table] ?? [];
      suggestions.addAll(
        columns
            .where((col) => col.toLowerCase().startsWith(lowerPrefix))
            .map((col) => CompletionItem(
                  label: col,
                  kind: CompletionItemKind.column,
                  detail: '$table 的列',
                )),
      );
    }
    
    return suggestions;
  }

  /// 获取函数建议
  List<CompletionItem> _getFunctionCompletions(String prefix) {
    final upperPrefix = prefix.toUpperCase();
    return _keywords
        .where((keyword) =>
            keyword.startsWith(upperPrefix) &&
            _isFunctionKeyword(keyword))
        .map((keyword) => CompletionItem(
              label: keyword,
              insertText: '$keyword()',
              kind: CompletionItemKind.function,
              parameters: _getFunctionParameters(keyword),
            ))
        .toList();
  }

  /// 获取运算符建议
  List<CompletionItem> _getOperatorCompletions(String prefix) {
    return _operators
        .where((op) => op.startsWith(prefix))
        .map((op) => CompletionItem(
              label: op,
              kind: CompletionItemKind.operator,
            ))
        .toList();
  }

  /// 获取代码片段建议
  List<CompletionItem> _getSnippetCompletions(String prefix) {
    final upperPrefix = prefix.toUpperCase();
    return _snippets
        .where((snippet) => snippet.label.startsWith(upperPrefix))
        .toList();
  }

  /// 辅助方法

  bool _isIdentifierChar(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }

  bool _isFunctionKeyword(String keyword) {
    return [
      'COUNT', 'SUM', 'AVG', 'MIN', 'MAX',
      'UPPER', 'LOWER', 'TRIM', 'SUBSTRING',
      'DATE', 'NOW', 'COALESCE', 'NULLIF',
    ].contains(keyword);
  }

  List<String>? _getFunctionParameters(String function) {
    switch (function) {
      case 'COUNT':
        return ['expression'];
      case 'SUM':
      case 'AVG':
      case 'MIN':
      case 'MAX':
        return ['column'];
      case 'UPPER':
      case 'LOWER':
      case 'TRIM':
        return ['string'];
      case 'SUBSTRING':
        return ['string', 'start', 'length'];
      case 'COALESCE':
        return ['value1', 'value2', '...'];
      case 'NULLIF':
        return ['value1', 'value2'];
      default:
        return null;
    }
  }

  Set<String> _extractTablesFromContext(String sql) {
    final tables = <String>{};
    
    // 提取FROM子句中的表
    final fromMatches = RegExp(r'FROM\s+([a-zA-Z_][a-zA-Z0-9_]*)')
        .allMatches(sql.toUpperCase());
    for (final match in fromMatches) {
      if (match.groupCount >= 1) {
        final table = match.group(1)!;
        if (_tableColumns.containsKey(table)) {
          tables.add(table);
        }
      }
    }
    
    // 提取JOIN子句中的表
    final joinMatches = RegExp(r'JOIN\s+([a-zA-Z_][a-zA-Z0-9_]*)')
        .allMatches(sql.toUpperCase());
    for (final match in joinMatches) {
      if (match.groupCount >= 1) {
        final table = match.group(1)!;
        if (_tableColumns.containsKey(table)) {
          tables.add(table);
        }
      }
    }
    
    return tables;
  }
}

/// SQL补全服务提供者
final sqlCompletionServiceProvider = Provider<SqlCompletionService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return SqlCompletionService(databaseService);
}); 