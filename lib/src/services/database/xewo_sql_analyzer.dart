import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';
import 'query_result.dart';
import 'dart:async';
import '../core/logger_service.dart';

/// SQL分析结果
class SqlAnalysisResult {
  final List<String> issues;
  final String? executionPlan;
  final Map<String, dynamic> statistics;
  final List<String> suggestions;

  SqlAnalysisResult({
    required this.issues,
    this.executionPlan,
    required this.statistics,
    required this.suggestions,
  });

  Map<String, dynamic> toMap() {
    return {
      'issues': issues,
      'execution_plan': executionPlan,
      'statistics': statistics,
      'suggestions': suggestions,
    };
  }
}

/// SQL分析器服务
class XewoSqlAnalyzer {
  final DatabaseService _databaseService;
  final LoggerService _logger = LoggerService();
  
  XewoSqlAnalyzer(this._databaseService);

  /// 分析SQL查询
  Future<SqlAnalysisResult> analyzeQuery(String connectionName, String query) async {
    final issues = <String>[];
    final suggestions = <String>[];
    
    try {
      // 执行查询并获取执行计划
      final stopwatch = Stopwatch()..start();
      final result = await _databaseService.executeQuery(connectionName, query);
      stopwatch.stop();

      // 分析查询性能
      if (result.executionTime.inMilliseconds > 1000) {
        issues.add('查询执行时间过长 (${result.executionTime.inMilliseconds}ms)。考虑优化查询或添加适当的索引。');
      }

      if (result.rows.length > 1000) {
        issues.add('查询返回过多行 (${result.rows.length})。考虑添加LIMIT子句或过滤条件。');
      }

      // 获取执行计划
      String? executionPlan;
      try {
        final planResult = await _databaseService.executeQuery(
          connectionName,
          'EXPLAIN $query',
        );
        executionPlan = planResult.rows.map((row) => row.join(' ')).join('\n');
      } catch (e) {
        // 忽略执行计划获取失败的错误
      }

      // 生成优化建议
      suggestions.addAll(_generateSuggestions(query, result, executionPlan));

      return SqlAnalysisResult(
        issues: issues,
        executionPlan: executionPlan,
        statistics: {
          'execution_time_ms': result.executionTime.inMilliseconds,
          'affected_rows': result.affectedRows,
          'returned_rows': result.rows.length,
        },
        suggestions: suggestions,
      );
    } catch (e) {
      issues.add('查询执行错误: ${e.toString()}');
      return SqlAnalysisResult(
        issues: issues,
        executionPlan: null,
        statistics: {},
        suggestions: [],
      );
    }
  }

  /// 生成优化建议
  List<String> _generateSuggestions(String query, QueryResult result, String? executionPlan) {
    final suggestions = <String>[];
    final lowerQuery = query.toLowerCase();

    // 检查是否使用SELECT *
    if (lowerQuery.contains('select *')) {
      suggestions.add('避免使用SELECT *。明确指定需要的列。');
    }

    // 检查是否缺少WHERE子句
    if (lowerQuery.contains('select') && !lowerQuery.contains('where')) {
      suggestions.add('考虑添加WHERE子句以过滤结果。');
    }

    // 检查是否有JOIN但没有ON条件
    if (lowerQuery.contains('join') && !lowerQuery.contains('on')) {
      suggestions.add('为JOIN添加ON条件以指定连接条件。');
    }

    // 检查执行时间
    final executionTimeMs = result.executionTime.inMilliseconds;
    if (executionTimeMs > 1000) {
      suggestions.add('查询执行时间较长 (${executionTimeMs}ms)。考虑添加索引或优化查询。');
    }

    // 检查返回行数
    final rowCount = result.rows.length;
    if (rowCount > 1000) {
      suggestions.add('查询返回大量行 (${rowCount})。考虑添加LIMIT或过滤条件。');
    }

    // 分析执行计划
    if (executionPlan != null) {
      if (executionPlan.toLowerCase().contains('table scan')) {
        suggestions.add('查询执行全表扫描。考虑添加索引。');
      }
      if (executionPlan.toLowerCase().contains('temporary')) {
        suggestions.add('查询创建临时表。考虑优化连接或子查询。');
      }
    }

    return suggestions;
  }
}

/// SQL分析器服务提供者
final sqlAnalyzerProvider = Provider<XewoSqlAnalyzer>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return XewoSqlAnalyzer(databaseService);
}); 