import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/window_context.dart';

/// 窗口管理服务
/// 负责管理所有窗口的上下文信息，实现AI助手的全局感知能力
class WindowManagerService {
  /// 单例实例
  static final WindowManagerService _instance = WindowManagerService._internal();

  /// 工厂构造函数
  factory WindowManagerService() {
    return _instance;
  }

  /// 内部构造函数
  WindowManagerService._internal();

  /// 窗口上下文映射表
  final Map<String, WindowContext> _windowContexts = {};

  /// 当前活动窗口ID
  String? _activeWindowId;

  /// 窗口上下文变更流控制器
  final StreamController<WindowContext> _windowContextStreamController = 
      StreamController<WindowContext>.broadcast();

  /// 窗口操作日志流控制器
  final StreamController<Map<String, dynamic>> _windowActionLogStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();

  /// 获取窗口上下文变更流
  Stream<WindowContext> get windowContextStream => 
      _windowContextStreamController.stream;

  /// 获取窗口操作日志流
  Stream<Map<String, dynamic>> get windowActionLogStream => 
      _windowActionLogStreamController.stream;

  /// 获取当前活动窗口ID
  String? get activeWindowId => _activeWindowId;

  /// 获取当前活动窗口上下文
  WindowContext? get activeWindowContext => 
      _activeWindowId != null ? _windowContexts[_activeWindowId] : null;

  /// 获取所有窗口上下文
  List<WindowContext> get allWindowContexts => _windowContexts.values.toList();

  /// 获取指定窗口上下文
  WindowContext? getWindowContext(String windowId) => _windowContexts[windowId];

  /// 创建新窗口上下文
  WindowContext createWindowContext({
    String? windowId,
    required String title,
    required String type,
    Map<String, dynamic>? state,
    List<String>? relatedWindowIds,
  }) {
    final id = windowId ?? const Uuid().v4();
    final context = WindowContext(
      windowId: id,
      title: title,
      type: type,
      state: state ?? {},
      relatedWindowIds: relatedWindowIds ?? [],
      createdAt: DateTime.now(),
    );
    
    _windowContexts[id] = context;
    _windowContextStreamController.add(context);
    
    _logWindowAction(
      WindowContextAction.windowCreate,
      {
        'windowId': id,
        'title': title,
        'type': type,
      },
    );
    
    return context;
  }

  /// 更新窗口上下文
  WindowContext updateWindowContext(
    String windowId, 
    Map<String, dynamic> newState,
  ) {
    final context = _windowContexts[windowId];
    if (context == null) {
      throw Exception('Window context not found: $windowId');
    }
    
    final updatedContext = context.updateState(newState);
    _windowContexts[windowId] = updatedContext;
    _windowContextStreamController.add(updatedContext);
    
    return updatedContext;
  }

  /// 设置活动窗口
  void setActiveWindow(String windowId) {
    if (!_windowContexts.containsKey(windowId)) {
      throw Exception('Window context not found: $windowId');
    }
    
    final previousActiveId = _activeWindowId;
    _activeWindowId = windowId;
    
    final context = _windowContexts[windowId]!;
    final updatedContext = context.copyWith(
      lastActiveAt: DateTime.now(),
    );
    
    _windowContexts[windowId] = updatedContext;
    _windowContextStreamController.add(updatedContext);
    
    _logWindowAction(
      WindowContextAction.windowSwitch,
      {
        'windowId': windowId,
        'previousWindowId': previousActiveId,
      },
    );
  }

  /// 关闭窗口
  void closeWindow(String windowId) {
    if (!_windowContexts.containsKey(windowId)) {
      return;
    }
    
    final context = _windowContexts[windowId]!;
    _windowContexts.remove(windowId);
    
    // 如果关闭的是当前活动窗口，则需要重新设置活动窗口
    if (_activeWindowId == windowId) {
      _activeWindowId = _windowContexts.isNotEmpty 
          ? _windowContexts.keys.first 
          : null;
    }
    
    // 从其他窗口的关联列表中移除此窗口
    for (final otherContext in _windowContexts.values) {
      if (otherContext.relatedWindowIds.contains(windowId)) {
        final updatedContext = otherContext.removeRelatedWindow(windowId);
        _windowContexts[otherContext.windowId] = updatedContext;
        _windowContextStreamController.add(updatedContext);
      }
    }
    
    _logWindowAction(
      WindowContextAction.windowClose,
      {
        'windowId': windowId,
        'title': context.title,
        'type': context.type,
      },
    );
  }

  /// 添加窗口关联
  void addWindowRelation(String sourceWindowId, String targetWindowId) {
    // 检查源窗口是否存在
    if (!_windowContexts.containsKey(sourceWindowId)) {
      if (kDebugMode) {
        print('源窗口上下文不存在: $sourceWindowId');
      }
      throw Exception('源窗口上下文不存在: $sourceWindowId');
    }
    
    // 检查目标窗口是否存在
    if (!_windowContexts.containsKey(targetWindowId)) {
      if (kDebugMode) {
        print('目标窗口上下文不存在: $targetWindowId');
      }
      throw Exception('目标窗口上下文不存在: $targetWindowId');
    }
    
    // 检查是否已经存在关联
    final sourceContext = _windowContexts[sourceWindowId]!;
    if (sourceContext.relatedWindowIds.contains(targetWindowId)) {
      if (kDebugMode) {
        print('窗口关联已存在: $sourceWindowId -> $targetWindowId');
      }
      return;
    }
    
    try {
      // 更新源窗口上下文
      final updatedSourceContext = sourceContext.addRelatedWindow(targetWindowId);
      _windowContexts[sourceWindowId] = updatedSourceContext;
      _windowContextStreamController.add(updatedSourceContext);
      
      // 更新目标窗口上下文
      final targetContext = _windowContexts[targetWindowId]!;
      final updatedTargetContext = targetContext.addRelatedWindow(sourceWindowId);
      _windowContexts[targetWindowId] = updatedTargetContext;
      _windowContextStreamController.add(updatedTargetContext);
      
      // 记录窗口关联操作
      _logWindowAction(
        WindowContextAction.windowCreate,
        {
          'sourceWindowId': sourceWindowId,
          'targetWindowId': targetWindowId,
          'sourceTitle': updatedSourceContext.title,
          'targetTitle': updatedTargetContext.title,
        },
      );
      
      if (kDebugMode) {
        print('窗口关联已建立: ${updatedSourceContext.title} <-> ${updatedTargetContext.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('建立窗口关联时出错: $e');
      }
      throw Exception('建立窗口关联时出错: $e');
    }
  }

  /// 移除窗口关联
  void removeWindowRelation(String sourceWindowId, String targetWindowId) {
    if (!_windowContexts.containsKey(sourceWindowId) || 
        !_windowContexts.containsKey(targetWindowId)) {
      return;
    }
    
    final sourceContext = _windowContexts[sourceWindowId]!;
    final updatedSourceContext = sourceContext.removeRelatedWindow(targetWindowId);
    _windowContexts[sourceWindowId] = updatedSourceContext;
    _windowContextStreamController.add(updatedSourceContext);
    
    final targetContext = _windowContexts[targetWindowId]!;
    final updatedTargetContext = targetContext.removeRelatedWindow(sourceWindowId);
    _windowContexts[targetWindowId] = updatedTargetContext;
    _windowContextStreamController.add(updatedTargetContext);
  }

  /// 记录窗口操作
  void logWindowAction(
    WindowContextAction action,
    Map<String, dynamic> data,
  ) {
    _logWindowAction(action, data);
  }

  /// 内部记录窗口操作方法
  void _logWindowAction(
    WindowContextAction action,
    Map<String, dynamic> data,
  ) {
    final logEntry = {
      'action': action.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'windowId': _activeWindowId,
      'data': data,
    };
    
    _windowActionLogStreamController.add(logEntry);
    
    if (kDebugMode) {
      print('Window Action: ${jsonEncode(logEntry)}');
    }
  }

  /// 获取相关窗口上下文
  List<WindowContext> getRelatedWindowContexts(String windowId) {
    final context = _windowContexts[windowId];
    if (context == null) {
      return [];
    }
    
    return context.relatedWindowIds
        .map((id) => _windowContexts[id])
        .whereType<WindowContext>()
        .toList();
  }

  /// 获取窗口操作历史
  List<Map<String, dynamic>> getWindowActionHistory(String windowId) {
    // 实际实现中，这里应该从持久化存储中获取历史记录
    // 此处为简化实现，返回空列表
    return [];
  }

  /// 导出窗口上下文数据
  Map<String, dynamic> exportWindowContexts() {
    return {
      'activeWindowId': _activeWindowId,
      'contexts': _windowContexts.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  /// 导入窗口上下文数据
  void importWindowContexts(Map<String, dynamic> data) {
    _windowContexts.clear();
    
    final contexts = data['contexts'] as Map<String, dynamic>;
    contexts.forEach((key, value) {
      _windowContexts[key] = WindowContext.fromJson(value);
    });
    
    _activeWindowId = data['activeWindowId'] as String?;
  }

  /// 释放资源
  void dispose() {
    _windowContextStreamController.close();
    _windowActionLogStreamController.close();
  }
} 