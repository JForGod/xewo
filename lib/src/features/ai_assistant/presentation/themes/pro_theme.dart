import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 专业模式主题
class ProTheme {
  // 专业模式特定变量
  static const double borderRadius = 12.0;
  static const double spacingUnit = 12.0;
  static const double fontSizeBase = 13.0;
  static const double buttonSize = 36.0;
  
  // 专业模式颜色
  static const Color primaryColor = Color(0xFF2389FF);
  static const Color secondaryColor = Color(0xFF8D70FF);
  static const Color accentColor = Color(0xFF6FD08C);
  static const Color backgroundColor = Color(0xFF131320);
  static const Color surfaceColor = Color(0xFF1E1E2D);
  
  // 专业模式特定装饰
  static BoxDecoration get containerDecoration => BoxDecoration(
    color: Colors.black.withOpacity(0.3),
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: AIAssistantTheme.glassShadow(),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 0.5,
    ),
  );
  
  // 专业模式文本样式
  static TextStyle get headingStyle => const TextStyle(
    color: Colors.white,
    fontSize: fontSizeBase * 1.2,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  
  static TextStyle get bodyStyle => TextStyle(
    color: Colors.white.withOpacity(0.9),
    fontSize: fontSizeBase,
    letterSpacing: 0.2,
  );
  
  static TextStyle get captionStyle => TextStyle(
    color: Colors.white.withOpacity(0.6),
    fontSize: fontSizeBase * 0.8,
    letterSpacing: 0.2,
  );
  
  // 控制台文本样式
  static TextStyle get consoleTextStyle => const TextStyle(
    color: Color(0xFFD7DAE0),
    fontSize: fontSizeBase * 0.9,
    fontFamily: 'SF Mono',
    height: 1.5,
  );
  
  // 专业模式按钮样式
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingUnit,
      vertical: spacingUnit / 2,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius / 2),
    ),
    textStyle: const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: fontSizeBase,
      letterSpacing: 0.5,
    ),
  );
}
