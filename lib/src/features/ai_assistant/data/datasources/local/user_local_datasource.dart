import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/models/user_preference.dart';
import '../../../domain/models/user_history.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/services/logging/logging_service.dart';

/// 用户本地数据源
class UserLocalDataSource {
  final StorageService _storageService;
  final LoggingService _loggingService;
  
  /// 构造函数
  UserLocalDataSource({
    required StorageService storageService,
    required LoggingService loggingService,
  })  : _storageService = storageService,
        _loggingService = loggingService;
  
  // 2025-03-16 + 获取当前用户资料功能
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      // 获取当前用户ID
      final currentUserId = await _storageService.read<String>('current_user_id');
      if (currentUserId == null) {
        return null;
      }
      
      // 获取用户资料
      return await getUserProfile(currentUserId);
    } catch (e) {
      _loggingService.error('获取当前用户资料失败', tags: {'error': e.toString()});
      return null;
    }
  }
  
  // 2025-03-16 + 获取用户资料功能
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final data = await _storageService.read<Map<String, dynamic>>(
        'users/$userId/profile',
      );
      
      if (data == null) {
        return null;
      }
      
      return UserProfile.fromMap(data);
    } catch (e) {
      _loggingService.error('获取用户资料失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return null;
    }
  }
  
  // 2025-03-16 + 保存用户资料功能
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      // 保存用户资料
      await _storageService.write(
        'users/${profile.id}/profile',
        profile.toMap(),
      );
      
      // 如果这是第一个用户，设置为当前用户
      final currentUserId = await _storageService.read<String>('current_user_id');
      if (currentUserId == null) {
        await _storageService.write('current_user_id', profile.id);
      }
    } catch (e) {
      _loggingService.error('保存用户资料失败', tags: {
        'error': e.toString(),
        'user_id': profile.id,
      });
      rethrow;
    }
  }
  
  // 2025-03-16 + 删除用户资料功能
  Future<void> deleteUserProfile(String userId) async {
    try {
      // 删除用户资料
      await _storageService.delete('users/$userId/profile');
      
      // 如果删除的是当前用户，清除当前用户ID
      final currentUserId = await _storageService.read<String>('current_user_id');
      if (currentUserId == userId) {
        await _storageService.delete('current_user_id');
        
        // 尝试设置另一个用户为当前用户
        final userKeys = await _storageService.getKeys('users/');
        if (userKeys.isNotEmpty) {
          for (final key in userKeys) {
            final id = key.split('/')[1];
            if (id != userId) {
              await _storageService.write('current_user_id', id);
              break;
            }
          }
        }
      }
    } catch (e) {
      _loggingService.error('删除用户资料失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      rethrow;
    }
  }
  
  // 2025-03-16 + 获取用户偏好功能
  Future<UserPreference?> getUserPreferences(String userId) async {
    try {
      final data = await _storageService.read<Map<String, dynamic>>(
        'users/$userId/preferences',
      );
      
      if (data == null) {
        return null;
      }
      
      return UserPreference.fromMap(data);
    } catch (e) {
      _loggingService.error('获取用户偏好失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return null;
    }
  }
  
  // 2025-03-16 + 保存用户偏好功能
  Future<void> saveUserPreferences(String userId, UserPreference preferences) async {
    try {
      await _storageService.write(
        'users/$userId/preferences',
        preferences.toMap(),
      );
    } catch (e) {
      _loggingService.error('保存用户偏好失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      rethrow;
    }
  }
  
  // 2025-03-16 + 删除用户偏好功能
  Future<void> deleteUserPreferences(String userId) async {
    try {
      await _storageService.delete('users/$userId/preferences');
    } catch (e) {
      _loggingService.error('删除用户偏好失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      rethrow;
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
      final keys = await _storageService.getKeys('users/$userId/history/');
      final List<HistoryEntry> entries = [];
      
      for (final key in keys) {
        final data = await _storageService.read<Map<String, dynamic>>(key);
        if (data != null) {
          final entry = HistoryEntry.fromMap(data);
          
          // 应用过滤条件
          if ((startDate == null || entry.timestamp.isAfter(startDate)) &&
              (endDate == null || entry.timestamp.isBefore(endDate))) {
            entries.add(entry);
          }
        }
      }
      
      // 按时间排序，最新的在前面
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // 应用分页
      if (offset != null || limit != null) {
        final start = offset ?? 0;
        final end = limit != null ? (start + limit) : null;
        
        if (start < entries.length) {
          return entries.sublist(start, end != null && end < entries.length ? end : entries.length);
        } else {
          return [];
        }
      }
      
      return entries;
    } catch (e) {
      _loggingService.error('获取用户历史失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return [];
    }
  }
  
  // 2025-03-16 + 保存历史条目功能
  Future<void> saveHistoryEntry(String userId, HistoryEntry entry) async {
    try {
      await _storageService.write(
        'users/$userId/history/${entry.id}',
        entry.toMap(),
      );
    } catch (e) {
      _loggingService.error('保存历史条目失败', tags: {
        'error': e.toString(),
        'user_id': userId,
        'entry_id': entry.id,
      });
      rethrow;
    }
  }
  
  // 2025-03-16 + 清除用户历史功能
  Future<void> clearUserHistory(
    String userId, {
    DateTime? before,
    List<String>? categories,
  }) async {
    try {
      // 获取所有历史条目
      final entries = await getUserHistoryEntries(userId);
      
      // 筛选需要删除的条目
      for (final entry in entries) {
        bool shouldDelete = false;
        
        // 按时间筛选
        if (before != null && entry.timestamp.isBefore(before)) {
          shouldDelete = true;
        }
        
        // 按类别筛选
        if (categories != null && categories.isNotEmpty) {
          if (categories.contains(entry.category)) {
            shouldDelete = true;
          }
        }
        
        // 如果没有指定筛选条件，删除所有
        if (before == null && (categories == null || categories.isEmpty)) {
          shouldDelete = true;
        }
        
        // 删除符合条件的条目
        if (shouldDelete) {
          await _storageService.delete('users/$userId/history/${entry.id}');
        }
      }
    } catch (e) {
      _loggingService.error('清除用户历史失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      rethrow;
    }
  }
  
  // 2025-03-16 + 获取用户学习数据功能
  Future<Map<String, dynamic>> getUserLearningData(String userId) async {
    try {
      final data = await _storageService.read<Map<String, dynamic>>(
        'users/$userId/learning_data',
      );
      
      return data ?? {};
    } catch (e) {
      _loggingService.error('获取用户学习数据失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      return {};
    }
  }
  
  // 2025-03-16 + 保存用户学习数据功能
  Future<void> saveUserLearningData(String userId, Map<String, dynamic> learningData) async {
    try {
      await _storageService.write(
        'users/$userId/learning_data',
        learningData,
      );
    } catch (e) {
      _loggingService.error('保存用户学习数据失败', tags: {
        'error': e.toString(),
        'user_id': userId,
      });
      rethrow;
    }
  }
}

/// 用户本地数据源提供者
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  
  return UserLocalDataSource(
    storageService: storageService,
    loggingService: loggingService,
  );
});
