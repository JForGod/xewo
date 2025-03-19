import 'package:flutter/material.dart';

class AsstAnimations {
  // 透明度动画
  static Animation<double> fadeInOut(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  // 缩放动画
  static Animation<double> scale(
    AnimationController controller, {
    double begin = 0.8, 
    double end = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ),
    );
  }
  
  // 位移动画
  static Animation<Offset> slide(
    AnimationController controller, {
    Offset begin = const Offset(0.0, 0.2),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }
  
  // 旋转动画
  static Animation<double> rotate(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  // 脉冲动画
  static Animation<double> pulse(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(controller);
  }
  
  // 波纹效果动画
  static Animation<double> ripple(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(controller);
  }
  
  // 状态转换动画配置
  static final stateTransition = {
    'duration': const Duration(milliseconds: 300),
    'curve': Curves.easeInOut,
  };
  
  // 手势轨迹动画
  static final gestureTrail = {
    'duration': const Duration(milliseconds: 800),
    'curve': Curves.easeOutQuad,
  };
  
  // 语音波纹动画
  static final voiceRipple = {
    'duration': const Duration(milliseconds: 1500),
    'curve': Curves.easeInOut,
  };
  
  // 全局展示动画
  static final globalShow = {
    'duration': const Duration(milliseconds: 400),
    'curve': Curves.easeOutBack,
  };
  
  // 全局隐藏动画
  static final globalHide = {
    'duration': const Duration(milliseconds: 300),
    'curve': Curves.easeIn,
  };
  
  // 模式切换动画
  static final modeSwitch = {
    'duration': const Duration(milliseconds: 500),
    'curve': Curves.easeInOutCubic,
  };
}
