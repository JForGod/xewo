import 'package:flutter/material.dart';

/// 主题工具类
class ThemeUtils {
  /// 私有构造函数，防止实例化
  ThemeUtils._();
  
  /// 获取图标颜色
  static Color getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }
  
  /// 获取主要文本颜色
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
  
  /// 获取次要文本颜色
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
  }
  
  /// 获取禁用颜色
  static Color getDisabledColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white38
        : Colors.black38;
  }
  
  /// 获取分隔线颜色
  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.black12;
  }
  
  /// 获取卡片背景颜色
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }
  
  /// 获取背景颜色
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }
  
  /// 获取主题色
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).primaryColor;
  }
  
  /// 获取强调色
  static Color getAccentColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }
}

/// 获取图标颜色的便捷方法
Color getIconColor(BuildContext context) {
  return ThemeUtils.getIconColor(context);
}

/// 获取主要文本颜色的便捷方法
Color getTextColor(BuildContext context) {
  return ThemeUtils.getTextColor(context);
}

/// 获取次要文本颜色的便捷方法
Color getSecondaryTextColor(BuildContext context) {
  return ThemeUtils.getSecondaryTextColor(context);
}

/// 获取禁用颜色的便捷方法
Color getDisabledColor(BuildContext context) {
  return ThemeUtils.getDisabledColor(context);
}

/// 获取分隔线颜色的便捷方法
Color getDividerColor(BuildContext context) {
  return ThemeUtils.getDividerColor(context);
}

/// 获取卡片背景颜色的便捷方法
Color getCardColor(BuildContext context) {
  return ThemeUtils.getCardColor(context);
}

/// 获取背景颜色的便捷方法
Color getBackgroundColor(BuildContext context) {
  return ThemeUtils.getBackgroundColor(context);
}

/// 获取主题色的便捷方法
Color getPrimaryColor(BuildContext context) {
  return ThemeUtils.getPrimaryColor(context);
}

/// 获取强调色的便捷方法
Color getAccentColor(BuildContext context) {
  return ThemeUtils.getAccentColor(context);
} 