import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/services/logging/logging_service.dart';

/// 设置远程数据源
class SettingsRemoteDataSource {
  final ApiClient _apiClient;
  final LoggingService _loggingService;
  
  /// 构造函数
  SettingsRemoteDataSource({
    required ApiClient apiClient,
    required LoggingService loggingService,
  })  : _apiClient = apiClient,
        _loggingService = loggingService;
  
  // 2025-03-16 + 获取设置值功能
  Future<T?> get<T>(String key) async {
    try {
      final response = await _apiClient.get('/settings/$key');
      
      if (response.statusCode == 200) {
        return response.data as T?;
      }
      
      return null;
    } catch (e) {
      _loggingService.error('获取远程设置值失败', tags: {
        'error': e.toString(),
        'key': key,
      });
      return null;
    }
  }
  
  // 2025-03-16 + 保存设置值功能
  Future<bool> set<T>(String key, T value) async {
    try {
      final response = await _apiClient.post(
        '/settings/$key',
        data: {'value': value},
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _loggingService.error('保存远程设置值失败', tags: {
        'error': e.toString(),
        'key': key,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 移除设置功能
  Future<bool> remove(String key) async {
    try {
      final response = await _apiClient.delete('/settings/$key');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _loggingService.error('移除远程设置失败', tags: {
        'error': e.toString(),
        'key': key,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 检查设置存在功能
  Future<bool> containsKey(String key) async {
    try {
      final response = await _apiClient.head('/settings/$key');
      
      return response.statusCode == 200;
    } catch (e) {
      _loggingService.error('检查远程设置存在失败', tags: {
        'error': e.toString(),
        'key': key,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 获取所有设置功能
  Future<Map<String, dynamic>> getAll() async {
    try {
      final response = await _apiClient.get('/settings');
      
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      
      return {};
    } catch (e) {
      _loggingService.error('获取所有远程设置失败', tags: {'error': e.toString()});
      return {};
    }
  }
  
  // 2025-03-16 + 批量设置功能
  Future<bool> setAll(Map<String, dynamic> values) async {
    try {
      final response = await _apiClient.post(
        '/settings',
        data: values,
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _loggingService.error('批量保存远程设置失败', tags: {'error': e.toString()});
      return false;
    }
  }
  
  // 2025-03-16 + 清除所有设置功能
  Future<bool> clear() async {
    try {
      final response = await _apiClient.delete('/settings');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _loggingService.error('清除所有远程设置失败', tags: {'error': e.toString()});
      return false;
    }
  }
}

/// 设置远程数据源提供者
final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource?>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  
  // 检查是否配置了API端点
  final hasApiConfig = ref.watch(apiConfigProvider).hasValidConfig;
  
  if (!hasApiConfig) {
    return null;
  }
  
  return SettingsRemoteDataSource(
    apiClient: apiClient,
    loggingService: loggingService,
  );
});
