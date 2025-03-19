import 'package:flutter/material.dart';

/// 主题常量
class ThemeConstants {
  // 基础颜色
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  
  // 浅色主题颜色
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightTextPrimaryColor = Color(0xFF212121);
  static const Color lightTextSecondaryColor = Color(0xFF757575);
  static const Color lightDividerColor = Color(0xFFBDBDBD);
  
  // 深色主题颜色
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkTextPrimaryColor = Color(0xFFFFFFFF);
  static const Color darkTextSecondaryColor = Color(0xFFB0B0B0);
  static const Color darkDividerColor = Color(0xFF424242);
  
  // 尺寸
  static const double fontSize = 16.0;
  static const double fontSizeSmall = 14.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeExtraLarge = 24.0;
  
  static const double spacing = 8.0;
  static const double spacingSmall = 4.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingExtraLarge = 24.0;
  
  static const double borderRadius = 8.0;
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusExtraLarge = 24.0;
  
  static const double iconSize = 24.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeExtraLarge = 48.0;
  
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 56.0;
  
  static const double inputHeight = 56.0;
  static const double inputHeightSmall = 48.0;
  static const double inputHeightLarge = 64.0;
  
  // 动画时长
  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Duration animationDurationShort = Duration(milliseconds: 150);
  static const Duration animationDurationLong = Duration(milliseconds: 350);
  
  // 字体
  static const String fontFamily = 'PingFang SC';
  static const String fontFamilySecondary = 'Noto Sans SC';
  
  // 阴影
  static List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  ThemeConstants._(); // 私有构造函数，防止实例化
}
