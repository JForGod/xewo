import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../domain/models/assistant_mode.dart';
import '../domain/models/assistant_state.dart';
import '../../../intelligence/global_assistant/services/global_assistant_service.dart';

/// 2025-03-17: 新增 - AI助手状态异常类
class AssistantStateException implements Exception {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  AssistantStateException(this.message, [this.error, this.stackTrace]);

  @override
  String toString() => 'AssistantStateException: $message${error != null ? ' - $error' : ''}';
}

/// 2025-03-17: 新增 - AI助手状态更新结果
class AssistantStateResult {
  final bool success;
  final String? message;
  final Exception? error;

  AssistantStateResult({
    required this.success,
    this.message,
    this.error,
  });

  factory AssistantStateResult.success([String? message]) {
    return AssistantStateResult(
      success: true,
      message: message,
    );
  }

  factory AssistantStateResult.failure(String message, [Exception? error]) {
    return AssistantStateResult(
      success: false,
      message: message,
      error: error,
    );
  }
}

/// 2025-03-17: 新增 - AI助手状态提供者类
class AssistantStateNotifier extends StateNotifier<AssistantState> {
  final GlobalAssistantService _assistantService;
  StreamSubscription? _globalContextSubscription;

  AssistantStateNotifier(this._assistantService) : super(AssistantState.initial()) {
    _initializeState();
  }

  /// 初始化助手状态
  Future<void> _initializeState() async {
    try {
      // 从持久化存储加载状态
      await _loadPersistedState();
      
      // 监听全局上下文变更
      _subscribeToGlobalContext();
      
      if (kDebugMode) {
        print('AI助手状态初始化完成');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('AI助手状态初始化失败: $e');
        print('堆栈跟踪: $stackTrace');
      }
      
      // 初始化失败也不影响应用启动，使用默认状态
      state = AssistantState.initial().copyWith(
        initializationError: e.toString(),
      );
    }
  }
  
  /// 加载持久化状态
  Future<void> _loadPersistedState() async {
    try {
      // 此处可以从SharedPreferences或其他持久化存储加载状态
      // 暂时使用默认状态
      state = AssistantState.initial();
    } catch (e, stackTrace) {
      throw AssistantStateException('加载持久化状态失败', e, stackTrace);
    }
  }
  
  /// 订阅全局上下文变更
  void _subscribeToGlobalContext() {
    try {
      _globalContextSubscription = _assistantService.globalContextStream.listen(
        (globalContext) {
          // 更新状态中的全局上下文
          state = state.copyWith(
            globalContext: globalContext,
            lastContextUpdateTime: DateTime.now(),
          );
          
          // 记录最近的上下文变更
          _updateRecentContextChanges(globalContext);
          
          if (kDebugMode) {
            print('AI助手状态已更新: ${globalContext.length} 个键');
          }
        },
        onError: (error, stackTrace) {
          if (kDebugMode) {
            print('全局上下文流错误: $error');
            print('堆栈跟踪: $stackTrace');
          }
          
          // 不影响整体状态，仅记录错误
          state = state.copyWith(
            lastError: error.toString(),
            lastErrorTime: DateTime.now(),
          );
        },
      );
    } catch (e, stackTrace) {
      throw AssistantStateException('订阅全局上下文失败', e, stackTrace);
    }
  }
  
  /// 更新最近的上下文变更
  void _updateRecentContextChanges(Map<String, dynamic> globalContext) {
    final previousContext = state.globalContext;
    final changedKeys = <String>[];
    
    // 检查新增或修改的键
    globalContext.forEach((key, value) {
      if (!previousContext.containsKey(key) || previousContext[key] != value) {
        changedKeys.add(key);
      }
    });
    
    // 检查移除的键
    previousContext.keys.forEach((key) {
      if (!globalContext.containsKey(key)) {
        changedKeys.add(key);
      }
    });
    
    if (changedKeys.isNotEmpty) {
      final recentChanges = [...state.recentContextChanges];
      
      recentChanges.add({
        'time': DateTime.now().toIso8601String(),
        'changedKeys': changedKeys,
      });
      
      // 保留最近的10个变更
      if (recentChanges.length > 10) {
        recentChanges.removeAt(0);
      }
      
      state = state.copyWith(recentContextChanges: recentChanges);
    }
  }

  /// 切换助手模式
  AssistantStateResult setAssistantMode(AssistantMode mode) {
    try {
      state = state.copyWith(
        currentMode: mode,
        lastModeChangeTime: DateTime.now(),
      );
      
      // 记录模式变更到全局上下文
      _assistantService.logAssistantAction(
        'mode_change',
        {
          'previousMode': state.currentMode.toString(),
          'newMode': mode.toString(),
        },
      );
      
      return AssistantStateResult.success('助手模式已切换到 ${mode.toString()}');
    } catch (e, stackTrace) {
      final error = AssistantStateException('切换助手模式失败', e, stackTrace);
      
      if (kDebugMode) {
        print(error);
      }
      
      return AssistantStateResult.failure('切换助手模式失败', error);
    }
  }
  
  /// 切换助手可见性
  AssistantStateResult setAssistantVisibility(bool isVisible) {
    try {
      state = state.copyWith(
        isVisible: isVisible,
      );
      
      return AssistantStateResult.success(isVisible ? '助手已显示' : '助手已隐藏');
    } catch (e, stackTrace) {
      final error = AssistantStateException('切换助手可见性失败', e, stackTrace);
      
      if (kDebugMode) {
        print(error);
      }
      
      return AssistantStateResult.failure('切换助手可见性失败', error);
    }
  }
  
  /// 设置上下文感知级别
  AssistantStateResult setContextAwarenessLevel(ContextAwarenessLevel level) {
    try {
      state = state.copyWith(
        contextAwarenessLevel: level,
      );
      
      return AssistantStateResult.success('上下文感知级别已设置为 ${level.toString()}');
    } catch (e, stackTrace) {
      final error = AssistantStateException('设置上下文感知级别失败', e, stackTrace);
      
      if (kDebugMode) {
        print(error);
      }
      
      return AssistantStateResult.failure('设置上下文感知级别失败', error);
    }
  }
  
  /// 记录助手操作
  AssistantStateResult logAssistantAction(String action, Map<String, dynamic> data) {
    try {
      _assistantService.logAssistantAction(action, data);
      
      return AssistantStateResult.success('助手操作已记录');
    } catch (e, stackTrace) {
      final error = AssistantStateException('记录助手操作失败', e, stackTrace);
      
      if (kDebugMode) {
        print(error);
      }
      
      return AssistantStateResult.failure('记录助手操作失败', error);
    }
  }
  
  /// 自动快照助手状态
  AssistantStateResult createStateSnapshot() {
    try {
      // 创建当前状态的快照
      final snapshotId = DateTime.now().millisecondsSinceEpoch.toString();
      final snapshots = {...state.stateSnapshots};
      
      snapshots[snapshotId] = {
        'mode': state.currentMode.toString(),
        'isVisible': state.isVisible,
        'contextAwarenessLevel': state.contextAwarenessLevel.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // 保留最近的10个快照
      if (snapshots.length > 10) {
        final oldestKey = snapshots.keys.first;
        snapshots.remove(oldestKey);
      }
      
      state = state.copyWith(stateSnapshots: snapshots);
      
      return AssistantStateResult.success('状态快照已创建');
    } catch (e, stackTrace) {
      final error = AssistantStateException('创建状态快照失败', e, stackTrace);
      
      if (kDebugMode) {
        print(error);
      }
      
      return AssistantStateResult.failure('创建状态快照失败', error);
    }
  }
  
  /// 恢复助手状态快照
  AssistantStateResult restoreStateSnapshot(String snapshotId) {
    try {
      final snapshots = state.stateSnapshots;
      
      if (!snapshots.containsKey(snapshotId)) {
        return AssistantStateResult.failure('快照不存在: $snapshotId');
      }
      
      final snapshot = snapshots[snapshotId];
      if (snapshot == null) {
        return AssistantStateResult.failure('快照为空: $snapshotId');
      }
      
      // 从快照恢复状态
      AssistantMode mode;
      try {
        final modeString = snapshot['mode'] as String?;
        if (modeString != null) {
          mode = AssistantMode.values.firstWhere(
            (m) => m.toString() == modeString,
            orElse: () => AssistantMode.standard,
          );
        } else {
          mode = AssistantMode.standard;
        }
      } catch (_) {
        mode = AssistantMode.standard;
      }
      
      ContextAwarenessLevel contextLevel;
      try {
        final levelString = snapshot['contextAwarenessLevel'] as String?;
        if (levelString != null) {
          contextLevel = ContextAwarenessLevel.values.firstWhere(
            (l) => l.toString() == levelString,
            orElse: () => ContextAwarenessLevel.medium,
          );
        } else {
          contextLevel = ContextAwarenessLevel.medium;
        }
      } catch (_) {
        contextLevel = ContextAwarenessLevel.medium;
      }
      
      final isVisible = snapshot['isVisible'] as bool? ?? false;
      
      state = state.copyWith(
        currentMode: mode,
        isVisible: isVisible,
        contextAwarenessLevel: contextLevel,
      );
      
      return AssistantStateResult.success('状态已从快照恢复');
    } catch (e, stackTrace) {
      final error = AssistantStateException('恢复状态快照失败', e, stackTrace);
      
      if (kDebugMode) {
        print(error);
      }
      
      return AssistantStateResult.failure('恢复状态快照失败', error);
    }
  }
  
  @override
  void dispose() {
    _globalContextSubscription?.cancel();
    super.dispose();
  }
}

/// 2025-03-17: 新增 - AI助手状态提供者
final assistantStateProvider = StateNotifierProvider<AssistantStateNotifier, AssistantState>((ref) {
  // 创建全局助手服务的实例
  final assistantService = GlobalAssistantService();
  
  // 返回状态通知器
  return AssistantStateNotifier(assistantService);
});

/// 2025-03-17: 新增 - 当前助手模式提供者
final currentAssistantModeProvider = Provider<AssistantMode>((ref) {
  return ref.watch(assistantStateProvider).currentMode;
});

/// 2025-03-17: 新增 - 助手可见性提供者
final assistantVisibilityProvider = Provider<bool>((ref) {
  return ref.watch(assistantStateProvider).isVisible;
});

/// 2025-03-17: 新增 - 上下文感知级别提供者
final contextAwarenessLevelProvider = Provider<ContextAwarenessLevel>((ref) {
  return ref.watch(assistantStateProvider).contextAwarenessLevel;
});

/// 2025-03-17: 新增 - 全局上下文提供者
final globalContextProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(assistantStateProvider).globalContext;
});

/// 2025-03-17: 新增 - 最近错误提供者
final lastAssistantErrorProvider = Provider<String?>((ref) {
  return ref.watch(assistantStateProvider).lastError;
}); 