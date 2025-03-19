import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// 助手状态
enum AssistantState {
  /// 初始化状态
  initializing,
  
  /// 空闲状态
  idle,
  
  /// 监听状态
  listening,
  
  /// 思考状态
  thinking,
  
  /// 处理状态
  processing,
  
  /// 响应状态
  responding,
  
  /// 学习状态
  learning,
  
  /// 暂停状态
  paused,
  
  /// 休眠状态
  sleeping,
  
  /// 错误状态
  error,
}

/// 助手模式
enum AssistantMode {
  /// 被动模式
  passive,
  
  /// 主动模式
  proactive,
  
  /// 协作模式
  collaborative,
  
  /// 教学模式
  instructive,
  
  /// 创造模式
  creative,
}

/// 资源使用情况
class ResourceUsage {
  /// CPU使用率
  final double cpuUsage;
  
  /// 内存使用量（MB）
  final double memoryUsageMB;
  
  /// API调用次数
  final int apiCallCount;
  
  /// 令牌使用量
  final int tokenUsage;
  
  /// 时间戳
  final DateTime timestamp;
  
  /// 构造函数
  ResourceUsage({
    required this.cpuUsage,
    required this.memoryUsageMB,
    required this.apiCallCount,
    required this.tokenUsage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 从Map创建资源使用情况
  factory ResourceUsage.fromMap(Map<String, dynamic> map) {
    return ResourceUsage(
      cpuUsage: (map['cpuUsage'] ?? 0.0) as double,
      memoryUsageMB: (map['memoryUsageMB'] ?? 0.0) as double,
      apiCallCount: (map['apiCallCount'] ?? 0) as int,
      tokenUsage: (map['tokenUsage'] ?? 0) as int,
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'cpuUsage': cpuUsage,
      'memoryUsageMB': memoryUsageMB,
      'apiCallCount': apiCallCount,
      'tokenUsage': tokenUsage,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 上下文项
class ContextItem {
  /// 项目ID
  final String id;
  
  /// 项目类型
  final String type;
  
  /// 项目内容
  final dynamic content;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 优先级
  final int priority;
  
  /// 过期时间（可选）
  final DateTime? expiresAt;
  
  /// 元数据
  final Map<String, dynamic> metadata;
  
  /// 构造函数
  ContextItem({
    required this.id,
    required this.type,
    required this.content,
    DateTime? createdAt,
    this.priority = 0,
    this.expiresAt,
    this.metadata = const {},
  }) : createdAt = createdAt ?? DateTime.now();
  
  /// 检查是否过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }
  
  /// 从Map创建上下文项
  factory ContextItem.fromMap(Map<String, dynamic> map) {
    return ContextItem(
      id: map['id'],
      type: map['type'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      priority: (map['priority'] ?? 0) as int,
      expiresAt: map['expiresAt'] != null 
          ? DateTime.parse(map['expiresAt']) 
          : null,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// 状态管理器
class StateManager {
  /// 当前状态
  AssistantState _currentState = AssistantState.initializing;
  
  /// 当前模式
  AssistantMode _currentMode = AssistantMode.passive;
  
  /// 状态控制器
  final StreamController<AssistantState> _stateController = 
      StreamController<AssistantState>.broadcast();
  
  /// 模式控制器
  final StreamController<AssistantMode> _modeController = 
      StreamController<AssistantMode>.broadcast();
  
  /// 资源使用控制器
  final StreamController<ResourceUsage> _resourceController = 
      StreamController<ResourceUsage>.broadcast();
  
  /// 上下文变化控制器
  final StreamController<List<ContextItem>> _contextController = 
      StreamController<List<ContextItem>>.broadcast();
  
  /// 上下文项目
  final List<ContextItem> _contextItems = [];
  
  /// 资源使用历史
  final List<ResourceUsage> _resourceHistory = [];
  
  /// 最大资源历史记录数
  final int _maxResourceHistorySize = 100;
  
  /// 最新的资源使用情况
  ResourceUsage? _latestResourceUsage;
  
  /// 状态变化回调
  final Map<AssistantState, List<Function()>> _stateChangeCallbacks = {};
  
  /// 构造函数
  StateManager() {
    // 初始化状态
    _initialize();
  }
  
  /// 初始化
  Future<void> _initialize() async {
    // 创建初始资源使用情况
    _latestResourceUsage = ResourceUsage(
      cpuUsage: 0.0,
      memoryUsageMB: 0.0,
      apiCallCount: 0,
      tokenUsage: 0,
    );
    
    // 转换到空闲状态
    _transitionToState(AssistantState.idle);
  }
  
  /// 获取当前状态
  AssistantState get currentState => _currentState;
  
  /// 获取当前模式
  AssistantMode get currentMode => _currentMode;
  
  /// 状态变化流
  Stream<AssistantState> get stateChanges => _stateController.stream;
  
  /// 模式变化流
  Stream<AssistantMode> get modeChanges => _modeController.stream;
  
  /// 资源使用流
  Stream<ResourceUsage> get resourceUpdates => _resourceController.stream;
  
  /// 上下文变化流
  Stream<List<ContextItem>> get contextUpdates => _contextController.stream;
  
  /// 获取最新的资源使用情况
  ResourceUsage? get latestResourceUsage => _latestResourceUsage;
  
  /// 获取资源使用历史
  List<ResourceUsage> getResourceHistory() {
    return List.unmodifiable(_resourceHistory);
  }
  
  /// 获取当前上下文
  List<ContextItem> getContext() {
    // 移除过期项目
    _contextItems.removeWhere((item) => item.isExpired);
    
    return List.unmodifiable(_contextItems);
  }
  
  /// 获取特定类型的上下文项
  List<ContextItem> getContextByType(String type) {
    // 移除过期项目
    _contextItems.removeWhere((item) => item.isExpired);
    
    return _contextItems
        .where((item) => item.type == type)
        .toList();
  }
  
  /// 获取上下文项的数量
  int getContextItemCount() {
    // 移除过期项目
    _contextItems.removeWhere((item) => item.isExpired);
    
    return _contextItems.length;
  }
  
  /// 添加上下文项
  void addContextItem(ContextItem item) {
    // 检查是否已存在相同ID的项目
    final existingIndex = _contextItems.indexWhere((i) => i.id == item.id);
    
    if (existingIndex >= 0) {
      // 替换已存在的项目
      _contextItems[existingIndex] = item;
    } else {
      // 添加新项目
      _contextItems.add(item);
    }
    
    // 按优先级排序
    _contextItems.sort((a, b) => b.priority.compareTo(a.priority));
    
    // 通知观察者
    _contextController.add(getContext());
  }
  
  /// 移除上下文项
  bool removeContextItem(String id) {
    final initialLength = _contextItems.length;
    _contextItems.removeWhere((item) => item.id == id);
    
    final removed = initialLength > _contextItems.length;
    
    if (removed) {
      // 通知观察者
      _contextController.add(getContext());
    }
    
    return removed;
  }
  
  /// 清除所有上下文项
  void clearContext() {
    _contextItems.clear();
    
    // 通知观察者
    _contextController.add(getContext());
  }
  
  /// 清除特定类型的上下文项
  void clearContextByType(String type) {
    final initialLength = _contextItems.length;
    _contextItems.removeWhere((item) => item.type == type);
    
    if (initialLength > _contextItems.length) {
      // 通知观察者
      _contextController.add(getContext());
    }
  }
  
  /// 设置助手模式
  void setMode(AssistantMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      _modeController.add(mode);
    }
  }
  
  /// 更新资源使用情况
  void updateResourceUsage(ResourceUsage usage) {
    _latestResourceUsage = usage;
    
    // 添加到历史记录
    _resourceHistory.add(usage);
    
    // 保持历史记录大小
    if (_resourceHistory.length > _maxResourceHistorySize) {
      _resourceHistory.removeAt(0);
    }
    
    // 通知观察者
    _resourceController.add(usage);
  }
  
  /// 转换到指定状态
  void transitionToState(AssistantState state) {
    _transitionToState(state);
  }
  
  /// 内部状态转换实现
  void _transitionToState(AssistantState state) {
    if (_currentState != state) {
      final oldState = _currentState;
      _currentState = state;
      
      // 执行状态变化回调
      _executeStateChangeCallbacks(state);
      
      // 通知观察者
      _stateController.add(state);
      
      if (kDebugMode) {
        print('助手状态从 $oldState 变为 $state');
      }
    }
  }
  
  /// 注册状态变化回调
  void registerStateChangeCallback(AssistantState state, Function() callback) {
    _stateChangeCallbacks[state] ??= [];
    _stateChangeCallbacks[state]!.add(callback);
  }
  
  /// 执行状态变化回调
  void _executeStateChangeCallbacks(AssistantState state) {
    if (_stateChangeCallbacks.containsKey(state)) {
      for (final callback in _stateChangeCallbacks[state]!) {
        try {
          callback();
        } catch (e) {
          if (kDebugMode) {
            print('执行状态变化回调时出错: $e');
          }
        }
      }
    }
  }
  
  /// 关闭状态管理器
  Future<void> close() async {
    await _stateController.close();
    await _modeController.close();
    await _resourceController.close();
    await _contextController.close();
  }
}

/// 状态管理器提供者
final stateManagerProvider = Provider<StateManager>((ref) {
  final manager = StateManager();
  
  ref.onDispose(() {
    manager.close();
  });
  
  return manager;
});

/// 当前助手状态提供者
final currentStateProvider = StreamProvider<AssistantState>((ref) {
  final manager = ref.watch(stateManagerProvider);
  return manager.stateChanges;
});

/// 当前助手模式提供者
final currentModeProvider = StreamProvider<AssistantMode>((ref) {
  final manager = ref.watch(stateManagerProvider);
  return manager.modeChanges;
});

/// 资源使用情况提供者
final resourceUsageProvider = StreamProvider<ResourceUsage>((ref) {
  final manager = ref.watch(stateManagerProvider);
  return manager.resourceUpdates;
});

/// 当前上下文提供者
final contextProvider = StreamProvider<List<ContextItem>>((ref) {
  final manager = ref.watch(stateManagerProvider);
  return manager.contextUpdates;
}); 