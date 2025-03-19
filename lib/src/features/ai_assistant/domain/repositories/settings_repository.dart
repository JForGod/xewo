/// 设置仓库接口
abstract class SettingsRepository {
  /// 获取设置值
  // 2025-03-16 + 获取设置值功能
  Future<T?> get<T>(String key, {T? defaultValue});
  
  /// 保存设置值
  // 2025-03-16 + 保存设置值功能
  Future<void> set<T>(String key, T value);
  
  /// 移除设置
  // 2025-03-16 + 移除设置功能
  Future<void> remove(String key);
  
  /// 检查设置是否存在
  // 2025-03-16 + 检查设置存在功能
  Future<bool> containsKey(String key);
  
  /// 获取所有设置
  // 2025-03-16 + 获取所有设置功能
  Future<Map<String, dynamic>> getAll();
  
  /// 批量设置多个值
  // 2025-03-16 + 批量设置功能
  Future<void> setAll(Map<String, dynamic> values);
  
  /// 清除所有设置
  // 2025-03-16 + 清除所有设置功能
  Future<void> clear();
  
  /// 获取特定类别的设置
  // 2025-03-16 + 获取类别设置功能
  Future<Map<String, dynamic>> getCategory(String category);
  
  /// 导出设置
  // 2025-03-16 + 导出设置功能
  Future<String> exportSettings();
  
  /// 导入设置
  // 2025-03-16 + 导入设置功能
  Future<void> importSettings(String data);
  
  /// 恢复默认设置
  // 2025-03-16 + 恢复默认设置功能
  Future<void> restoreDefaults({List<String>? keys});
  
  /// 监听设置变化
  // 2025-03-16 + 监听设置变化功能
  Stream<SettingsChange> watchSettings({List<String>? keys});
}

/// 设置变化模型
class SettingsChange {
  /// 设置键
  final String key;
  
  /// 旧值
  final dynamic oldValue;
  
  /// 新值
  final dynamic newValue;
  
  /// 变化时间
  final DateTime timestamp;
  
  /// 构造函数
  SettingsChange({
    required this.key,
    this.oldValue,
    this.newValue,
    required this.timestamp,
  });
}
