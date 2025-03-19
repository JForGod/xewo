import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 应用主题常量
class AppTheme {
  // 颜色系统
  static const Color primary500 = Color(0xFF2196F3);  // 基准色
  
  // 中性色
  static const Color neutral50 = Color(0xFFFAFAFA);   // 导航栏背景
  static const Color neutral100 = Color(0xFFF5F5F5);  // 主内容区背景
  static const Color neutral200 = Color(0xFFEEEEEE);  // 编辑器背景
  static const Color neutral600 = Color(0xFF757575);  // 正文
  static const Color neutral700 = Color(0xFF616161);  // 次标题
  static const Color neutral800 = Color(0xFF424242);  // 标题
  static const Color neutral900 = Color(0xFF212121);  // 深色文本

  // 主色调变体
  static const Color primary50 = Color(0xFFE3F2FD);   // 悬停背景
  static const Color primary100 = Color(0xFFBBDEFB);  // 选中背景
  static const Color primary300 = Color(0xFF64B5F6);  // 次要按钮
  static const Color primary400 = Color(0xFF42A5F5);  // 主要按钮
  static const Color primary600 = Color(0xFF1E88E5);  // 主要文本
  static const Color primary700 = Color(0xFF1976D2);  // 强调文本

  // 间距系统
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // 字号系统
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;

  // 圆角
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;

  // 布局尺寸
  static const double navBarWidth = 210.0;
  static const double maxContentWidth = 1200.0;
  static const double aiAssistantWidth = 360.0;

  // 组件尺寸
  static const double navItemHeight = 40.0;

  // 阴影
  static final BoxShadow shadowLg = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 16,
    offset: const Offset(0, 8),
  );

  // 应用程序主题
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary500,
      onPrimary: Colors.white,
      secondary: primary400,
      onSecondary: Colors.white,
      surface: neutral50,
      onSurface: neutral900,
      background: neutral100,
      onBackground: neutral900,
    ),
    scaffoldBackgroundColor: neutral100,
    appBarTheme: AppBarTheme(
      backgroundColor: neutral50,
      foregroundColor: neutral900,
      elevation: 0,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: neutral900,
        fontSize: fontSizeBase,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: neutral900,
        fontSize: fontSizeSm,
      ),
      bodyMedium: TextStyle(
        color: neutral700,
        fontSize: fontSizeSm,
      ),
    ),
  );
  
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primary400,
      onPrimary: Colors.white,
      secondary: primary300,
      onSecondary: Colors.white,
      surface: neutral900,
      onSurface: neutral50,
      background: neutral800,
      onBackground: neutral50,
    ),
    scaffoldBackgroundColor: neutral900,
    appBarTheme: AppBarTheme(
      backgroundColor: neutral900,
      foregroundColor: neutral50,
      elevation: 0,
    ),
    textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
    fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  // 颜色常量
  static const Color secondary = Color(0xFF64B5F6);
  static const Color accent = Color(0xFF42A5F5);
} 