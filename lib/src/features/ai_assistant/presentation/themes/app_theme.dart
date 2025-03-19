import 'package:flutter/material.dart';
import 'dart:ui';
import '../../domain/models/assistant_mode.dart';

/// 全局AI助手的主题定义
class AIAssistantTheme {
  // 全局变量
  static const double defaultRadius = 16.0;
  static const double defaultSpacing = 16.0;
  static const double defaultFontSize = 14.0;
  
  // 玻璃态效果背景滤镜
  static ImageFilter glassBlur({double sigma = 10.0}) {
    return ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
  }
  
  // 玻璃态效果阴影
  static List<BoxShadow> glassShadow() {
    return [
      BoxShadow(
        color: Colors.white.withOpacity(0.05),
        blurRadius: 20,
        spreadRadius: -5,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 10,
        spreadRadius: -10,
        offset: const Offset(0, 5),
      ),
    ];
  }
  
  // 玻璃态容器装饰
  static BoxDecoration glassDecoration({
    double borderRadius = defaultRadius,
    Color baseColor = Colors.white,
    double opacity = 0.15,
  }) {
    return BoxDecoration(
      color: baseColor.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: glassShadow(),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 0.5,
      ),
    );
  }
  
  // 根据模式获取主色
  static Color getPrimaryColorByMode(AssistantMode mode) {
    switch (mode) {
      case AssistantMode.guardian:
        return const Color(0xFF7C5CE0); // 紫色
      case AssistantMode.pro:
        return const Color(0xFF2389FF); // 深蓝色
      case AssistantMode.standard:
      default:
        return const Color(0xFF4F7DC9); // 蓝色
    }
  }
  
  // 根据模式获取次要色
  static Color getAccentColorByMode(AssistantMode mode) {
    switch (mode) {
      case AssistantMode.guardian:
        return const Color(0xFFE06CA0); // 粉色
      case AssistantMode.pro:
        return const Color(0xFF6FD08C); // 绿色
      case AssistantMode.standard:
      default:
        return const Color(0xFF82D2B4); // 青色
    }
  }
  
  // 通用动画持续时间
  static Duration animationDuration = const Duration(milliseconds: 300);
  static Duration longAnimationDuration = const Duration(milliseconds: 500);
}
