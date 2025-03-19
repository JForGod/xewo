import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/settings_local_datasource.dart';
import '../datasources/remote/settings_remote_datasource.dart';
import '../../../../core/services/logging/logging_service.dart';
import '../../../../core/services/error/error_handling_service.dart';

/// 设置仓库实现
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;
  final SettingsRemoteDataSource? _remoteDataSource;
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  
  /// 设置缓存
  final Map<String, dynamic> _settingsCache = {};
  
  /// 设置变更流控制器
  final StreamController<SettingsChange> _changeController = 
      StreamController<SettingsChange>.broadcast();
  
  /// 设置变更监听器
  final Map<String, List<StreamSubscription>> _watcherSubscriptions = {};
  
  /// 构造函数
  SettingsRepositoryImpl({
    required SettingsLocalDataSource localDataSource,
    SettingsRemoteDataSource? remoteDataSource,
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _loggingService = loggingService,
        _errorHandlingService = errorHandlingService {
    _initializeRepository();
  }
  
  // 2025-03-16 + 初始化仓库功能
  Future<void> _initializeRepository() async {
    try {
      // 从本地加载所有设置
      final localSettings = await _localDataSource.getAll();
      _settingsCache.addAll(localSettings);
      
      // 如果远程数据源可用，尝试同步
      if (_remoteDataSource != null) {
        _syncWithRemote();
      }
    } catch (e) {
      _loggingService.error('初始化设置仓库失败', tags: {'error': e.toString()});
    }
  }
  
  // 2025-03-16 + 与远程同步功能
  Future<void> _syncWithRemote() async {
    try {
      // 获取远程设置
      final remoteSettings = await _remoteDataSource!.getAll();
      
      // 比较和合并设置
      for (final entry in remoteSettings.entries) {
        final key = entry.key;
        final remoteValue = entry.value;
        
        // 如果本地没有或远程更新，则更新本地
        if (!_settingsCache.containsKey(key) || 
            _settingsCache[key] != remoteValue) {
          await _localDataSource.set(key, remoteValue);
          
          // 发送变更通知
          _notifyChange(
            key, 
            _settingsCache[key],
            remoteValue,
          );
          
          // 更新缓存
          _settingsCache[key] = remoteValue;
        }
      }
    } catch (e) {
      _loggingService.warning('同步远程设置失败', tags: {'error': e.toString()});
    }
  }
  
  @override
  // 2025-03-16 + 获取设置值功能
  Future<T?> get<T>(String key, {T? defaultValue}) async {
    try {
      // 先从缓存获取
      if (_settingsCache.containsKey(key)) {
        final value = _settingsCache[key];
        if (value is T) {
          return value;
        }
      }
      
      // 从本地获取
      final value = await _localDataSource.get(key);
      
      // 如果本地没有且远程数据源可用，尝试从远程获取
      if (value == null && _remoteDataSource != null) {
        try {
          final remoteValue = await _remoteDataSource!.get(key);
          
          // 如果远程有，保存到本地和缓存
          if (remoteValue != null) {
            await _localDataSource.set(key, remoteValue);
            _settingsCache[key] = remoteValue;
            
            if (remoteValue is T) {
              return remoteValue;
            }
          }
        } catch (e) {
          _loggingService.warning('获取远程设置失败', tags: {
            'error': e.toString(),
            'key': key,
          });
        }
      } else if (value != null) {
        // 更新缓存
        _settingsCache[key] = value;
        
        if (value is T) {
          return value;
        }
      }
      
      // 返回默认值
      return defaultValue;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.low,
        message: '获取设置值失败',
      );
      return defaultValue;
    }
  }
  
  @override
  // 2025-03-16 + 保存设置值功能
  Future<void> set<T>(String key, T value) async {
    try {
      // 获取旧值用于通知变更
      final oldValue = _settingsCache[key];
      
      // 保存到本地
      await _localDataSource.set(key, value);
      
      // 更新缓存
      _settingsCache[key] = value;
      
      // 发送变更通知
      _notifyChange(key, oldValue, value);
      
      // 如果远程数据源可用，也保存到远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.set(key, value);
        } catch (e) {
          _loggingService.warning('保存设置到远程失败', tags: {
            'error': e.toString(),
            'key': key,
          });
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '保存设置值失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 移除设置功能
  Future<void> remove(String key) async {
    try {
      // 获取旧值用于通知变更
      final oldValue = _settingsCache[key];
      
      // 从本地移除
      await _localDataSource.remove(key);
      
      // 发送变更通知
      _notifyChange(key, oldValue, null);
      
      // 从缓存移除
      _settingsCache.remove(key);
      
      // 如果远程数据源可用，也移除远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.remove(key);
        } catch (e) {
          _loggingService.warning('移除远程设置失败', tags: {
            'error': e.toString(),
            'key': key,
          });
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '移除设置失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 检查设置存在功能
  Future<bool> containsKey(String key) async {
    try {
      // 先检查缓存
      if (_settingsCache.containsKey(key)) {
        return true;
      }
      
      // 检查本地存储
      final exists = await _localDataSource.containsKey(key);
      
      // 如果本地没有且远程数据源可用，检查远程
      if (!exists && _remoteDataSource != null) {
        try {
          return await _remoteDataSource!.containsKey(key);
        } catch (e) {
          _loggingService.warning('检查远程设置失败', tags: {
            'error': e.toString(),
            'key': key,
          });
        }
      }
      
      return exists;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.low,
        message: '检查设置存在失败',
      );
      return false;
    }
  }
  
  @override
  // 2025-03-16 + 获取所有设置功能
  Future<Map<String, dynamic>> getAll() async {
    try {
      // 如果缓存有数据，直接返回
      if (_settingsCache.isNotEmpty) {
        return Map<String, dynamic>.from(_settingsCache);
      }
      
      // 从本地获取
      final localSettings = await _localDataSource.getAll();
      
      // 如果远程数据源可用，尝试同步
      if (_remoteDataSource != null) {
        try {
          await _syncWithRemote();
          
          // 同步后返回更新的缓存
          return Map<String, dynamic>.from(_settingsCache);
        } catch (e) {
          _loggingService.warning('获取远程设置失败', tags: {'error': e.toString()});
          // 如果远程同步失败，仍返回本地数据
        }
      }
      
      // 更新缓存
      _settingsCache.addAll(localSettings);
      return localSettings;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '获取所有设置失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 批量设置功能
  Future<void> setAll(Map<String, dynamic> values) async {
    try {
      for (final entry in values.entries) {
        // 获取旧值用于通知变更
        final oldValue = _settingsCache[entry.key];
        
        // 保存到本地
        await _localDataSource.set(entry.key, entry.value);
        
        // 更新缓存
        _settingsCache[entry.key] = entry.value;
        
        // 发送变更通知
        _notifyChange(entry.key, oldValue, entry.value);
      }
      
      // 如果远程数据源可用，也保存到远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.setAll(values);
        } catch (e) {
          _loggingService.warning('批量保存设置到远程失败', tags: {'error': e.toString()});
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '批量设置值失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 清除所有设置功能
  Future<void> clear() async {
    try {
      // 获取所有键用于通知变更
      final keys = _settingsCache.keys.toList();
      final oldValues = Map<String, dynamic>.from(_settingsCache);
      
      // 清除本地数据
      await _localDataSource.clear();
      
      // 清除缓存
      _settingsCache.clear();
      
      // 发送所有键的变更通知
      for (final key in keys) {
        _notifyChange(key, oldValues[key], null);
      }
      
      // 如果远程数据源可用，也清除远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.clear();
        } catch (e) {
          _loggingService.warning('清除远程设置失败', tags: {'error': e.toString()});
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.high,
        message: '清除所有设置失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 获取类别设置功能
  Future<Map<String, dynamic>> getCategory(String category) async {
    try {
      // 获取所有设置
      final allSettings = await getAll();
      
      // 筛选指定类别的设置
      final categorySettings = <String, dynamic>{};
      final prefix = '$category.';
      
      for (final entry in allSettings.entries) {
        if (entry.key.startsWith(prefix)) {
          // 去掉前缀，只保留类别内的键名
          final subKey = entry.key.substring(prefix.length);
          categorySettings[subKey] = entry.value;
        }
      }
      
      return categorySettings;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '获取类别设置失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 导出设置功能
  Future<String> exportSettings() async {
    try {
      // 获取所有设置
      final allSettings = await getAll();
      
      // 转换为JSON字符串
      return jsonEncode(allSettings);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '导出设置失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 导入设置功能
  Future<void> importSettings(String data) async {
    try {
      // 解析JSON字符串
      final Map<String, dynamic> settings = jsonDecode(data);
      
      // 批量设置
      await setAll(settings);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.high,
        message: '导入设置失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 恢复默认设置功能
  Future<void> restoreDefaults({List<String>? keys}) async {
    try {
      // 获取默认设置
      final defaults = await _getDefaultSettings();
      
      if (keys != null) {
        // 只恢复指定的键
        final settingsToRestore = <String, dynamic>{};
        for (final key in keys) {
          if (defaults.containsKey(key)) {
            settingsToRestore[key] = defaults[key];
          }
        }
        
        // 批量设置
        await setAll(settingsToRestore);
      } else {
        // 恢复所有默认设置
        await setAll(defaults);
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.high,
        message: '恢复默认设置失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 监听设置变化功能
  Stream<SettingsChange> watchSettings({List<String>? keys}) {
    // 创建过滤流
    final streamId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 如果没有指定键，返回所有变更
    if (keys == null || keys.isEmpty) {
      return _changeController.stream;
    }
    
    // 创建过滤器，只关注指定的键
    final controller = StreamController<SettingsChange>.broadcast();
    final subscription = _changeController.stream.listen((change) {
      if (keys.contains(change.key)) {
        controller.add(change);
      }
    });
    
    // 保存订阅以便稍后清理
    _watcherSubscriptions[streamId] = [subscription];
    
    // 当流关闭时清理资源
    controller.onCancel = () {
      subscription.cancel();
      _watcherSubscriptions.remove(streamId);
    };
    
    return controller.stream;
  }
  
  // 2025-03-16 + 通知设置变化功能
  void _notifyChange(String key, dynamic oldValue, dynamic newValue) {
    if (oldValue != newValue) {
      final change = SettingsChange(
        key: key,
        oldValue: oldValue,
        newValue: newValue,
        timestamp: DateTime.now(),
      );
      
      _changeController.add(change);
    }
  }
  
  // 2025-03-16 + 获取默认设置功能
  Future<Map<String, dynamic>> _getDefaultSettings() async {
    // 默认设置
    return {
      'appearance.theme': 'system',
      'appearance.darkMode': false,
      'appearance.fontSize': 'medium',
      'appearance.fontFamily': 'default',
      'appearance.accentColor': '#3498db',
      
      'language.current': 'auto',
      'language.translation': true,
      
      'notifications.enabled': true,
      'notifications.sound': true,
      'notifications.vibration': true,
      
      'security.biometricLogin': false,
      'security.autoLock': false,
      'security.autoLockTimeout': 5,
      
      'assistant.mode': 'standard',
      'assistant.voiceControl': true,
      'assistant.gestureControl': true,
      'assistant.autoActivate': false,
      
      'privacy.dataSaving': false,
      'privacy.analytics': true,
      'privacy.personalization': true,
    };
  }
  
  // 2025-03-16 + 释放资源功能
  Future<void> dispose() async {
    // 取消所有设置监听
    for (final subscriptions in _watcherSubscriptions.values) {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }
    
    _watcherSubscriptions.clear();
    
    // 关闭流控制器
    await _changeController.close();
  }
}

/// 设置仓库提供者
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final localDataSource = ref.watch(settingsLocalDataSourceProvider);
  final remoteDataSource = ref.watch(settingsRemoteDataSourceProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final repository = SettingsRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    if (repository is SettingsRepositoryImpl) {
      repository.dispose();
    }
  });
  
  return repository;
});
