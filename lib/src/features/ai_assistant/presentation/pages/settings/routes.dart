// 2025-03-22: 新增 - 创建设置页面路由定义文件

import 'package:flutter/material.dart';
import 'multimodal_settings_page.dart';

/// 设置页面路由
class SettingsRoutes {
  /// 多模态设置页面路由
  static const String multimodalSettings = '/multimodal-settings';
  
  /// 获取设置页面路由
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      multimodalSettings: (context) => const MultimodalSettingsPage(),
    };
  }
  
  /// 导航到多模态设置页面
  static Future<void> navigateToMultimodalSettings(BuildContext context) async {
    await Navigator.of(context).pushNamed(multimodalSettings);
  }
} 