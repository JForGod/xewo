import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用配置类，管理应用级别的配置信息和初始化流程
class AppConfig {
  // 单例模式
  static final AppConfig _instance = AppConfig._internal();
  static AppConfig get instance => _instance;
  
  AppConfig._internal();
  
  // 配置信息
  late final String appVersion;
  late final bool isDevelopment;
  late final String dataDirectory;
  late final ThemeMode themeMode;
  
  // 初始化配置
  Future<void> initialize() async {
    appVersion = '1.0.0';
    isDevelopment = true;
    dataDirectory = '.';
    
    // 从SharedPreferences加载主题设置
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
    themeMode = ThemeMode.values[themeModeIndex];
  }
  
  // 获取应用版本
  String getAppVersion() => appVersion;
  
  // 判断是否为开发环境
  bool isInDevelopmentMode() => isDevelopment;
  
  // 获取数据目录
  String getDataDirectory() => dataDirectory;
  
  // 获取当前主题模式
  ThemeMode getThemeMode() => themeMode;
  
  // 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
} 