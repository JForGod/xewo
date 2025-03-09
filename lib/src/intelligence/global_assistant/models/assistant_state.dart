import 'package:flutter/material.dart';
import 'assistant_mode.dart';

/// AI助手状态
class AssistantState {
  /// 当前模式
  final AssistantMode mode;
  
  /// 是否最小化
  final bool isMinimized;
  
  /// 是否正在处理请求
  final bool isProcessing;
  
  /// 错误信息
  final String? error;
  
  /// 上下文数据
  final Map<String, dynamic> contextData;
  
  const AssistantState({
    this.mode = AssistantMode.standard,
    this.isMinimized = false,
    this.isProcessing = false,
    this.error,
    this.contextData = const {},
  });
  
  AssistantState copyWith({
    AssistantMode? mode,
    bool? isMinimized,
    bool? isProcessing,
    String? error,
    Map<String, dynamic>? contextData,
  }) {
    return AssistantState(
      mode: mode ?? this.mode,
      isMinimized: isMinimized ?? this.isMinimized,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      contextData: contextData ?? this.contextData,
    );
  }
} 