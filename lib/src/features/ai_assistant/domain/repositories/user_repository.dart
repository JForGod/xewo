import '../models/user_profile.dart';
import '../models/user_preference.dart';
import '../models/user_history.dart';

/// 用户仓库接口
abstract class UserRepository {
  /// 获取当前用户资料
  // 2025-03-16 + 获取用户资料功能
  Future<UserProfile?> getCurrentUserProfile();
  
  /// 更新用户资料
  // 2025-03-16 + 更新用户资料功能
  Future<void> updateUserProfile(UserProfile profile);
  
  /// 获取用户偏好设置
  // 2025-03-16 + 获取用户偏好功能
  Future<UserPreference> getUserPreferences();
  
  /// 更新用户偏好设置
  // 2025-03-16 + 更新用户偏好功能
  Future<void> updateUserPreferences(UserPreference preferences);
  
  /// 获取用户历史记录
  // 2025-03-16 + 获取用户历史功能
  Future<UserHistory> getUserHistory({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// 清除用户历史记录
  // 2025-03-16 + 清除用户历史功能
  Future<void> clearUserHistory({
    DateTime? before,
    List<String>? categories,
  });
  
  /// 添加用户历史条目
  // 2025-03-16 + 添加历史条目功能
  Future<void> addHistoryEntry(HistoryEntry entry);
  
  /// 创建新用户
  // 2025-03-16 + 创建用户功能
  Future<UserProfile> createUser(UserProfile profile, String password);
  
  /// 删除用户
  // 2025-03-16 + 删除用户功能
  Future<void> deleteUser(String userId);
  
  /// 获取用户学习数据
  // 2025-03-16 + 获取学习数据功能
  Future<Map<String, dynamic>> getUserLearningData();
  
  /// 更新用户学习数据
  // 2025-03-16 + 更新学习数据功能
  Future<void> updateUserLearningData(Map<String, dynamic> learningData);
  
  /// 设置用户权限
  // 2025-03-16 + 设置用户权限功能
  Future<void> setUserPermissions(String userId, List<String> permissions);
  
  /// 检查用户权限
  // 2025-03-16 + 检查用户权限功能
  Future<bool> checkUserPermission(String userId, String permission);
}
