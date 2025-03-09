import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_preferences_provider.dart';

/// 编辑器设置状态类
class EditorSettings {
  final String fontFamily;
  final double fontSize;
  final bool wordWrap;
  final bool lineNumbers;
  final bool highlightCurrentLine;
  final bool autoIndent;
  final bool autoCloseBrackets;
  final bool autoCloseTags;
  final bool tabSize;
  final int indentSize;
  final bool useTabs;
  final bool showWhitespace;
  final bool showIndentGuides;
  final bool minimap;
  final bool smoothScrolling;
  final bool autoSave;
  final int autoSaveInterval; // 秒

  const EditorSettings({
    this.fontFamily = 'JetBrains Mono',
    this.fontSize = 14.0,
    this.wordWrap = true,
    this.lineNumbers = true,
    this.highlightCurrentLine = true,
    this.autoIndent = true,
    this.autoCloseBrackets = true,
    this.autoCloseTags = true,
    this.tabSize = true,
    this.indentSize = 2,
    this.useTabs = false,
    this.showWhitespace = false,
    this.showIndentGuides = true,
    this.minimap = false,
    this.smoothScrolling = true,
    this.autoSave = true,
    this.autoSaveInterval = 30,
  });

  EditorSettings copyWith({
    String? fontFamily,
    double? fontSize,
    bool? wordWrap,
    bool? lineNumbers,
    bool? highlightCurrentLine,
    bool? autoIndent,
    bool? autoCloseBrackets,
    bool? autoCloseTags,
    bool? tabSize,
    int? indentSize,
    bool? useTabs,
    bool? showWhitespace,
    bool? showIndentGuides,
    bool? minimap,
    bool? smoothScrolling,
    bool? autoSave,
    int? autoSaveInterval,
  }) {
    return EditorSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      wordWrap: wordWrap ?? this.wordWrap,
      lineNumbers: lineNumbers ?? this.lineNumbers,
      highlightCurrentLine: highlightCurrentLine ?? this.highlightCurrentLine,
      autoIndent: autoIndent ?? this.autoIndent,
      autoCloseBrackets: autoCloseBrackets ?? this.autoCloseBrackets,
      autoCloseTags: autoCloseTags ?? this.autoCloseTags,
      tabSize: tabSize ?? this.tabSize,
      indentSize: indentSize ?? this.indentSize,
      useTabs: useTabs ?? this.useTabs,
      showWhitespace: showWhitespace ?? this.showWhitespace,
      showIndentGuides: showIndentGuides ?? this.showIndentGuides,
      minimap: minimap ?? this.minimap,
      smoothScrolling: smoothScrolling ?? this.smoothScrolling,
      autoSave: autoSave ?? this.autoSave,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
    );
  }

  /// 从SharedPreferences加载设置
  static Future<EditorSettings> fromPrefs(SharedPreferences prefs) async {
    return EditorSettings(
      fontFamily: prefs.getString('editor.fontFamily') ?? 'JetBrains Mono',
      fontSize: prefs.getDouble('editor.fontSize') ?? 14.0,
      wordWrap: prefs.getBool('editor.wordWrap') ?? true,
      lineNumbers: prefs.getBool('editor.lineNumbers') ?? true,
      highlightCurrentLine: prefs.getBool('editor.highlightCurrentLine') ?? true,
      autoIndent: prefs.getBool('editor.autoIndent') ?? true,
      autoCloseBrackets: prefs.getBool('editor.autoCloseBrackets') ?? true,
      autoCloseTags: prefs.getBool('editor.autoCloseTags') ?? true,
      tabSize: prefs.getBool('editor.tabSize') ?? true,
      indentSize: prefs.getInt('editor.indentSize') ?? 2,
      useTabs: prefs.getBool('editor.useTabs') ?? false,
      showWhitespace: prefs.getBool('editor.showWhitespace') ?? false,
      showIndentGuides: prefs.getBool('editor.showIndentGuides') ?? true,
      minimap: prefs.getBool('editor.minimap') ?? false,
      smoothScrolling: prefs.getBool('editor.smoothScrolling') ?? true,
      autoSave: prefs.getBool('editor.autoSave') ?? true,
      autoSaveInterval: prefs.getInt('editor.autoSaveInterval') ?? 30,
    );
  }

  /// 保存设置到SharedPreferences
  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setString('editor.fontFamily', fontFamily);
    await prefs.setDouble('editor.fontSize', fontSize);
    await prefs.setBool('editor.wordWrap', wordWrap);
    await prefs.setBool('editor.lineNumbers', lineNumbers);
    await prefs.setBool('editor.highlightCurrentLine', highlightCurrentLine);
    await prefs.setBool('editor.autoIndent', autoIndent);
    await prefs.setBool('editor.autoCloseBrackets', autoCloseBrackets);
    await prefs.setBool('editor.autoCloseTags', autoCloseTags);
    await prefs.setBool('editor.tabSize', tabSize);
    await prefs.setInt('editor.indentSize', indentSize);
    await prefs.setBool('editor.useTabs', useTabs);
    await prefs.setBool('editor.showWhitespace', showWhitespace);
    await prefs.setBool('editor.showIndentGuides', showIndentGuides);
    await prefs.setBool('editor.minimap', minimap);
    await prefs.setBool('editor.smoothScrolling', smoothScrolling);
    await prefs.setBool('editor.autoSave', autoSave);
    await prefs.setInt('editor.autoSaveInterval', autoSaveInterval);
  }
}

/// 编辑器设置状态管理类
class EditorSettingsNotifier extends StateNotifier<EditorSettings> {
  final SharedPreferences _prefs;

  EditorSettingsNotifier(this._prefs) : super(const EditorSettings()) {
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final settings = await EditorSettings.fromPrefs(_prefs);
    state = settings;
  }

  /// 更新字体
  Future<void> updateFontFamily(String fontFamily) async {
    state = state.copyWith(fontFamily: fontFamily);
    await state.saveToPrefs(_prefs);
  }

  /// 更新字体大小
  Future<void> updateFontSize(double fontSize) async {
    state = state.copyWith(fontSize: fontSize);
    await state.saveToPrefs(_prefs);
  }

  /// 更新自动换行
  Future<void> updateWordWrap(bool wordWrap) async {
    state = state.copyWith(wordWrap: wordWrap);
    await state.saveToPrefs(_prefs);
  }

  /// 更新行号显示
  Future<void> updateLineNumbers(bool lineNumbers) async {
    state = state.copyWith(lineNumbers: lineNumbers);
    await state.saveToPrefs(_prefs);
  }

  /// 更新当前行高亮
  Future<void> updateHighlightCurrentLine(bool highlightCurrentLine) async {
    state = state.copyWith(highlightCurrentLine: highlightCurrentLine);
    await state.saveToPrefs(_prefs);
  }

  /// 更新自动缩进
  Future<void> updateAutoIndent(bool autoIndent) async {
    state = state.copyWith(autoIndent: autoIndent);
    await state.saveToPrefs(_prefs);
  }

  /// 更新自动闭合括号
  Future<void> updateAutoCloseBrackets(bool autoCloseBrackets) async {
    state = state.copyWith(autoCloseBrackets: autoCloseBrackets);
    await state.saveToPrefs(_prefs);
  }

  /// 更新自动闭合标签
  Future<void> updateAutoCloseTags(bool autoCloseTags) async {
    state = state.copyWith(autoCloseTags: autoCloseTags);
    await state.saveToPrefs(_prefs);
  }

  /// 更新缩进大小
  Future<void> updateIndentSize(int indentSize) async {
    state = state.copyWith(indentSize: indentSize);
    await state.saveToPrefs(_prefs);
  }

  /// 更新使用Tab缩进
  Future<void> updateUseTabs(bool useTabs) async {
    state = state.copyWith(useTabs: useTabs);
    await state.saveToPrefs(_prefs);
  }

  /// 更新显示空白字符
  Future<void> updateShowWhitespace(bool showWhitespace) async {
    state = state.copyWith(showWhitespace: showWhitespace);
    await state.saveToPrefs(_prefs);
  }

  /// 更新显示缩进指南
  Future<void> updateShowIndentGuides(bool showIndentGuides) async {
    state = state.copyWith(showIndentGuides: showIndentGuides);
    await state.saveToPrefs(_prefs);
  }

  /// 更新小地图
  Future<void> updateMinimap(bool minimap) async {
    state = state.copyWith(minimap: minimap);
    await state.saveToPrefs(_prefs);
  }

  /// 更新平滑滚动
  Future<void> updateSmoothScrolling(bool smoothScrolling) async {
    state = state.copyWith(smoothScrolling: smoothScrolling);
    await state.saveToPrefs(_prefs);
  }

  /// 更新自动保存
  Future<void> updateAutoSave(bool autoSave) async {
    state = state.copyWith(autoSave: autoSave);
    await state.saveToPrefs(_prefs);
  }

  /// 更新自动保存间隔
  Future<void> updateAutoSaveInterval(int autoSaveInterval) async {
    state = state.copyWith(autoSaveInterval: autoSaveInterval);
    await state.saveToPrefs(_prefs);
  }
}

/// 编辑器设置提供者
final editorSettingsProvider = StateNotifierProvider<EditorSettingsNotifier, EditorSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return EditorSettingsNotifier(prefs);
}); 