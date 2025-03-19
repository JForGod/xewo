import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/models/user_preference.dart';
import '../../../domain/models/user_history.dart';
import '../../../../core/services/network/api_client.dart';
import '../../../../core/services/logging/logging_service.dart';

/// 用户远程数据源
class UserRemoteDataSource {
  final ApiClient _apiClient;
  final LoggingService _loggingService;
  
  /// 构造函数
  UserRemoteDataSource({
    required ApiClient apiClient,
    required LoggingService loggingService,
  })  : _apiClient = apiClient,
        _loggingService = loggingService;
  
  // 2025-03-16 + 获取当前用户资料功能
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final response = await _apiClient.get('/user/profile');
      
      if (response.statusCode == 200) {
        return UserProfile.fromMap(response.data);
      }
      
      return null;
    } catch (e) {
      _loggingService.error('获取远程当前用户资料失败', tags: {'error': e.toString()});
      return null;
    }
  }
  
  // 2025-03-16 + 获取用户资料功能
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _apiClient.get('/users/$userId/profile');
      
      if (response.statusCode == 200) {
        return UserProfile.fromMap(response.data);
      }
      
      return null;
    } catch (e) {
      _loggingService.error('获取远程用户资料失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return null;
    }
  }
  
  // 2025-03-16 + 保存用户资料功能
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final response = await _apiClient.post(
        '/users/${profile.id}/profile',
        data: profile.toMap(),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _loggingService.error('保存远程用户资料失败', tags: {
        'error': e.toString(),
        'user_id': profile.id,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 删除用户资料功能
  Future<bool> deleteUserProfile(String userId) async {
    try {
      final response = await _apiClient.delete('/users/$userId/profile');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _loggingService.error('删除远程用户资料失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 获取用户偏好功能
  Future<UserPreference?> getUserPreferences(String userId) async {
    try {
      final response = await _apiClient.get('/users/$userId/preferences');
      
      if (response.statusCode == 200) {
        return UserPreference.fromMap(response.data);
      }
      
      return null;
    } catch (e) {
      _loggingService.error('获取远程用户偏好失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return null;
    }
  }
  
  // 2025-03-16 + 保存用户偏好功能
  Future<bool> saveUserPreferences(String userId, UserPreference preferences) async {
    try {
      final response = await _apiClient.post(
        '/users/$userId/preferences',
        data: preferences.toMap(),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _loggingService.error('保存远程用户偏好失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 获取用户历史条目功能
  Future<List<HistoryEntry>> getUserHistoryEntries(
    String userId, {
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      
      final response = await _apiClient.get(
        '/users/$userId/history',
        queryParams: queryParams,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> entriesData = response.data;
        return entriesData
            .map((data) => HistoryEntry.fromMap(data))
            .toList();
      }
      
      return [];
    } catch (e) {
      _loggingService.error('获取远程用户历史条目失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return [];
    }
  }
  
  // 2025-03-16 + 保存历史条目功能
  Future<bool> saveHistoryEntry(String userId, HistoryEntry entry) async {
    try {
      final response = await _apiClient.post(
        '/users/$userId/history',
        data: entry.toMap(),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _loggingService.error('保存远程历史条目失败', tags: {
        'error': e.toString(),
        'user_id': userId,
        'entry_id': entry.id,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 清除用户历史功能
  Future<bool> clearUserHistory(
    String userId, {
    DateTime? before,
    List<String>? categories,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (before != null) queryParams['before'] = before.toIso8601String();
      if (categories != null) queryParams['categories'] = categories.join(',');
      
      final response = await _apiClient.delete(
        '/users/$userId/history',
        queryParams: queryParams,
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _loggingService.error('清除远程用户历史失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return false;
    }
  }
  
  // 2025-03-16 + 获取用户学习数据功能
  Future<Map<String, dynamic>> getUserLearningData(String userId) async {
    try {
      final response = await _apiClient.get('/users/$userId/learning_data');
      
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      
      return {};
    } catch (e) {
      _loggingService.error('获取远程用户学习数据失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return {};
    }
  }
  
  // 2025-03-16 + 保存用户学习数据功能
  Future<bool> saveUserLearningData(String userId, Map<String, dynamic> learningData) async {
    try {
      final response = await _apiClient.post(
        '/users/$userId/learning_data',
        data: learningData,
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _loggingService.error('保存远程用户学习数据失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return false;
    }
  }
}

/// 用户远程数据源提供者
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource?>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  
  // 检查是否配置了API端点
  final hasApiConfig = ref.watch(apiConfigProvider).hasValidConfig;
  
  if (!hasApiConfig) {
    return null;
  }
  
  return UserRemoteDataSource(
    apiClient: apiClient,
    loggingService: loggingService,
  );
});
