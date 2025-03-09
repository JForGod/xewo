import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/logger_service.dart';
import '../../state/providers/shared_preferences_provider.dart';

/// 查询记录
class QueryRecord {
  final String id;
  final String connectionName;
  final String sql;
  final DateTime timestamp;
  final Duration executionTime;
  final bool isStarred;
  final Map<String, dynamic>? metadata;

  const QueryRecord({
    required this.id,
    required this.connectionName,
    required this.sql,
    required this.timestamp,
    required this.executionTime,
    this.isStarred = false,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'connectionName': connectionName,
    'sql': sql,
    'timestamp': timestamp.toIso8601String(),
    'executionTime': executionTime.inMicroseconds,
    'isStarred': isStarred,
    'metadata': metadata,
  };

  factory QueryRecord.fromJson(Map<String, dynamic> json) {
    return QueryRecord(
      id: json['id'] as String,
      connectionName: json['connectionName'] as String,
      sql: json['sql'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      executionTime: Duration(microseconds: json['executionTime'] as int),
      isStarred: json['isStarred'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  QueryRecord copyWith({
    String? id,
    String? connectionName,
    String? sql,
    DateTime? timestamp,
    Duration? executionTime,
    bool? isStarred,
    Map<String, dynamic>? metadata,
  }) {
    return QueryRecord(
      id: id ?? this.id,
      connectionName: connectionName ?? this.connectionName,
      sql: sql ?? this.sql,
      timestamp: timestamp ?? this.timestamp,
      executionTime: executionTime ?? this.executionTime,
      isStarred: isStarred ?? this.isStarred,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 查询历史服务
class QueryHistoryService {
  static const _historyKey = 'query_history';
  static const _maxHistorySize = 1000;
  
  final SharedPreferences _prefs;
  final List<QueryRecord> _history = [];
  
  QueryHistoryService(this._prefs) {
    _loadHistory();
  }
  
  /// 加载历史记录
  void _loadHistory() {
    final jsonList = _prefs.getStringList(_historyKey) ?? [];
    _history.clear();
    _history.addAll(
      jsonList
        .map((json) => QueryRecord.fromJson(jsonDecode(json)))
        .toList()
    );
  }
  
  /// 保存历史记录
  Future<void> _saveHistory() async {
    final jsonList = _history
      .map((record) => jsonEncode(record.toJson()))
      .toList();
    await _prefs.setStringList(_historyKey, jsonList);
  }
  
  /// 添加查询记录
  Future<void> addRecord(QueryRecord record) async {
    // 移除最旧的记录（如果超出最大限制）
    if (_history.length >= _maxHistorySize) {
      _history.removeWhere((r) => !r.isStarred);
      if (_history.length >= _maxHistorySize) {
        _history.removeLast();
      }
    }
    
    _history.insert(0, record);
    await _saveHistory();
  }
  
  /// 标记/取消标记收藏
  Future<void> toggleStar(String recordId) async {
    final index = _history.indexWhere((r) => r.id == recordId);
    if (index != -1) {
      _history[index] = _history[index].copyWith(
        isStarred: !_history[index].isStarred,
      );
      await _saveHistory();
    }
  }
  
  /// 删除记录
  Future<void> deleteRecord(String recordId) async {
    _history.removeWhere((r) => r.id == recordId);
    await _saveHistory();
  }
  
  /// 清除历史记录
  Future<void> clearHistory({bool keepStarred = true}) async {
    if (keepStarred) {
      _history.removeWhere((r) => !r.isStarred);
    } else {
      _history.clear();
    }
    await _saveHistory();
  }
  
  /// 获取所有记录
  List<QueryRecord> getAllRecords() => List.unmodifiable(_history);
  
  /// 获取收藏的记录
  List<QueryRecord> getStarredRecords() => 
    _history.where((r) => r.isStarred).toList();
  
  /// 搜索记录
  List<QueryRecord> searchRecords(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return _history.where((r) =>
      r.sql.toLowerCase().contains(lowerKeyword) ||
      r.connectionName.toLowerCase().contains(lowerKeyword)
    ).toList();
  }
  
  /// 获取特定连接的记录
  List<QueryRecord> getConnectionRecords(String connectionName) =>
    _history.where((r) => r.connectionName == connectionName).toList();
  
  /// 获取最近的记录
  List<QueryRecord> getRecentRecords({int limit = 10}) =>
    _history.take(limit).toList();
}

/// 查询历史服务提供者
final queryHistoryServiceProvider = Provider<QueryHistoryService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return QueryHistoryService(prefs);
});

// 添加Provider定义
final loggerServiceProvider = Provider<LoggerService>((ref) => LoggerService()); 