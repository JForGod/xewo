// 2025-03-17: 新增 - 输入指示器组件

import 'package:flutter/material.dart';

/// 显示AI助手"正在输入"的动画指示器
class TypingIndicator extends StatefulWidget {
  /// 圆点颜色
  final Color dotColor;
  
  /// 背景颜色
  final Color backgroundColor;
  
  /// 构造函数
  const TypingIndicator({
    Key? key,
    this.dotColor = Colors.white,
    this.backgroundColor = Colors.transparent,
  }) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  final List<Animation<double>> _animations = [];
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // 为每个点创建一个错开的动画
    final delayInterval = 0.2;
    for (int i = 0; i < 3; i++) {
      final delay = i * delayInterval;
      final begin = 0.0 + delay;
      final end = 0.5 + delay;
      
      _animations.add(
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.0)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(begin % 1.0, (end % 1.0 == 0) ? 1.0 : end % 1.0),
          ),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          const SizedBox(width: 4),
          _buildDot(1),
          const SizedBox(width: 4),
          _buildDot(2),
        ],
      ),
    );
  }
  
  /// 构建单个动画点
  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _animations[index].value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.dotColor.withOpacity(0.5 + 0.5 * _animations[index].value),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
} 