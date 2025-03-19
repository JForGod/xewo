import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/services/logging/logging_service.dart';

/// 设置本地数据源
class SettingsLocalDataSource {
  final StorageService _storageService;
  final LoggingService _loggingService;
  
  /// 构造函数
  SettingsLocalDataSource({
    required StorageService storageService,
    required LoggingService loggingService,
  })  : _storageService = storageService,
        _loggingService = loggingService;
  
  // 2025-03-16 + 获取设置值功能
  Future<T?> get<T>(String key) async {
    try {
      return await _storageService.read<T>('settings/$key');
    } catch (e) {
      _loggingService.error('获取设置值失败', tags: {
        'error': e.toString(),
        'key': key,
      });
      return null;
    }
  }
  
  // 2025-03-16 + 保存设置值功能
  Future<void> set<T>(String key, T value) async {
    try {
      await _storageService.write('settings/$key', value);
    } catch (e) {
      _loggingService.error('保存设置值失败', tags: {
        'error': e.toString(),
        'key': key,
      });
      rethrow;
    }
  }
  
  // 2025-03-16 + 移除设置功能
  Future<void> remove(String key) async {
    try {
      await _storageService.delete('settings/$key');
    } catch (e) {
      _loggingService.error('移除设置失败', tags: {
        'error': e.toString(),
        'key': key,
      });
      rethrow;
    }
  }
  
  // 2025-03-16 + 检查设置存在功能
  Future<bool> containsKey(String key) async {
    try {
      return await _storageService.exists('settings/$key');
    } catch (e) {
      _loggingService.error('检查设置存在失败', tags: {
        'error': e.toString(),
        'key': key,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 获取所有设置功能
  Future<Map<String, dynamic>> getAll() async {
    try {
      final keys = await _storageService.getKeys('settings/');
      final Map<String, dynamic> settings = {};
      
      for (final key in keys) {
        // 从完整路径中提取设置键名
        final settingKey = key.substring('settings/'.length);
        final value = await _storageService.read(key);
        
        if (value != null) {
          settings[settingKey] = value;
        }
      }
      
      return settings;
    } catch (e) {
      _loggingService.error('获取所有设置失败', tags: {'error': e.toString()});
      return {};
    }
  }
  
  // 2025-03-16 + 清除所有设置功能
  Future<void> clear() async {
    try {
      final keys = await _storageService.getKeys('settings/');
      
      for (final key in keys) {
        await _storageService.delete(key);
      }
    } catch (e) {
      _loggingService.error('清除所有设置失败', tags: {'error': e.toString()});
      rethrow;
    }
  }
}

/// 设置本地数据源提供者
final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  
  return SettingsLocalDataSource(
    storageService: storageService,
    loggingService: loggingService,
  );
});
