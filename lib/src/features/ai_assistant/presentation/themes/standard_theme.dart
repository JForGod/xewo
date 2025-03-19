import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 标准模式主题
class StandardTheme {
  // 标准模式特定变量
  static const double borderRadius = 16.0;
  static const double spacingUnit = 12.0;
  static const double fontSizeBase = 14.0;
  static const double buttonSize = 40.0;
  
  // 标准模式颜色
  static const Color primaryColor = Color(0xFF4F7DC9);
  static const Color accentColor = Color(0xFF82D2B4);
  static const Color backgroundColor = Color(0xFF1C1C28);
  static const Color surfaceColor = Color(0xFF2A2A38);
  static const Color headerBackground = Color(0xFF252535);
  
  // 标准模式特定装饰
  static BoxDecoration get containerDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: AIAssistantTheme.glassShadow(),
  );
  
  // 标准模式文本样式
  static TextStyle get headingStyle => const TextStyle(
    color: Colors.white,
    fontSize: fontSizeBase * 1.2,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get bodyStyle => TextStyle(
    color: Colors.white.withOpacity(0.9),
    fontSize: fontSizeBase,
  );
  
  static TextStyle get captionStyle => TextStyle(
    color: Colors.white.withOpacity(0.7),
    fontSize: fontSizeBase * 0.8,
  );
  
  // 标准模式按钮样式
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingUnit * 1.5,
      vertical: spacingUnit * 0.6,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius / 2),
    ),
  );
}
