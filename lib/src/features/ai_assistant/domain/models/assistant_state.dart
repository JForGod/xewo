import 'package:flutter/foundation.dart';
import 'assistant_mode.dart';

/// 2025-03-17: 新增 - 上下文感知级别枚举
enum ContextAwarenessLevel {
  /// 低级别 - 仅基本上下文感知，不主动收集信息
  low,
  
  /// 中级别 - 平衡的上下文感知，收集部分信息
  medium,
  
  /// 高级别 - 完整上下文感知，主动收集全面信息
  high,
}

/// 2025-03-17: 新增 - AI助手状态模型
class AssistantState {
  /// 当前助手模式
  final AssistantMode currentMode;
  
  /// 助手是否可见
  final bool isVisible;
  
  /// 上下文感知级别
  final ContextAwarenessLevel contextAwarenessLevel;
  
  /// 全局上下文数据
  final Map<String, dynamic> globalContext;
  
  /// 最近的全局上下文变更记录
  final List<Map<String, dynamic>> recentContextChanges;
  
  /// 状态快照
  final Map<String, Map<String, dynamic>> stateSnapshots;
  
  /// 最后一次错误
  final String? lastError;
  
  /// 最后一次错误时间
  final DateTime? lastErrorTime;
  
  /// 最后一次模式切换时间
  final DateTime? lastModeChangeTime;
  
  /// 最后一次上下文更新时间
  final DateTime? lastContextUpdateTime;
  
  /// 初始化错误
  final String? initializationError;
  
  /// 构造函数
  const AssistantState({
    required this.currentMode,
    required this.isVisible,
    required this.contextAwarenessLevel,
    required this.globalContext,
    required this.recentContextChanges,
    required this.stateSnapshots,
    this.lastError,
    this.lastErrorTime,
    this.lastModeChangeTime,
    this.lastContextUpdateTime,
    this.initializationError,
  });
  
  /// 创建初始状态
  factory AssistantState.initial() {
    return const AssistantState(
      currentMode: AssistantMode.standard,
      isVisible: false,
      contextAwarenessLevel: ContextAwarenessLevel.medium,
      globalContext: {},
      recentContextChanges: [],
      stateSnapshots: {},
    );
  }
  
  /// 创建带错误的状态
  factory AssistantState.error(String error) {
    return AssistantState(
      currentMode: AssistantMode.standard,
      isVisible: false,
      contextAwarenessLevel: ContextAwarenessLevel.low,
      globalContext: {},
      recentContextChanges: [],
      stateSnapshots: {},
      lastError: error,
      lastErrorTime: DateTime.now(),
    );
  }
  
  /// 复制状态并修改部分属性
  AssistantState copyWith({
    AssistantMode? currentMode,
    bool? isVisible,
    ContextAwarenessLevel? contextAwarenessLevel,
    Map<String, dynamic>? globalContext,
    List<Map<String, dynamic>>? recentContextChanges,
    Map<String, Map<String, dynamic>>? stateSnapshots,
    String? lastError,
    DateTime? lastErrorTime,
    DateTime? lastModeChangeTime,
    DateTime? lastContextUpdateTime,
    String? initializationError,
  }) {
    return AssistantState(
      currentMode: currentMode ?? this.currentMode,
      isVisible: isVisible ?? this.isVisible,
      contextAwarenessLevel: contextAwarenessLevel ?? this.contextAwarenessLevel,
      globalContext: globalContext ?? this.globalContext,
      recentContextChanges: recentContextChanges ?? this.recentContextChanges,
      stateSnapshots: stateSnapshots ?? this.stateSnapshots,
      lastError: lastError ?? this.lastError,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
      lastModeChangeTime: lastModeChangeTime ?? this.lastModeChangeTime,
      lastContextUpdateTime: lastContextUpdateTime ?? this.lastContextUpdateTime,
      initializationError: initializationError ?? this.initializationError,
    );
  }
  
  /// 检查是否有错误
  bool get hasError => lastError != null;
  
  /// 检查是否有初始化错误
  bool get hasInitializationError => initializationError != null;
  
  /// 检查是否有任何上下文数据
  bool get hasContextData => globalContext.isNotEmpty;
  
  /// 检查是否有任何状态快照
  bool get hasSnapshots => stateSnapshots.isNotEmpty;
  
  /// 获取最近快照的ID
  String? get latestSnapshotId {
    if (stateSnapshots.isEmpty) return null;
    return stateSnapshots.keys.last;
  }
  
  /// 用于调试的字符串表示
  @override
  String toString() {
    return 'AssistantState('
        'mode: $currentMode, '
        'visible: $isVisible, '
        'context: ${globalContext.length} keys, '
        'error: ${lastError != null ? "Yes" : "No"})';
  }
  
  /// 检查两个状态是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AssistantState &&
        other.currentMode == currentMode &&
        other.isVisible == isVisible &&
        other.contextAwarenessLevel == contextAwarenessLevel &&
        mapEquals(other.globalContext, globalContext) &&
        listEquals(other.recentContextChanges, recentContextChanges) &&
        mapEquals(other.stateSnapshots, stateSnapshots) &&
        other.lastError == lastError &&
        other.lastErrorTime == lastErrorTime &&
        other.lastModeChangeTime == lastModeChangeTime &&
        other.lastContextUpdateTime == lastContextUpdateTime &&
        other.initializationError == initializationError;
  }
  
  /// 生成哈希码
  @override
  int get hashCode {
    return currentMode.hashCode ^
        isVisible.hashCode ^
        contextAwarenessLevel.hashCode ^
        globalContext.hashCode ^
        recentContextChanges.hashCode ^
        stateSnapshots.hashCode ^
        lastError.hashCode ^
        lastErrorTime.hashCode ^
        lastModeChangeTime.hashCode ^
        lastContextUpdateTime.hashCode ^
        initializationError.hashCode;
  }
} 