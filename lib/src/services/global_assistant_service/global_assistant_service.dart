import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局助手服务
/// 负责管理AI助手的全局感知能力
class GlobalAssistantService {
  /// 单例实例
  static final GlobalAssistantService _instance = GlobalAssistantService._internal();

  /// 工厂构造函数
  factory GlobalAssistantService() {
    return _instance;
  }

  /// 全局上下文数据
  final Map<String, dynamic> _globalContext = {};

  /// 全局上下文变更流控制器
  final StreamController<Map<String, dynamic>> _globalContextStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();

  /// 获取全局上下文变更流
  Stream<Map<String, dynamic>> get globalContextStream => 
      _globalContextStreamController.stream;

  /// 内部构造函数
  GlobalAssistantService._internal() {
    _initializeService();
  }

  /// 初始化服务
  Future<void> _initializeService() async {
    try {
      await _restoreContextFromStorage();
    } catch (e) {
      if (kDebugMode) {
        print('初始化全局助手服务失败: $e');
      }
    }
  }

  /// 从存储中恢复上下文
  Future<void> _restoreContextFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contextJson = prefs.getString('global_assistant_context');
      if (contextJson != null) {
        _globalContext.addAll(json.decode(contextJson) as Map<String, dynamic>);
        _notifyGlobalContextChange();
      }
    } catch (e) {
      if (kDebugMode) {
        print('从存储恢复上下文失败: $e');
      }
    }
  }

  /// 保存上下文到存储
  Future<void> _persistContextToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('global_assistant_context', json.encode(_globalContext));
    } catch (e) {
      if (kDebugMode) {
        print('保存上下文到存储失败: $e');
      }
    }
  }

  /// 获取活动窗口上下文
  dynamic getActiveWindowContext() {
    final windowContext = _getFromGlobalContext('active_window_context');
    if (windowContext != null) {
      return _WindowContext.fromJson(windowContext);
    }
    return null;
  }

  /// 获取窗口上下文
  dynamic getWindowContext(String windowId) {
    final windows = _getFromGlobalContext('windows') as Map<String, dynamic>?;
    if (windows != null && windows.containsKey(windowId)) {
      return _WindowContext.fromJson(windows[windowId]);
    }
    return null;
  }

  /// 创建窗口上下文
  dynamic createWindowContext({
    required String windowId,
    required String title,
    required String type,
    Map<String, dynamic>? state,
    List<String>? relatedWindowIds,
  }) {
    final context = _WindowContext(
      windowId: windowId,
      title: title,
      type: type,
      state: state ?? {},
      relatedWindowIds: relatedWindowIds ?? [],
      createdAt: DateTime.now(),
    );

    // 更新全局上下文中的窗口信息
    final windows = _getFromGlobalContext('windows') as Map<String, dynamic>? ?? {};
    windows[windowId] = context.toJson();
    _updateGlobalContext({'windows': windows});

    // 设置为活动窗口
    _updateGlobalContext({'active_window_context': context.toJson()});

    return context;
  }

  /// 添加窗口关联
  void addWindowRelation(String sourceWindowId, String targetWindowId) {
    try {
      final windows = _getFromGlobalContext('windows') as Map<String, dynamic>? ?? {};
      
      // 更新源窗口关联
      if (windows.containsKey(sourceWindowId)) {
        final sourceContext = _WindowContext.fromJson(windows[sourceWindowId]);
        if (!sourceContext.relatedWindowIds.contains(targetWindowId)) {
          final relatedWindowIds = List<String>.from(sourceContext.relatedWindowIds)
            ..add(targetWindowId);
            
          final updatedSource = sourceContext.copyWith(
            relatedWindowIds: relatedWindowIds,
          );
          
          windows[sourceWindowId] = updatedSource.toJson();
        }
      }
      
      // 更新目标窗口关联
      if (windows.containsKey(targetWindowId)) {
        final targetContext = _WindowContext.fromJson(windows[targetWindowId]);
        if (!targetContext.relatedWindowIds.contains(sourceWindowId)) {
          final relatedWindowIds = List<String>.from(targetContext.relatedWindowIds)
            ..add(sourceWindowId);
            
          final updatedTarget = targetContext.copyWith(
            relatedWindowIds: relatedWindowIds,
          );
          
          windows[targetWindowId] = updatedTarget.toJson();
        }
      }
      
      _updateGlobalContext({'windows': windows});
    } catch (e) {
      if (kDebugMode) {
        print('添加窗口关联失败: $e');
      }
    }
  }

  /// 记录编辑器操作
  void logEditorAction(dynamic action, Map<String, dynamic> data) {
    try {
      // 记录操作日志
      final logs = _getFromGlobalContext('editor_logs') as List<dynamic>? ?? [];
      final logEntry = {
        'action': action.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      
      logs.add(logEntry);
      
      // 限制日志大小
      final limitedLogs = logs.length > 100 ? logs.sublist(logs.length - 100) : logs;
      
      _updateGlobalContext({'editor_logs': limitedLogs});
      
      // 打印调试信息
      if (kDebugMode) {
        print('编辑器操作: $action, 数据: $data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('记录编辑器操作失败: $e');
      }
    }
  }

  /// 从全局上下文获取值
  dynamic _getFromGlobalContext(String key) {
    return _globalContext[key];
  }

  /// 更新全局上下文
  void _updateGlobalContext(Map<String, dynamic> updates) {
    _globalContext.addAll(updates);
    _notifyGlobalContextChange();
    _persistContextToStorage();
  }

  /// 通知全局上下文变更
  void _notifyGlobalContextChange() {
    _globalContextStreamController.add(Map.from(_globalContext));
  }

  /// 释放资源
  void dispose() {
    _globalContextStreamController.close();
  }
}

/// 窗口上下文操作枚举
class WindowContextAction {
  // 基本操作
  static const String openProject = 'open_project';
  static const String openFile = 'open_file';
  static const String saveFile = 'save_file';
  static const String closeFile = 'close_file';
  
  // 窗口操作
  static const String openNewWindow = 'open_new_window';
  static const String windowCreate = 'window_create';
  static const String windowClose = 'window_close';
  static const String windowSwitch = 'window_switch';
  static const String windowLayoutChange = 'window_layout_change';
  
  // 视图操作
  static const String toggleFileTree = 'toggle_file_tree';
  static const String toggleLineNumbers = 'toggle_line_numbers';
  static const String toggleMinimap = 'toggle_minimap';
  
  // 编辑操作
  static const String formatCode = 'format_code';
  static const String search = 'search';
  static const String replace = 'replace';
  static const String foldAll = 'fold_all';
  static const String expandAll = 'expand_all';
}

/// 内部窗口上下文类
class _WindowContext {
  final String windowId;
  final String title;
  final String type;
  final Map<String, dynamic> state;
  final List<String> relatedWindowIds;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  _WindowContext({
    required this.windowId,
    required this.title,
    required this.type,
    required this.state,
    required this.relatedWindowIds,
    required this.createdAt,
    DateTime? lastActiveAt,
  }) : lastActiveAt = lastActiveAt ?? DateTime.now();

  factory _WindowContext.fromJson(Map<String, dynamic> json) {
    return _WindowContext(
      windowId: json['windowId'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      state: json['state'] as Map<String, dynamic>,
      relatedWindowIds: (json['relatedWindowIds'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: json['lastActiveAt'] != null 
          ? DateTime.parse(json['lastActiveAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'windowId': windowId,
      'title': title,
      'type': type,
      'state': state,
      'relatedWindowIds': relatedWindowIds,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }

  _WindowContext copyWith({
    String? windowId,
    String? title,
    String? type,
    Map<String, dynamic>? state,
    List<String>? relatedWindowIds,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return _WindowContext(
      windowId: windowId ?? this.windowId,
      title: title ?? this.title,
      type: type ?? this.type,
      state: state ?? this.state,
      relatedWindowIds: relatedWindowIds ?? this.relatedWindowIds,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
} 