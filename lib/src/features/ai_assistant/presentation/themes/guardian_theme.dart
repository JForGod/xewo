import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 监护模式主题
class GuardianTheme {
  // 监护模式特定变量
  static const double borderRadius = 18.0;
  static const double spacingUnit = 16.0;
  static const double fontSizeBase = 16.0;
  static const double buttonSize = 50.0;
  
  // 监护模式颜色
  static const Color primaryColor = Color(0xFF7C5CE0);
  static const Color secondaryColor = Color(0xFFE06CA0);
  static const Color backgroundColor = Color(0xFF2A2A40);
  static const Color surfaceColor = Color(0xFF3A3A55);
  static const Color accentColor = Color(0xFF6DE0A0);
  
  // 监护模式特定装饰
  static BoxDecoration get containerDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: AIAssistantTheme.glassShadow(),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor.withOpacity(0.1),
        secondaryColor.withOpacity(0.05),
      ],
    ),
  );
  
  // 监护模式文本样式
  static TextStyle get headingStyle => const TextStyle(
    color: Colors.white,
    fontSize: fontSizeBase * 1.3,
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
  
  // 监护模式按钮样式
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingUnit * 1.5,
      vertical: spacingUnit * 0.75,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius / 2),
    ),
    textStyle: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: fontSizeBase,
    ),
  );
}
