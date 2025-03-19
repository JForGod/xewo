import 'package:flutter/material.dart';

/// AI助手动画定义
class AssistantAnimations {
  // 唤醒过渡动画
  static Animation<double> wakeUpAnimation(AnimationController controller) {
    return Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }
  
  // 语音识别波纹动画
  static Animation<double> voiceRippleAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }
  
  // 边缘滑出动画
  static Animation<double> edgeSlideAnimation(AnimationController controller) {
    return Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }
  
  // 模式切换动画
  static Animation<double> modeSwitchBlurAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
  }
  
  static Animation<double> modeSwitchScaleAnimation(AnimationController controller) {
    return Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
  }
}
