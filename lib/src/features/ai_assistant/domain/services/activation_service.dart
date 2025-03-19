import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/logging/logging_service.dart';
import '../../../../core/services/error/error_handling_service.dart';
import '../models/activation_method.dart';
import '../models/activation_state.dart';

/// 激活服务接口
abstract class ActivationService {
  /// 获取激活状态流
  Stream<ActivationState> get stateStream;
  
  /// 获取当前激活状态
  Future<ActivationState> getCurrentState();
  
  /// 通过特定方法激活助手
  // 2025-03-15 + 通过特定方法激活助手功能
  Future<bool> activateByMethod(ActivationMethod method, {Map<String, dynamic>? data});
  
  /// 停用助手
  // 2025-03-15 + 停用助手功能
  Future<void> deactivate();
  
  /// 配置激活方法
  // 2025-03-15 + 配置激活方法功能
  Future<void> configureMethod(ActivationMethod method, {required bool enabled, Map<String, dynamic>? settings});
  
  /// 获取激活方法配置
  // 2025-03-15 + 获取激活方法配置功能
  Future<Map<String, dynamic>> getMethodConfiguration(ActivationMethod method);
}

/// 激活服务实现
class ActivationServiceImpl implements ActivationService {
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  
  /// 激活状态控制器
  final StreamController<ActivationState> _stateController = 
      StreamController<ActivationState>.broadcast();
  
  /// 当前激活状态
  ActivationState _currentState = ActivationState(
    isActive: false,
    lastActivationMethod: null,
    lastActivationTime: null,
    enabledMethods: {
      ActivationMethod.hotkey: true,
      ActivationMethod.voice: true,
      ActivationMethod.gesture: false,
      ActivationMethod.gaze: false,
      ActivationMethod.scheduled: false,
    },
    methodConfigurations: {},
  );
  
  /// 方法配置
  final Map<ActivationMethod, Map<String, dynamic>> _methodConfigurations = {
    ActivationMethod.hotkey: {
      'key_combination': 'Ctrl+Shift+A',
      'global': true,
    },
    ActivationMethod.voice: {
      'wake_word': '你好助手',
      'sensitivity': 0.7,
      'always_listening': true,
    },
    ActivationMethod.gesture: {
      'gesture_type': 'wave',
      'sensitivity': 0.6,
    },
    ActivationMethod.gaze: {
      'duration_seconds': 2.0,
      'sensitivity': 0.5,
    },
    ActivationMethod.scheduled: {
      'schedule': [],
      'auto_deactivate': true,
      'deactivate_after_minutes': 30,
    },
  };
  
  /// 构造函数
  ActivationServiceImpl({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
  }) : _loggingService = loggingService,
       _errorHandlingService = errorHandlingService {
    // 初始化状态
    _updateState();
  }
  
  @override
  Stream<ActivationState> get stateStream => _stateController.stream;
  
  @override
  // 2025-03-15 + 获取当前激活状态功能
  Future<ActivationState> getCurrentState() async {
    return _currentState;
  }
  
  @override
  // 2025-03-15 + 通过特定方法激活助手功能
  Future<bool> activateByMethod(ActivationMethod method, {Map<String, dynamic>? data}) async {
    try {
      // 检查方法是否启用
      if (!_currentState.enabledMethods[method]!) {
        _loggingService.warning('尝试使用未启用的激活方法', tags: {
          'method': method.toString(),
        });
        return false;
      }
      
      _loggingService.info('通过方法激活助手', tags: {
        'method': method.toString(),
        'data': data?.toString() ?? 'null',
      });
      
      // 验证激活数据
      if (!await _validateActivationData(method, data)) {
        _loggingService.warning('激活数据验证失败', tags: {
          'method': method.toString(),
          'data': data?.toString() ?? 'null',
        });
        return false;
      }
      
      // 更新状态
      _currentState = _currentState.copyWith(
        isActive: true,
        lastActivationMethod: method,
        lastActivationTime: DateTime.now(),
      );
      
      _updateState();
      return true;
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e, 
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '激活助手失败',
      );
      return false;
    }
  }
  
  @override
  // 2025-03-15 + 停用助手功能
  Future<void> deactivate() async {
    try {
      _loggingService.info('停用助手');
      
      // 更新状态
      _currentState = _currentState.copyWith(
        isActive: false,
      );
      
      _updateState();
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e, 
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '停用助手失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-15 + 配置激活方法功能
  Future<void> configureMethod(ActivationMethod method, {required bool enabled, Map<String, dynamic>? settings}) async {
    try {
      _loggingService.info('配置激活方法', tags: {
        'method': method.toString(),
        'enabled': enabled.toString(),
        'settings': settings?.toString() ?? 'null',
      });
      
      // 更新启用状态
      final updatedEnabledMethods = Map<ActivationMethod, bool>.from(_currentState.enabledMethods);
      updatedEnabledMethods[method] = enabled;
      
      // 更新配置
      if (settings != null) {
        _methodConfigurations[method]?.addAll(settings);
      }
      
      // 更新状态
      _currentState = _currentState.copyWith(
        enabledMethods: updatedEnabledMethods,
        methodConfigurations: Map.from(_methodConfigurations),
      );
      
      _updateState();
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e, 
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '配置激活方法失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-15 + 获取激活方法配置功能
  Future<Map<String, dynamic>> getMethodConfiguration(ActivationMethod method) async {
    return Map.from(_methodConfigurations[method] ?? {});
  }
  
  // 2025-03-15 + 验证激活数据功能
  Future<bool> _validateActivationData(ActivationMethod method, Map<String, dynamic>? data) async {
    if (data == null) return true;
    
    switch (method) {
      case ActivationMethod.hotkey:
        // 验证热键组合
        final expectedCombination = _methodConfigurations[method]?['key_combination'];
        return data['key_combination'] == expectedCombination;
        
      case ActivationMethod.voice:
        // 验证唤醒词
        final expectedWakeWord = _methodConfigurations[method]?['wake_word'];
        final confidence = data['confidence'] as double? ?? 0.0;
        final sensitivity = _methodConfigurations[method]?['sensitivity'] as double? ?? 0.7;
        
        return data['wake_word'] == expectedWakeWord && confidence >= sensitivity;
        
      case ActivationMethod.gesture:
        // 验证手势类型
        final expectedGestureType = _methodConfigurations[method]?['gesture_type'];
        final confidence = data['confidence'] as double? ?? 0.0;
        final sensitivity = _methodConfigurations[method]?['sensitivity'] as double? ?? 0.6;
        
        return data['gesture_type'] == expectedGestureType && confidence >= sensitivity;
        
      case ActivationMethod.gaze:
        // 验证注视时长
        final expectedDuration = _methodConfigurations[method]?['duration_seconds'] as double? ?? 2.0;
        final actualDuration = data['duration_seconds'] as double? ?? 0.0;
        
        return actualDuration >= expectedDuration;
        
      case ActivationMethod.scheduled:
        // 验证是否在计划时间内
        final schedule = _methodConfigurations[method]?['schedule'] as List? ?? [];
        final now = DateTime.now();
        
        for (final scheduledTime in schedule) {
          final scheduledDateTime = DateTime.parse(scheduledTime as String);
          final difference = now.difference(scheduledDateTime).inMinutes.abs();
          
          if (difference <= 5) {  // 5分钟内视为有效
            return true;
          }
        }
        
        return false;
    }
  }
  
  // 2025-03-15 + 更新状态功能
  void _updateState() {
    _stateController.add(_currentState);
  }
  
  // 2025-03-15 + 释放资源功能
  void dispose() {
    _stateController.close();
  }
}

/// 激活服务提供者
final activationServiceProvider = Provider<ActivationService>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final service = ActivationServiceImpl(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    if (service is ActivationServiceImpl) {
      service.dispose();
    }
  });
  
  return service;
});

/// 激活状态流提供者
final activationStateStreamProvider = StreamProvider<ActivationState>((ref) {
  final activationService = ref.watch(activationServiceProvider);
  return activationService.stateStream;
});
