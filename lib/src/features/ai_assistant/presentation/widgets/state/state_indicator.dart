import 'package:flutter/material.dart';
import 'dart:ui';

/// 运行状态指示器
/// 
/// 一个具有Glassmorphism风格的状态指示器，展示AI助手的当前运行状态
/// 包括：活跃、协作和休眠三种基本状态
class StateIndicator extends StatelessWidget {
  /// 当前状态
  final AssistantState state;
  
  /// 自定义尺寸
  final double size;
  
  /// 动画持续时间
  final Duration animationDuration;
  
  /// 构造函数
  const StateIndicator({
    Key? key, 
    required this.state, 
    this.size = 80, 
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: animationDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: _getStateColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: _getStateColor().withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: AnimatedOpacity(
                opacity: state == AssistantState.sleeping ? 0.5 : 1.0,
                duration: animationDuration,
                child: Icon(
                  _getStateIcon(),
                  color: _getStateColor().withOpacity(0.9),
                  size: size * 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 获取状态对应的颜色
  Color _getStateColor() {
    switch (state) {
      case AssistantState.active:
        return const Color(0xFF3A7BFF); // 主色：激活状态
      case AssistantState.collaborating:
        return const Color(0xFF6B7BFF); // 协作状态
      case AssistantState.sleeping:
        return const Color(0xFFAAAAAA); // 休眠状态
    }
  }

  /// 获取状态对应的图标
  IconData _getStateIcon() {
    switch (state) {
      case AssistantState.active:
        return Icons.add_reaction_outlined; // 活跃状态图标
      case AssistantState.collaborating:
        return Icons.handshake_outlined; // 协作状态图标
      case AssistantState.sleeping:
        return Icons.bedtime_outlined; // 休眠状态图标
    }
  }
}

/// 助手运行状态枚举
enum AssistantState {
  /// 活跃状态 - 主动监听并响应用户
  active,
  
  /// 协作状态 - 与用户共同完成任务
  collaborating,
  
  /// 休眠状态 - 最小化资源占用
  sleeping,
} 