import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../models/window_context.dart';
import 'window_manager_service.dart';

/// 全局助手服务
/// 负责管理AI助手的全局感知能力，与窗口管理服务集成
class GlobalAssistantService {
  /// 单例实例
  static final GlobalAssistantService _instance = GlobalAssistantService._internal();

  /// 工厂构造函数
  factory GlobalAssistantService() {
    return _instance;
  }

  /// 窗口管理服务
  final WindowManagerService _windowManagerService = WindowManagerService();

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
    // 监听窗口上下文变更
    _windowManagerService.windowContextStream.listen(_handleWindowContextChange);
    
    // 监听窗口操作日志
    _windowManagerService.windowActionLogStream.listen(_handleWindowActionLog);
  }

  /// 处理窗口上下文变更
  void _handleWindowContextChange(WindowContext context) {
    // 更新全局上下文中的窗口信息
    final windowsContext = _globalContext['windows'] as Map<String, dynamic>? ?? {};
    windowsContext[context.windowId] = {
      'title': context.title,
      'type': context.type,
      'state': context.state,
      'lastActiveAt': context.lastActiveAt.toIso8601String(),
    };
    
    _globalContext['windows'] = windowsContext;
    _notifyGlobalContextChange();
  }

  /// 处理窗口操作日志
  void _handleWindowActionLog(Map<String, dynamic> logEntry) {
    // 更新全局上下文中的操作历史
    final actionLogs = _globalContext['actionLogs'] as List<dynamic>? ?? [];
    actionLogs.add(logEntry);
    
    // 限制历史记录数量
    if (actionLogs.length > 100) {
      actionLogs.removeAt(0);
    }
    
    _globalContext['actionLogs'] = actionLogs;
    _notifyGlobalContextChange();
  }

  /// 通知全局上下文变更
  void _notifyGlobalContextChange() {
    _globalContextStreamController.add(Map.from(_globalContext));
    
    if (kDebugMode) {
      print('Global Context Updated: ${jsonEncode(_globalContext)}');
    }
  }

  /// 获取全局上下文
  Map<String, dynamic> getGlobalContext() {
    return Map<String, dynamic>.from(_globalContext);
  }

  /// 更新全局上下文
  void updateGlobalContext(Map<String, dynamic> updates) {
    updates.forEach((key, value) {
      _globalContext[key] = value;
    });
    
    _notifyGlobalContextChange();
  }

  /// 记录用户操作
  void logUserAction(
    String action,
    Map<String, dynamic> data,
  ) {
    final userActions = _globalContext['userActions'] as List<dynamic>? ?? [];
    
    final logEntry = {
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      'windowId': _windowManagerService.activeWindowId,
      'data': data,
    };
    
    userActions.add(logEntry);
    
    // 限制历史记录数量
    if (userActions.length > 100) {
      userActions.removeAt(0);
    }
    
    _globalContext['userActions'] = userActions;
    _notifyGlobalContextChange();
  }

  /// 记录AI助手操作
  void logAssistantAction(
    String action,
    Map<String, dynamic> data,
  ) {
    final assistantActions = _globalContext['assistantActions'] as List<dynamic>? ?? [];
    
    final logEntry = {
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      'windowId': _windowManagerService.activeWindowId,
      'data': data,
    };
    
    assistantActions.add(logEntry);
    
    // 限制历史记录数量
    if (assistantActions.length > 100) {
      assistantActions.removeAt(0);
    }
    
    _globalContext['assistantActions'] = assistantActions;
    _notifyGlobalContextChange();
  }

  /// 记录编辑器操作
  void logEditorAction(
    WindowContextAction action,
    Map<String, dynamic> data,
  ) {
    // 通过窗口管理服务记录窗口操作
    _windowManagerService.logWindowAction(action, data);
    
    // 同时在全局上下文中记录
    final editorActions = _globalContext['editorActions'] as List<dynamic>? ?? [];
    
    final logEntry = {
      'action': action.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'windowId': _windowManagerService.activeWindowId,
      'data': data,
    };
    
    editorActions.add(logEntry);
    
    // 限制历史记录数量
    if (editorActions.length > 100) {
      editorActions.removeAt(0);
    }
    
    _globalContext['editorActions'] = editorActions;
    _notifyGlobalContextChange();
  }

  /// 获取指定窗口上下文
  WindowContext? getWindowContext(String windowId) {
    return _windowManagerService.getWindowContext(windowId);
  }

  /// 获取当前活动窗口上下文
  WindowContext? getActiveWindowContext() {
    return _windowManagerService.activeWindowContext;
  }

  /// 获取所有窗口上下文
  List<WindowContext> getAllWindowContexts() {
    return _windowManagerService.allWindowContexts;
  }

  /// 获取相关窗口上下文
  List<WindowContext> getRelatedWindowContexts(String windowId) {
    return _windowManagerService.getRelatedWindowContexts(windowId);
  }

  /// 创建新窗口上下文
  WindowContext createWindowContext({
    String? windowId,
    required String title,
    required String type,
    Map<String, dynamic>? state,
    List<String>? relatedWindowIds,
  }) {
    return _windowManagerService.createWindowContext(
      windowId: windowId,
      title: title,
      type: type,
      state: state,
      relatedWindowIds: relatedWindowIds,
    );
  }

  /// 更新窗口上下文
  WindowContext updateWindowContext(
    String windowId, 
    Map<String, dynamic> newState,
  ) {
    return _windowManagerService.updateWindowContext(windowId, newState);
  }

  /// 设置活动窗口
  void setActiveWindow(String windowId) {
    _windowManagerService.setActiveWindow(windowId);
  }

  /// 关闭窗口
  void closeWindow(String windowId) {
    _windowManagerService.closeWindow(windowId);
  }

  /// 添加窗口关联
  void addWindowRelation(String sourceWindowId, String targetWindowId) {
    _windowManagerService.addWindowRelation(sourceWindowId, targetWindowId);
  }

  /// 移除窗口关联
  void removeWindowRelation(String sourceWindowId, String targetWindowId) {
    _windowManagerService.removeWindowRelation(sourceWindowId, targetWindowId);
  }

  /// 导出全局上下文数据
  Map<String, dynamic> exportGlobalContext() {
    final exportData = Map<String, dynamic>.from(_globalContext);
    exportData['windowContexts'] = _windowManagerService.exportWindowContexts();
    return exportData;
  }

  /// 导入全局上下文数据
  void importGlobalContext(Map<String, dynamic> data) {
    _globalContext.clear();
    
    data.forEach((key, value) {
      if (key != 'windowContexts') {
        _globalContext[key] = value;
      }
    });
    
    if (data.containsKey('windowContexts')) {
      _windowManagerService.importWindowContexts(data['windowContexts'] as Map<String, dynamic>);
    }
    
    _notifyGlobalContextChange();
  }

  /// 释放资源
  void dispose() {
    _globalContextStreamController.close();
  }
} 