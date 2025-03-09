import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 编辑器主题类，定义编辑器外观
class EditorTheme {
  final String id;
  final String name;
  final String description;
  final bool isDark;
  final Map<String, Color> colors;
  final Color background;
  final Color foreground;
  final Color lineNumber;
  final Color cursor;
  final Color selection;
  final Color gutterBackground;
  final Color gutterForeground;
  final String? fontFamily;
  final double? fontSize;
  
  const EditorTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.isDark,
    required this.colors,
    required this.background,
    required this.foreground,
    required this.lineNumber,
    required this.cursor,
    required this.selection,
    required this.gutterBackground,
    required this.gutterForeground,
    this.fontFamily,
    this.fontSize,
  });
  
  /// 创建主题的副本并更新特定属性
  EditorTheme copyWith({
    String? id,
    String? name,
    String? description,
    bool? isDark,
    Map<String, Color>? colors,
    Color? background,
    Color? foreground,
    Color? lineNumber,
    Color? cursor,
    Color? selection,
    Color? gutterBackground,
    Color? gutterForeground,
    String? fontFamily,
    double? fontSize,
  }) {
    return EditorTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isDark: isDark ?? this.isDark,
      colors: colors ?? Map.from(this.colors),
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      lineNumber: lineNumber ?? this.lineNumber,
      cursor: cursor ?? this.cursor,
      selection: selection ?? this.selection,
      gutterBackground: gutterBackground ?? this.gutterBackground,
      gutterForeground: gutterForeground ?? this.gutterForeground,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }
  
  /// 从JSON创建主题
  factory EditorTheme.fromJson(Map<String, dynamic> json) {
    final Map<String, Color> colors = {};
    (json['colors'] as Map<String, dynamic>).forEach((key, value) {
      colors[key] = Color(value as int);
    });
    
    return EditorTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isDark: json['isDark'] as bool,
      colors: colors,
      background: Color(json['background'] as int),
      foreground: Color(json['foreground'] as int),
      lineNumber: Color(json['lineNumber'] as int),
      cursor: Color(json['cursor'] as int),
      selection: Color(json['selection'] as int),
      gutterBackground: Color(json['gutterBackground'] as int),
      gutterForeground: Color(json['gutterForeground'] as int),
      fontFamily: json['fontFamily'] as String?,
      fontSize: json['fontSize'] as double?,
    );
  }
  
  /// 转换主题为JSON
  Map<String, dynamic> toJson() {
    final Map<String, int> colorsMap = {};
    colors.forEach((key, value) {
      colorsMap[key] = value.value;
    });
    
    return {
      'id': id,
      'name': name,
      'description': description,
      'isDark': isDark,
      'colors': colorsMap,
      'background': background.value,
      'foreground': foreground.value,
      'lineNumber': lineNumber.value,
      'cursor': cursor.value,
      'selection': selection.value,
      'gutterBackground': gutterBackground.value,
      'gutterForeground': gutterForeground.value,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
    };
  }
}

/// 编辑器主题管理器
class EditorThemeManager extends StateNotifier<EditorTheme> {
  EditorThemeManager() : super(defaultLightTheme);
  
  /// 默认亮色主题
  static final EditorTheme defaultLightTheme = EditorTheme(
    id: 'default_light',
    name: '默认浅色主题',
    description: '默认的浅色编辑器主题',
    isDark: false,
    colors: {
      'keyword': const Color(0xFF0000FF),     // 关键字
      'string': const Color(0xFF008000),      // 字符串
      'comment': const Color(0xFF808080),     // 注释
      'number': const Color(0xFF098658),      // 数字
      'function': const Color(0xFF795E26),    // 函数
      'type': const Color(0xFF267F99),        // 类型
      'variable': const Color(0xFF001080),    // 变量
      'operator': const Color(0xFF000000),    // 运算符
      'classname': const Color(0xFF267F99),   // 类名
      'property': const Color(0xFF001080),    // 属性
      'namespace': const Color(0xFF000000),   // 命名空间
      'tag': const Color(0xFF800000),         // 标签
      'attribute': const Color(0xFF0000FF),   // 属性
    },
    background: Colors.white,
    foreground: const Color(0xFF000000),
    lineNumber: const Color(0xFF999999),
    cursor: const Color(0xFF000000),
    selection: const Color(0xFFADD6FF),
    gutterBackground: const Color(0xFFF5F5F5),
    gutterForeground: const Color(0xFF999999),
    fontFamily: 'JetBrains Mono',
    fontSize: 14,
  );
  
  /// 默认暗色主题
  static final EditorTheme defaultDarkTheme = EditorTheme(
    id: 'default_dark',
    name: '默认深色主题',
    description: '默认的深色编辑器主题',
    isDark: true,
    colors: {
      'keyword': const Color(0xFF569CD6),     // 关键字
      'string': const Color(0xFFCE9178),      // 字符串
      'comment': const Color(0xFF6A9955),     // 注释
      'number': const Color(0xFFB5CEA8),      // 数字
      'function': const Color(0xFFDCDCAA),    // 函数
      'type': const Color(0xFF4EC9B0),        // 类型
      'variable': const Color(0xFF9CDCFE),    // 变量
      'operator': const Color(0xFFD4D4D4),    // 运算符
      'classname': const Color(0xFF4EC9B0),   // 类名
      'property': const Color(0xFF9CDCFE),    // 属性
      'namespace': const Color(0xFFD4D4D4),   // 命名空间
      'tag': const Color(0xFF569CD6),         // 标签
      'attribute': const Color(0xFF9CDCFE),   // 属性
    },
    background: const Color(0xFF1E1E1E),
    foreground: const Color(0xFFD4D4D4),
    lineNumber: const Color(0xFF858585),
    cursor: const Color(0xFFAEAFAD),
    selection: const Color(0xFF264F78),
    gutterBackground: const Color(0xFF252526),
    gutterForeground: const Color(0xFF858585),
    fontFamily: 'JetBrains Mono',
    fontSize: 14,
  );
  
  /// 更改当前主题
  void setTheme(EditorTheme theme) {
    state = theme;
  }
  
  /// 切换亮暗主题
  void toggleDarkMode() {
    state = state.isDark ? defaultLightTheme : defaultDarkTheme;
  }
  
  /// 创建自定义主题
  EditorTheme createCustomTheme({
    required String name,
    required String description,
    required bool isDark,
    required Map<String, Color> colors,
    required Color background,
    required Color foreground,
    required Color lineNumber,
    required Color cursor,
    required Color selection,
    required Color gutterBackground,
    required Color gutterForeground,
    String? fontFamily,
    double? fontSize,
  }) {
    // 生成唯一ID
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    
    return EditorTheme(
      id: id,
      name: name,
      description: description,
      isDark: isDark,
      colors: colors,
      background: background,
      foreground: foreground,
      lineNumber: lineNumber,
      cursor: cursor,
      selection: selection,
      gutterBackground: gutterBackground,
      gutterForeground: gutterForeground,
      fontFamily: fontFamily,
      fontSize: fontSize,
    );
  }
}

/// 编辑器主题状态提供者
final editorThemeProvider =
    StateNotifierProvider<EditorThemeManager, EditorTheme>((ref) {
  return EditorThemeManager();
}); 