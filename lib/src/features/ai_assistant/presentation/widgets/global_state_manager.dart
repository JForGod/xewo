import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../themes/animations.dart';

// 定义助手状态
enum AssistantState {
  idle,      // 休眠状态
  listening, // 监听状态
  thinking,  // 思考状态
  speaking,  // 说话状态
  learning,  // 学习状态
  proactive, // 主动状态
  error,     // 错误状态
}

class GlobalStateManager extends StatefulWidget {
  final AssistantState currentState;
  final Widget child;
  final Function(AssistantState)? onStateChanged;
  final AssistantMode mode;

  const GlobalStateManager({
    Key? key,
    required this.currentState,
    required this.child,
    this.onStateChanged,
    this.mode = AssistantMode.standard,
  }) : super(key: key);

  @override
  State<GlobalStateManager> createState() => _GlobalStateManagerState();
}

class _GlobalStateManagerState extends State<GlobalStateManager> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = AsstAnimations.pulse(_animationController);
    
    if (_shouldAnimate(widget.currentState)) {
      _animationController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(GlobalStateManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentState != oldWidget.currentState) {
      if (_shouldAnimate(widget.currentState)) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _shouldAnimate(AssistantState state) {
    return state == AssistantState.listening ||
           state == AssistantState.thinking ||
           state == AssistantState.speaking;
  }

  Color _getStateColor() {
    switch (widget.currentState) {
      case AssistantState.idle:
        return Colors.grey;
      case AssistantState.listening:
        return Colors.blue;
      case AssistantState.thinking:
        return Colors.purple;
      case AssistantState.speaking:
        return Colors.green;
      case AssistantState.learning:
        return Colors.orange;
      case AssistantState.proactive:
        return Colors.cyan;
      case AssistantState.error:
        return Colors.red;
    }
  }

  String _getStateLabel() {
    switch (widget.currentState) {
      case AssistantState.idle:
        return '休眠中';
      case AssistantState.listening:
        return '聆听中...';
      case AssistantState.thinking:
        return '思考中...';
      case AssistantState.speaking:
        return '回应中...';
      case AssistantState.learning:
        return '学习中...';
      case AssistantState.proactive:
        return '主动模式';
      case AssistantState.error:
        return '出错了';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        Positioned(
          top: 8,
          right: 8,
          child: _buildStateIndicator(),
        ),
      ],
    );
  }

  Widget _buildStateIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _shouldAnimate(widget.currentState)
              ? _pulseAnimation.value
              : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getStateColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStateColor().withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStateColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _getStateLabel(),
                  style: TextStyle(
                    color: _getStateColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
