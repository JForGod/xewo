import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 设置服务提供者
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// 设置服务类
/// 
/// 负责管理应用程序的设置，包括用户偏好、界面配置、最近打开的项目等
class SettingsService {
  late SharedPreferences _prefs;
  bool _initialized = false;

  /// 初始化设置服务
  Future<void> initialize() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// 确保服务已初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// 获取字符串设置
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs.getString(key);
  }

  /// 设置字符串设置
  Future<bool> setString(String key, String value) async {
    await _ensureInitialized();
    return await _prefs.setString(key, value);
  }

  /// 获取布尔设置
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    await _ensureInitialized();
    return _prefs.getBool(key) ?? defaultValue;
  }

  /// 设置布尔设置
  Future<bool> setBool(String key, bool value) async {
    await _ensureInitialized();
    return await _prefs.setBool(key, value);
  }

  /// 获取整数设置
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    await _ensureInitialized();
    return _prefs.getInt(key) ?? defaultValue;
  }

  /// 设置整数设置
  Future<bool> setInt(String key, int value) async {
    await _ensureInitialized();
    return await _prefs.setInt(key, value);
  }

  /// 获取双精度浮点数设置
  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    await _ensureInitialized();
    return _prefs.getDouble(key) ?? defaultValue;
  }

  /// 设置双精度浮点数设置
  Future<bool> setDouble(String key, double value) async {
    await _ensureInitialized();
    return await _prefs.setDouble(key, value);
  }

  /// 获取字符串列表设置
  Future<List<String>> getStringList(String key, {List<String> defaultValue = const []}) async {
    await _ensureInitialized();
    return _prefs.getStringList(key) ?? defaultValue;
  }

  /// 设置字符串列表设置
  Future<bool> setStringList(String key, List<String> value) async {
    await _ensureInitialized();
    return await _prefs.setStringList(key, value);
  }

  /// 获取JSON对象设置
  Future<Map<String, dynamic>?> getJson(String key) async {
    await _ensureInitialized();
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decoding JSON for key $key: $e');
      return null;
    }
  }

  /// 设置JSON对象设置
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    await _ensureInitialized();
    try {
      final jsonString = json.encode(value);
      return await _prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('Error encoding JSON for key $key: $e');
      return false;
    }
  }

  /// 检查设置是否存在
  Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    return _prefs.containsKey(key);
  }

  /// 移除设置
  Future<bool> remove(String key) async {
    await _ensureInitialized();
    return await _prefs.remove(key);
  }

  /// 清除所有设置
  Future<bool> clear() async {
    await _ensureInitialized();
    return await _prefs.clear();
  }

  // ===== 应用特定设置 =====

  /// 保存上次打开的项目路径
  Future<bool> saveLastOpenedProjectPath(String path) async {
    return await setString('last_opened_project_path', path);
  }

  /// 获取上次打开的项目路径
  Future<String?> getLastOpenedProjectPath() async {
    return await getString('last_opened_project_path');
  }

  /// 保存最近打开的项目列表
  Future<bool> saveRecentProjects(List<String> projects) async {
    return await setStringList('recent_projects', projects);
  }

  /// 获取最近打开的项目列表
  Future<List<String>> getRecentProjects() async {
    return await getStringList('recent_projects');
  }

  /// 添加项目到最近打开的项目列表
  Future<bool> addToRecentProjects(String projectPath) async {
    final recentProjects = await getRecentProjects();
    
    // 创建一个新的可变列表
    final List<String> mutableList = List<String>.from(recentProjects);
    
    // 如果已存在，先移除
    mutableList.remove(projectPath);
    
    // 添加到列表开头
    mutableList.insert(0, projectPath);
    
    // 限制列表大小为10个
    if (mutableList.length > 10) {
      mutableList.removeLast();
    }
    
    return await saveRecentProjects(mutableList);
  }

  /// 保存编辑器主题
  Future<bool> saveEditorTheme(String theme) async {
    return await setString('editor_theme', theme);
  }

  /// 获取编辑器主题
  Future<String> getEditorTheme({String defaultTheme = 'light'}) async {
    return await getString('editor_theme') ?? defaultTheme;
  }

  /// 保存字体大小
  Future<bool> saveFontSize(double size) async {
    return await setDouble('font_size', size);
  }

  /// 获取字体大小
  Future<double> getFontSize({double defaultSize = 14.0}) async {
    return await getDouble('font_size', defaultValue: defaultSize);
  }

  /// 保存是否显示行号
  Future<bool> saveShowLineNumbers(bool show) async {
    return await setBool('show_line_numbers', show);
  }

  /// 获取是否显示行号
  Future<bool> getShowLineNumbers({bool defaultValue = true}) async {
    return await getBool('show_line_numbers', defaultValue: defaultValue);
  }

  /// 保存是否显示小地图
  Future<bool> saveShowMinimap(bool show) async {
    return await setBool('show_minimap', show);
  }

  /// 获取是否显示小地图
  Future<bool> getShowMinimap({bool defaultValue = true}) async {
    return await getBool('show_minimap', defaultValue: defaultValue);
  }

  /// 保存文件树宽度
  Future<bool> saveFileTreeWidth(double width) async {
    return await setDouble('file_tree_width', width);
  }

  /// 获取文件树宽度
  Future<double> getFileTreeWidth({double defaultWidth = 280.0}) async {
    return await getDouble('file_tree_width', defaultValue: defaultWidth);
  }

  /// 保存用户模式
  Future<bool> saveUserMode(String mode) async {
    return await setString('user_mode', mode);
  }

  /// 获取用户模式
  Future<String> getUserMode({String defaultMode = 'standard'}) async {
    return await getString('user_mode') ?? defaultMode;
  }

  /// 保存已展开的目录
  Future<bool> saveExpandedDirectories(List<String> directories) async {
    return await setStringList('expanded_directories', directories);
  }

  /// 获取已展开的目录
  Future<List<String>> getExpandedDirectories() async {
    return await getStringList('expanded_directories');
  }

  /// 保存已打开的文件
  Future<bool> saveOpenFiles(List<String> files) async {
    return await setStringList('open_files', files);
  }

  /// 获取已打开的文件
  Future<List<String>> getOpenFiles() async {
    return await getStringList('open_files');
  }

  /// 保存当前活动文件
  Future<bool> saveActiveFile(String? filePath) async {
    if (filePath == null) {
      return await remove('active_file');
    }
    return await setString('active_file', filePath);
  }

  /// 获取当前活动文件
  Future<String?> getActiveFile() async {
    return await getString('active_file');
  }

  /// 保存文件内容缓存
  Future<bool> saveFileCache(String filePath, String content) async {
    final cacheKey = 'file_cache_${filePath.hashCode}';
    return await setString(cacheKey, content);
  }

  /// 获取文件内容缓存
  Future<String?> getFileCache(String filePath) async {
    final cacheKey = 'file_cache_${filePath.hashCode}';
    return await getString(cacheKey);
  }

  /// 清除文件内容缓存
  Future<bool> clearFileCache(String filePath) async {
    final cacheKey = 'file_cache_${filePath.hashCode}';
    return await remove(cacheKey);
  }

  /// 保存智能隐藏设置
  Future<bool> saveSmartHideEnabled(bool enabled) async {
    return await setBool('smart_hide_enabled', enabled);
  }

  /// 获取智能隐藏设置
  Future<bool> getSmartHideEnabled({bool defaultValue = true}) async {
    return await getBool('smart_hide_enabled', defaultValue: defaultValue);
  }

  /// 保存智能隐藏延迟
  Future<bool> saveSmartHideDelay(int delayInSeconds) async {
    return await setInt('smart_hide_delay', delayInSeconds);
  }

  /// 获取智能隐藏延迟
  Future<int> getSmartHideDelay({int defaultValue = 20}) async {
    return await getInt('smart_hide_delay', defaultValue: defaultValue);
  }

  /// 保存忽略的文件和目录
  Future<bool> saveIgnoredPaths(List<String> paths) async {
    return await setStringList('ignored_paths', paths);
  }

  /// 获取忽略的文件和目录
  Future<List<String>> getIgnoredPaths() async {
    return await getStringList('ignored_paths');
  }

  /// 保存忽略的文件扩展名
  Future<bool> saveIgnoredExtensions(List<String> extensions) async {
    return await setStringList('ignored_extensions', extensions);
  }

  /// 获取忽略的文件扩展名
  Future<List<String>> getIgnoredExtensions() async {
    final defaultExtensions = [
      'exe', 'dll', 'so', 'dylib', 'obj', 'o', 'a', 'lib',
      'zip', 'tar', 'gz', 'rar', '7z',
      'png', 'jpg', 'jpeg', 'gif', 'bmp', 'ico',
      'mp3', 'mp4', 'avi', 'mov', 'flv',
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'
    ];
    return await getStringList('ignored_extensions', defaultValue: defaultExtensions);
  }

  /// 保存用户界面设置
  Future<bool> saveUiSettings(Map<String, dynamic> settings) async {
    return await setJson('ui_settings', settings);
  }

  /// 获取用户界面设置
  Future<Map<String, dynamic>> getUiSettings() async {
    return await getJson('ui_settings') ?? {};
  }
}
