import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../state/providers/shared_preferences_provider.dart';
import 'logger_service.dart';

/// 应用设置服务，管理应用的各种设置
class SettingsService {
  final SharedPreferences _prefs;
  final LoggerService _logger;
  
  /// 构造函数
  SettingsService(this._prefs, this._logger);
  
  /// 获取字符串值
  String getStringValue(String key, String defaultValue) {
    try {
      return _prefs.getString(key) ?? defaultValue;
    } catch (e) {
      _logger.error('获取设置值失败: $key', e);
      return defaultValue;
    }
  }
  
  /// 设置字符串值
  Future<bool> setStringValue(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (e) {
      _logger.error('设置值失败: $key', e);
      return false;
    }
  }
  
  /// 获取整数值
  int getIntValue(String key, int defaultValue) {
    try {
      return _prefs.getInt(key) ?? defaultValue;
    } catch (e) {
      _logger.error('获取设置值失败: $key', e);
      return defaultValue;
    }
  }
  
  /// 设置整数值
  Future<bool> setIntValue(String key, int value) async {
    try {
      return await _prefs.setInt(key, value);
    } catch (e) {
      _logger.error('设置值失败: $key', e);
      return false;
    }
  }
  
  /// 获取双精度浮点值
  double getDoubleValue(String key, double defaultValue) {
    try {
      return _prefs.getDouble(key) ?? defaultValue;
    } catch (e) {
      _logger.error('获取设置值失败: $key', e);
      return defaultValue;
    }
  }
  
  /// 设置双精度浮点值
  Future<bool> setDoubleValue(String key, double value) async {
    try {
      return await _prefs.setDouble(key, value);
    } catch (e) {
      _logger.error('设置值失败: $key', e);
      return false;
    }
  }
  
  /// 获取布尔值
  bool getBoolValue(String key, bool defaultValue) {
    try {
      return _prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      _logger.error('获取设置值失败: $key', e);
      return defaultValue;
    }
  }
  
  /// 设置布尔值
  Future<bool> setBoolValue(String key, bool value) async {
    try {
      return await _prefs.setBool(key, value);
    } catch (e) {
      _logger.error('设置值失败: $key', e);
      return false;
    }
  }
  
  /// 获取字符串列表值
  List<String> getStringListValue(String key, List<String> defaultValue) {
    try {
      return _prefs.getStringList(key) ?? defaultValue;
    } catch (e) {
      _logger.error('获取设置值失败: $key', e);
      return defaultValue;
    }
  }
  
  /// 设置字符串列表值
  Future<bool> setStringListValue(String key, List<String> value) async {
    try {
      return await _prefs.setStringList(key, value);
    } catch (e) {
      _logger.error('设置值失败: $key', e);
      return false;
    }
  }
  
  /// 检查是否包含指定键
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  /// 移除指定键的值
  Future<bool> removeKey(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e) {
      _logger.error('移除设置值失败: $key', e);
      return false;
    }
  }
  
  /// 清除所有设置
  Future<bool> clear() async {
    try {
      return await _prefs.clear();
    } catch (e) {
      _logger.error('清除所有设置失败', e);
      return false;
    }
  }
}

/// 设置服务提供者
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final logger = ref.watch(loggerServiceProvider);
  return SettingsService(prefs, logger);
}); 