import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/editor/theme_manager.dart';

/// 主题服务提供者
final themeServiceProvider = Provider<ThemeService>((ref) {
  throw UnimplementedError('themeServiceProvider 未初始化');
});

/// 主题服务类，负责编辑器主题的管理、导入和导出
class ThemeService {
  final SharedPreferences prefs;
  final List<EditorTheme> _availableThemes = [];
  late EditorTheme _currentTheme;
  
  static const String _themesKey = 'editor_themes';
  static const String _currentThemeKey = 'current_theme_id';
  
  ThemeService({required this.prefs}) {
    _initThemes();
  }
  
  /// 初始化主题
  void _initThemes() {
    // 添加默认主题
    _availableThemes.add(EditorThemeManager.defaultLightTheme);
    _availableThemes.add(EditorThemeManager.defaultDarkTheme);
    
    // 从SharedPreferences加载保存的主题
    final savedThemesJson = prefs.getStringList(_themesKey);
    if (savedThemesJson != null) {
      for (final themeJson in savedThemesJson) {
        try {
          final themeMap = jsonDecode(themeJson) as Map<String, dynamic>;
          final theme = EditorTheme.fromJson(themeMap);
          
          // 避免重复添加默认主题
          if (!_availableThemes.any((t) => t.id == theme.id)) {
            _availableThemes.add(theme);
          }
        } catch (e) {
          debugPrint('加载主题出错: $e');
        }
      }
    }
    
    // 设置当前主题
    final currentThemeId = prefs.getString(_currentThemeKey) ?? 
                          EditorThemeManager.defaultLightTheme.id;
    _currentTheme = _availableThemes.firstWhere(
      (theme) => theme.id == currentThemeId,
      orElse: () => EditorThemeManager.defaultLightTheme
    );
  }
  
  /// 获取当前主题
  EditorTheme getCurrentTheme() => _currentTheme;
  
  /// 获取所有可用主题
  List<EditorTheme> getAvailableThemes() => List.unmodifiable(_availableThemes);
  
  /// 设置当前主题
  Future<void> setCurrentTheme(String themeId) async {
    final theme = _availableThemes.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => _currentTheme
    );
    
    if (theme.id != _currentTheme.id) {
      _currentTheme = theme;
      await prefs.setString(_currentThemeKey, themeId);
    }
  }
  
  /// 添加新主题
  Future<bool> addTheme(EditorTheme theme) async {
    // 检查ID是否重复
    if (_availableThemes.any((t) => t.id == theme.id)) {
      return false;
    }
    
    _availableThemes.add(theme);
    return await _saveThemes();
  }
  
  /// 更新现有主题
  Future<bool> updateTheme(EditorTheme theme) async {
    final index = _availableThemes.indexWhere((t) => t.id == theme.id);
    if (index == -1) {
      return false;
    }
    
    // 不允许修改默认主题
    if (_availableThemes[index].id == EditorThemeManager.defaultLightTheme.id ||
        _availableThemes[index].id == EditorThemeManager.defaultDarkTheme.id) {
      return false;
    }
    
    _availableThemes[index] = theme;
    
    // 如果更新的是当前主题，更新当前主题引用
    if (_currentTheme.id == theme.id) {
      _currentTheme = theme;
    }
    
    return await _saveThemes();
  }
  
  /// 删除主题
  Future<bool> deleteTheme(String themeId) async {
    // 不允许删除默认主题
    if (themeId == EditorThemeManager.defaultLightTheme.id ||
        themeId == EditorThemeManager.defaultDarkTheme.id) {
      return false;
    }
    
    final index = _availableThemes.indexWhere((t) => t.id == themeId);
    if (index == -1) {
      return false;
    }
    
    // 如果删除的是当前主题，切换到默认主题
    if (_currentTheme.id == themeId) {
      _currentTheme = EditorThemeManager.defaultLightTheme;
      await prefs.setString(_currentThemeKey, _currentTheme.id);
    }
    
    _availableThemes.removeAt(index);
    return await _saveThemes();
  }
  
  /// 保存所有自定义主题到SharedPreferences
  Future<bool> _saveThemes() async {
    final customThemes = _availableThemes.where((theme) => 
      theme.id != EditorThemeManager.defaultLightTheme.id &&
      theme.id != EditorThemeManager.defaultDarkTheme.id
    ).toList();
    
    final List<String> themesJson = [];
    for (final theme in customThemes) {
      themesJson.add(jsonEncode(theme.toJson()));
    }
    
    return await prefs.setStringList(_themesKey, themesJson);
  }
  
  /// 导出主题到文件
  Future<bool> exportTheme(String themeId, String filePath) async {
    final theme = _availableThemes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => throw Exception('主题不存在')
    );
    
    try {
      final file = File(filePath);
      final themeJson = jsonEncode(theme.toJson());
      await file.writeAsString(themeJson);
      return true;
    } catch (e) {
      debugPrint('导出主题失败: $e');
      return false;
    }
  }
  
  /// 从文件导入主题
  Future<EditorTheme?> importTheme(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }
      
      final themeJson = await file.readAsString();
      final themeMap = jsonDecode(themeJson) as Map<String, dynamic>;
      final theme = EditorTheme.fromJson(themeMap);
      
      // 如果主题ID存在，生成新ID
      if (_availableThemes.any((t) => t.id == theme.id)) {
        final newId = '${theme.id}_${DateTime.now().millisecondsSinceEpoch}';
        final updatedTheme = theme.copyWith(id: newId);
        if (await addTheme(updatedTheme)) {
          return updatedTheme;
        }
      } else {
        if (await addTheme(theme)) {
          return theme;
        }
      }
    } catch (e) {
      debugPrint('导入主题失败: $e');
    }
    return null;
  }
} 