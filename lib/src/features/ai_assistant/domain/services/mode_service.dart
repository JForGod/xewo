import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/logging/logging_service.dart';
import '../../../../core/services/error/error_handling_service.dart';
import '../../../../core/services/config/config_management_service.dart';
import '../models/assistant_mode.dart';
import '../models/mode_settings.dart';
import '../models/mode_state.dart';

/// 模式服务接口
abstract class ModeService {
  /// 获取模式状态流
  Stream<ModeState> get stateStream;
  
  /// 获取当前模式
  Future<AssistantMode> getCurrentMode();
  
  /// 切换模式
  // 2025-03-15 + 切换助手模式功能
  Future<void> switchMode(AssistantMode mode);
  
  /// 获取模式设置
  // 2025-03-15 + 获取模式设置功能
  Future<ModeSettings> getModeSettings(AssistantMode mode);
  
  /// 更新模式设置
  // 2025-03-15 + 更新模式设置功能
  Future<void> updateModeSettings(AssistantMode mode, ModeSettings settings);
  
  /// 检查模式权限
  // 2025-03-15 + 检查模式权限功能
  Future<bool> checkModePermission(AssistantMode mode, String permission);
}

/// 模式服务实现
class ModeServiceImpl implements ModeService {
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  final ConfigManagementService _configService;
  
  /// 模式状态控制器
  final StreamController<ModeState> _stateController = 
      StreamController<ModeState>.broadcast();
  
  /// 当前模式状态
  ModeState _currentState = ModeState(
    currentMode: AssistantMode.standard,
    lastMode: null,
    switchTime: DateTime.now(),
    modeSettings: {},
  );
  
  /// 模式设置缓存
  final Map<AssistantMode, ModeSettings> _modeSettingsCache = {};
  
  /// 模式权限配置
  final Map<AssistantMode, Set<String>> _modePermissions = {
    AssistantMode.guardian: {
      'basic_chat',
      'voice_control',
      'safety_monitoring',
      'learning_guidance',
    },
    AssistantMode.standard: {
      'basic_chat',
      'voice_control',
      'gesture_control',
      'basic_code_assist',
      'learning_tools',
      'file_access',
    },
    AssistantMode.pro: {
      'basic_chat',
      'voice_control',
      'gesture_control',
      'advanced_code_assist',
      'system_integration',
      'custom_extensions',
      'experimental_features',
      'full_file_access',
      'network_access',
    },
  };
  
  /// 构造函数
  ModeServiceImpl({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    required ConfigManagementService configService,
  }) : _loggingService = loggingService,
       _errorHandlingService = errorHandlingService,
       _configService = configService {
    _initializeService();
  }
  
  // 2025-03-15 + 初始化服务功能
  Future<void> _initializeService() async {
    try {
      // 加载持久化的模式设置
      for (final mode in AssistantMode.values) {
        final settings = await _loadModeSettings(mode);
        _modeSettingsCache[mode] = settings;
      }
      
      // 加载上次的模式
      final lastMode = await _loadLastMode();
      if (lastMode != null) {
        await switchMode(lastMode);
      }
      
      _updateState();
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.high,
        message: '初始化模式服务失败',
      );
    }
  }
  
  @override
  Stream<ModeState> get stateStream => _stateController.stream;
  
  @override
  // 2025-03-15 + 获取当前模式功能
  Future<AssistantMode> getCurrentMode() async {
    return _currentState.currentMode;
  }
  
  @override
  // 2025-03-15 + 切换助手模式功能
  Future<void> switchMode(AssistantMode mode) async {
    try {
      _loggingService.info('切换助手模式', tags: {
        'from_mode': _currentState.currentMode.toString(),
        'to_mode': mode.toString(),
      });
      
      // 保存当前模式设置
      await _saveModeSettings(_currentState.currentMode);
      
      // 更新状态
      _currentState = _currentState.copyWith(
        currentMode: mode,
        lastMode: _currentState.currentMode,
        switchTime: DateTime.now(),
      );
      
      // 加载新模式设置
      final settings = await _loadModeSettings(mode);
      _modeSettingsCache[mode] = settings;
      
      // 保存当前模式
      await _saveCurrentMode(mode);
      
      _updateState();
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '切换模式失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-15 + 获取模式设置功能
  Future<ModeSettings> getModeSettings(AssistantMode mode) async {
    try {
      // 优先从缓存获取
      if (_modeSettingsCache.containsKey(mode)) {
        return _modeSettingsCache[mode]!;
      }
      
      // 从配置服务加载
      final settings = await _loadModeSettings(mode);
      _modeSettingsCache[mode] = settings;
      
      return settings;
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '获取模式设置失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-15 + 更新模式设置功能
  Future<void> updateModeSettings(AssistantMode mode, ModeSettings settings) async {
    try {
      _loggingService.info('更新模式设置', tags: {
        'mode': mode.toString(),
        'settings': settings.toString(),
      });
      
      // 更新缓存
      _modeSettingsCache[mode] = settings;
      
      // 保存设置
      await _saveModeSettings(mode);
      
      // 如果是当前模式，更新状态
      if (mode == _currentState.currentMode) {
        _updateState();
      }
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '更新模式设置失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-15 + 检查模式权限功能
  Future<bool> checkModePermission(AssistantMode mode, String permission) async {
    try {
      // 检查模式是否有对应权限
      final permissions = _modePermissions[mode];
      if (permissions == null) return false;
      
      return permissions.contains(permission);
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '检查模式权限失败',
      );
      return false;
    }
  }
  
  // 2025-03-15 + 加载模式设置功能
  Future<ModeSettings> _loadModeSettings(AssistantMode mode) async {
    final key = 'mode_settings_${mode.toString()}';
    final data = await _configService.getItem(key);
    
    if (data != null) {
      return ModeSettings.fromMap(data as Map<String, dynamic>);
    }
    
    // 返回默认设置
    return _getDefaultSettings(mode);
  }
  
  // 2025-03-15 + 保存模式设置功能
  Future<void> _saveModeSettings(AssistantMode mode) async {
    final settings = _modeSettingsCache[mode];
    if (settings == null) return;
    
    final key = 'mode_settings_${mode.toString()}';
    await _configService.setItem(key, settings.toMap());
  }
  
  // 2025-03-15 + 加载上次模式功能
  Future<AssistantMode?> _loadLastMode() async {
    final data = await _configService.getItem('last_mode');
    if (data == null) return null;
    
    return AssistantMode.values.firstWhere(
      (mode) => mode.toString() == data as String,
      orElse: () => AssistantMode.standard,
    );
  }
  
  // 2025-03-15 + 保存当前模式功能
  Future<void> _saveCurrentMode(AssistantMode mode) async {
    await _configService.setItem('last_mode', mode.toString());
  }
  
  // 2025-03-15 + 获取默认设置功能
  ModeSettings _getDefaultSettings(AssistantMode mode) {
    switch (mode) {
      case AssistantMode.guardian:
        return ModeSettings(
          features: {
            'content_filtering': true,
            'time_limit': true,
            'parental_control': true,
          },
          restrictions: {
            'max_session_minutes': 60,
            'allowed_hours': ['8:00-20:00'],
            'blocked_topics': ['violence', 'adult'],
          },
          preferences: {
            'language': 'simple',
            'response_speed': 'slow',
            'guidance_level': 'high',
          },
        );
        
      case AssistantMode.standard:
        return ModeSettings(
          features: {
            'content_filtering': true,
            'code_completion': true,
            'learning_assistance': true,
          },
          restrictions: {
            'max_session_minutes': 240,
            'allowed_hours': ['6:00-23:00'],
            'blocked_topics': ['adult'],
          },
          preferences: {
            'language': 'normal',
            'response_speed': 'normal',
            'guidance_level': 'medium',
          },
        );
        
      case AssistantMode.pro:
        return ModeSettings(
          features: {
            'content_filtering': false,
            'advanced_tools': true,
            'experimental': true,
          },
          restrictions: {
            'max_session_minutes': 0, // 无限制
            'allowed_hours': ['0:00-24:00'],
            'blocked_topics': [],
          },
          preferences: {
            'language': 'technical',
            'response_speed': 'fast',
            'guidance_level': 'low',
          },
        );
    }
  }
  
  // 2025-03-15 + 更新状态功能
  void _updateState() {
    final state = _currentState.copyWith(
      modeSettings: Map.from(_modeSettingsCache),
    );
    
    _stateController.add(state);
  }
  
  // 2025-03-15 + 释放资源功能
  void dispose() {
    _stateController.close();
  }
}

/// 模式服务提供者
final modeServiceProvider = Provider<ModeService>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  final configService = ref.watch(configManagementServiceProvider);
  
  final service = ModeServiceImpl(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
    configService: configService,
  );
  
  ref.onDispose(() {
    if (service is ModeServiceImpl) {
      service.dispose();
    }
  });
  
  return service;
});

/// 模式状态流提供者
final modeStateStreamProvider = StreamProvider<ModeState>((ref) {
  final modeService = ref.watch(modeServiceProvider);
  return modeService.stateStream;
});
