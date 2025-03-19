import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_preference.dart';
import '../../domain/models/user_history.dart';
import '../datasources/local/user_local_datasource.dart';
import '../datasources/remote/user_remote_datasource.dart';
import '../../../../core/services/logging/logging_service.dart';
import '../../../../core/services/error/error_handling_service.dart';
import '../../../../core/services/security/security_service.dart';

/// 用户仓库实现
class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _localDataSource;
  final UserRemoteDataSource? _remoteDataSource;
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  final SecurityService _securityService;
  
  /// 当前用户缓存
  UserProfile? _currentUser;
  
  /// 用户偏好缓存
  UserPreference? _preferences;
  
  /// 构造函数
  UserRepositoryImpl({
    required UserLocalDataSource localDataSource,
    UserRemoteDataSource? remoteDataSource,
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    required SecurityService securityService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _securityService = securityService {
    _initializeRepository();
  }
  
  // 2025-03-16 + 初始化仓库功能
  Future<void> _initializeRepository() async {
    try {
      // 加载当前用户数据
      _currentUser = await _localDataSource.getCurrentUserProfile();
      
      // 加载用户偏好
      if (_currentUser != null) {
        _preferences = await _localDataSource.getUserPreferences(_currentUser!.id);
      }
    } catch (e) {
      _loggingService.error('初始化用户仓库失败', tags: {'error': e.toString()});
    }
  }
  
  @override
  // 2025-03-16 + 获取用户资料功能
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      // 如果已有缓存，直接返回
      if (_currentUser != null) {
        return _currentUser;
      }
      
      // 从本地获取
      final localProfile = await _localDataSource.getCurrentUserProfile();
      
      // 如果本地没有且远程数据源可用，尝试从远程获取
      if (localProfile == null && _remoteDataSource != null) {
        try {
          final remoteProfile = await _remoteDataSource!.getCurrentUserProfile();
          
          // 如果远程有，保存到本地
          if (remoteProfile != null) {
            await _localDataSource.saveUserProfile(remoteProfile);
            _currentUser = remoteProfile;
            return remoteProfile;
          }
        } catch (e) {
          _loggingService.warning('获取远程用户资料失败', tags: {'error': e.toString()});
        }
      }
      
      _currentUser = localProfile;
      return localProfile;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '获取用户资料失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 更新用户资料功能
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      // 保存到本地
      await _localDataSource.saveUserProfile(profile);
      
      // 更新缓存
      _currentUser = profile;
      
      // 如果远程数据源可用，也保存到远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.saveUserProfile(profile);
        } catch (e) {
          _loggingService.warning('更新远程用户资料失败', tags: {'error': e.toString()});
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '更新用户资料失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 获取用户偏好功能
  Future<UserPreference> getUserPreferences() async {
    try {
      // 必须有当前用户
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('没有当前用户');
      }
      
      // 如果已有缓存，直接返回
      if (_preferences != null) {
        return _preferences!;
      }
      
      // 从本地获取
      final localPreferences = await _localDataSource.getUserPreferences(currentUser.id);
      
      // 如果本地没有且远程数据源可用，尝试从远程获取
      if (localPreferences == null && _remoteDataSource != null) {
        try {
          final remotePreferences = await _remoteDataSource!.getUserPreferences(currentUser.id);
          
          // 如果远程有，保存到本地
          if (remotePreferences != null) {
            await _localDataSource.saveUserPreferences(currentUser.id, remotePreferences);
            _preferences = remotePreferences;
            return remotePreferences;
          }
        } catch (e) {
          _loggingService.warning('获取远程用户偏好失败', tags: {'error': e.toString()});
        }
      }
      
      // 如果还是没有，创建默认偏好
      if (localPreferences == null) {
        final defaultPreferences = UserPreference(
          userId: currentUser.id,
          theme: 'system',
          language: 'auto',
          notifications: true,
          soundEffects: true,
          appearance: {
            'darkMode': false,
            'fontSize': 'medium',
            'fontFamily': 'default',
          },
          security: {
            'biometricLogin': false,
            'autoLock': false,
            'autoLockTimeout': 5,
          },
          created: DateTime.now(),
          updated: DateTime.now(),
        );
        
        await _localDataSource.saveUserPreferences(currentUser.id, defaultPreferences);
        _preferences = defaultPreferences;
        return defaultPreferences;
      }
      
      _preferences = localPreferences;
      return localPreferences;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '获取用户偏好失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 更新用户偏好功能
  Future<void> updateUserPreferences(UserPreference preferences) async {
    try {
      // 必须有当前用户
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('没有当前用户');
      }
      
      // 保存到本地
      await _localDataSource.saveUserPreferences(
        currentUser.id,
        preferences.copyWith(updated: DateTime.now()),
      );
      
      // 更新缓存
      _preferences = preferences;
      
      // 如果远程数据源可用，也保存到远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.saveUserPreferences(currentUser.id, preferences);
        } catch (e) {
          _loggingService.warning('更新远程用户偏好失败', tags: {'error': e.toString()});
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '更新用户偏好失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 获取用户历史功能
  Future<UserHistory> getUserHistory({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // 必须有当前用户
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('没有当前用户');
      }
      
      // 从本地获取历史记录
      final localEntries = await _localDataSource.getUserHistoryEntries(
        currentUser.id,
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      );
      
      // 如果远程数据源可用且本地记录较少，尝试从远程获取
      if (_remoteDataSource != null && 
          (localEntries.isEmpty || (limit != null && localEntries.length < limit))) {
        try {
          final remoteEntries = await _remoteDataSource!.getUserHistoryEntries(
            currentUser.id,
            limit: limit,
            offset: offset,
            startDate: startDate,
            endDate: endDate,
          );
          
          // 保存远程记录到本地
          for (final entry in remoteEntries) {
            if (!localEntries.any((e) => e.id == entry.id)) {
              await _localDataSource.saveHistoryEntry(currentUser.id, entry);
            }
          }
          
          // 重新获取本地记录
          final updatedEntries = await _localDataSource.getUserHistoryEntries(
            currentUser.id,
            limit: limit,
            offset: offset,
            startDate: startDate,
            endDate: endDate,
          );
          
          return UserHistory(
            userId: currentUser.id,
            entries: updatedEntries,
          );
        } catch (e) {
          _loggingService.warning('获取远程历史记录失败', tags: {'error': e.toString()});
          // 如果远程获取失败，仍返回本地数据
        }
      }
      
      return UserHistory(
        userId: currentUser.id,
        entries: localEntries,
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '获取用户历史失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 清除用户历史功能
  Future<void> clearUserHistory({
    DateTime? before,
    List<String>? categories,
  }) async {
    try {
      // 必须有当前用户
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('没有当前用户');
      }
      
      // 清除本地历史记录
      await _localDataSource.clearUserHistory(
        currentUser.id,
        before: before,
        categories: categories,
      );
      
      // 如果远程数据源可用，也清除远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.clearUserHistory(
            currentUser.id,
            before: before,
            categories: categories,
          );
        } catch (e) {
          _loggingService.warning('清除远程历史记录失败', tags: {'error': e.toString()});
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '清除用户历史失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 添加历史条目功能
  Future<void> addHistoryEntry(HistoryEntry entry) async {
    try {
      // 必须有当前用户
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('没有当前用户');
      }
      
      // 保存到本地
      await _localDataSource.saveHistoryEntry(currentUser.id, entry);
      
      // 如果远程数据源可用，也保存到远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.saveHistoryEntry(currentUser.id, entry);
        } catch (e) {
          _loggingService.warning('保存历史条目到远程失败', tags: {'error': e.toString()});
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '添加历史条目失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 创建用户功能
  Future<UserProfile> createUser(UserProfile profile, String password) async {
    try {
      // 哈希密码
      final hashedPassword = await _securityService.hashPassword(password);
      
      // 创建用户对象
      final user = profile.copyWith(
        passwordHash: hashedPassword,
        created: DateTime.now(),
        updated: DateTime.now(),
      );
      
      // 保存到本地
      await _localDataSource.saveUserProfile(user);
      
      // 更新缓存
      _currentUser = user;
      
      // 创建默认偏好
      final defaultPreferences = UserPreference(
        userId: user.id,
        theme: 'system',
        language: 'auto',
        notifications: true,
        soundEffects: true,
        appearance: {
          'darkMode': false,
          'fontSize': 'medium',
          'fontFamily': 'default',
        },
        security: {
          'biometricLogin': false,
          'autoLock': false,
          'autoLockTimeout': 5,
        },
        created: DateTime.now(),
        updated: DateTime.now(),
      );
      
      await _localDataSource.saveUserPreferences(user.id, defaultPreferences);
      
      // 如果远程数据源可用，也保存到远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.saveUserProfile(user);
          await _remoteDataSource!.saveUserPreferences(user.id, defaultPreferences);
        } catch (e) {
          _loggingService.warning('创建远程用户失败', tags: {'error': e.toString()});
        }
      }
      
      return user;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.high,
        message: '创建用户失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 删除用户功能
  Future<void> deleteUser(String userId) async {
    try {
      // 检查权限
      final hasPermission = await checkUserPermission(userId, 'delete_user');
      if (!hasPermission) {
        throw Exception('没有删除用户的权限');
      }
      
      // 删除本地用户数据
      await _localDataSource.deleteUserProfile(userId);
      await _localDataSource.deleteUserPreferences(userId);
      await _localDataSource.clearUserHistory(userId);
      
      // 如果是当前用户，清除缓存
      if (_currentUser?.id == userId) {
        _currentUser = null;
        _preferences = null;
      }
      
      // 如果远程数据源可用，也删除远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.deleteUserProfile(userId);
        } catch (e) {
          _loggingService.warning('删除远程用户失败', tags: {'error': e.toString()});
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.high,
        message: '删除用户失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 获取学习数据功能
  Future<Map<String, dynamic>> getUserLearningData() async {
    try {
      // 必须有当前用户
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('没有当前用户');
      }
      
      // 从本地获取学习数据
      final localData = await _localDataSource.getUserLearningData(currentUser.id);
      
      // 如果本地没有且远程数据源可用，尝试从远程获取
      if (localData.isEmpty && _remoteDataSource != null) {
        try {
          final remoteData = await _remoteDataSource!.getUserLearningData(currentUser.id);
          
          // 如果远程有，保存到本地
          if (remoteData.isNotEmpty) {
            await _localDataSource.saveUserLearningData(currentUser.id, remoteData);
            return remoteData;
          }
        } catch (e) {
          _loggingService.warning('获取远程学习数据失败', tags: {'error': e.toString()});
        }
      }
      
      return localData;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '获取用户学习数据失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 更新学习数据功能
  Future<void> updateUserLearningData(Map<String, dynamic> learningData) async {
    try {
      // 必须有当前用户
      final currentUser = await getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('没有当前用户');
      }
      
      // 保存到本地
      await _localDataSource.saveUserLearningData(currentUser.id, learningData);
      
      // 如果远程数据源可用，也保存到远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.saveUserLearningData(currentUser.id, learningData);
        } catch (e) {
          _loggingService.warning('更新远程学习数据失败', tags: {'error': e.toString()});
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '更新用户学习数据失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 设置用户权限功能
  Future<void> setUserPermissions(String userId, List<String> permissions) async {
    try {
      // 检查是否有设置权限的权限
      final hasPermission = await checkUserPermission(userId, 'manage_permissions');
      if (!hasPermission) {
        throw Exception('没有管理权限的权限');
      }
      
      // 获取用户资料
      final profile = await _localDataSource.getUserProfile(userId);
      if (profile == null) {
        throw Exception('用户不存在');
      }
      
      // 更新权限
      final updatedProfile = profile.copyWith(
        permissions: permissions,
        updated: DateTime.now(),
      );
      
      // 保存到本地
      await _localDataSource.saveUserProfile(updatedProfile);
      
      // 如果是当前用户，更新缓存
      if (_currentUser?.id == userId) {
        _currentUser = updatedProfile;
      }
      
      // 如果远程数据源可用，也保存到远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.saveUserProfile(updatedProfile);
        } catch (e) {
          _loggingService.warning('更新远程用户权限失败', tags: {'error': e.toString()});
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.high,
        message: '设置用户权限失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 检查用户权限功能
  Future<bool> checkUserPermission(String userId, String permission) async {
    try {
      // 获取用户资料
      UserProfile? profile;
      
      // 如果是当前用户，使用缓存
      if (_currentUser?.id == userId) {
        profile = _currentUser;
      } else {
        profile = await _localDataSource.getUserProfile(userId);
      }
      
      if (profile == null) {
        return false;
      }
      
      // 检查是否有该权限
      return profile.permissions.contains(permission) || 
             profile.permissions.contains('admin');  // admin有所有权限
    } catch (e) {
      _loggingService.error('检查用户权限失败', tags: {
        'error': e.toString(),
        'user_id': userId,
        'permission': permission,
      });
      return false;
    }
  }
}

/// 用户仓库提供者
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final localDataSource = ref.watch(userLocalDataSourceProvider);
  final remoteDataSource = ref.watch(userRemoteDataSourceProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  final securityService = ref.watch(securityServiceProvider);
  
  return UserRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
    securityService: securityService,
  );
});
