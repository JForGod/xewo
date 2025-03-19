import 'dart:async';
import 'dart:io';

import 'security_policy.dart';

/// 系统调用类型
enum SyscallType {
  /// 文件操作
  fileOperation,
  
  /// 网络操作
  networkOperation,
  
  /// 进程操作
  processOperation,
  
  /// 内存操作
  memoryOperation,
  
  /// 设备操作
  deviceOperation,
  
  /// 其他操作
  other,
}

/// 系统调用信息
class SyscallInfo {
  /// 调用类型
  final SyscallType type;
  
  /// 调用名称
  final String name;
  
  /// 调用参数
  final List<dynamic> arguments;
  
  /// 调用时间
  final DateTime timestamp;
  
  /// 调用结果
  final dynamic result;
  
  /// 错误信息
  final String? error;
  
  /// 执行时间（毫秒）
  final int executionTimeMs;
  
  SyscallInfo({
    required this.type,
    required this.name,
    required this.arguments,
    this.result,
    this.error,
    required this.executionTimeMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 从Map创建
  factory SyscallInfo.fromMap(Map<String, dynamic> map) {
    return SyscallInfo(
      type: SyscallType.values.byName(map['type'] as String),
      name: map['name'] as String,
      arguments: List<dynamic>.from(map['arguments'] as List),
      result: map['result'],
      error: map['error'] as String?,
      executionTimeMs: map['executionTimeMs'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'name': name,
      'arguments': arguments,
      'result': result,
      'error': error,
      'executionTimeMs': executionTimeMs,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// 系统调用拦截器
class SyscallInterceptor {
  /// 安全策略
  final SecurityPolicy securityPolicy;
  
  /// 调用历史
  final List<SyscallInfo> _callHistory = [];
  
  /// 最大历史记录数
  final int _maxHistorySize = 1000;
  
  /// 调用信息流控制器
  final _syscallController = StreamController<SyscallInfo>.broadcast();
  
  /// 构造函数
  SyscallInterceptor({
    required this.securityPolicy,
  });
  
  /// 调用信息流
  Stream<SyscallInfo> get syscallStream => _syscallController.stream;
  
  /// 拦截文件操作
  Future<T> interceptFileOperation<T>(
    String operation,
    String path,
    Future<T> Function() action,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // 检查权限
      if (!_checkFilePermission(operation, path)) {
        throw Exception('没有权限执行文件操作: $operation on $path');
      }
      
      // 执行操作
      final result = await action();
      
      // 记录调用信息
      _recordSyscall(
        SyscallInfo(
          type: SyscallType.fileOperation,
          name: operation,
          arguments: [path],
          result: result,
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
      
      return result;
      
    } catch (e) {
      // 记录错误
      _recordSyscall(
        SyscallInfo(
          type: SyscallType.fileOperation,
          name: operation,
          arguments: [path],
          error: e.toString(),
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
      
      rethrow;
    }
  }
  
  /// 拦截网络操作
  Future<T> interceptNetworkOperation<T>(
    String operation,
    String target,
    Future<T> Function() action,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // 检查权限
      if (!securityPolicy.canAccessNetwork(target)) {
        throw Exception('没有权限访问网络目标: $target');
      }
      
      // 执行操作
      final result = await action();
      
      // 记录调用信息
      _recordSyscall(
        SyscallInfo(
          type: SyscallType.networkOperation,
          name: operation,
          arguments: [target],
          result: result,
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
      
      return result;
      
    } catch (e) {
      // 记录错误
      _recordSyscall(
        SyscallInfo(
          type: SyscallType.networkOperation,
          name: operation,
          arguments: [target],
          error: e.toString(),
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
      
      rethrow;
    }
  }
  
  /// 拦截进程操作
  Future<T> interceptProcessOperation<T>(
    String operation,
    String command,
    Future<T> Function() action,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // 检查权限
      if (!securityPolicy.hasPermission(PermissionType.processManagement)) {
        throw Exception('没有权限执行进程操作: $operation');
      }
      
      // 执行操作
      final result = await action();
      
      // 记录调用信息
      _recordSyscall(
        SyscallInfo(
          type: SyscallType.processOperation,
          name: operation,
          arguments: [command],
          result: result,
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
      
      return result;
      
    } catch (e) {
      // 记录错误
      _recordSyscall(
        SyscallInfo(
          type: SyscallType.processOperation,
          name: operation,
          arguments: [command],
          error: e.toString(),
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
      
      rethrow;
    }
  }
  
  /// 拦截内存操作
  Future<T> interceptMemoryOperation<T>(
    String operation,
    int size,
    Future<T> Function() action,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // 检查权限
      if (!securityPolicy.hasPermission(PermissionType.memoryAccess)) {
        throw Exception('没有权限执行内存操作: $operation');
      }
      
      // 执行操作
      final result = await action();
      
      // 记录调用信息
      _recordSyscall(
        SyscallInfo(
          type: SyscallType.memoryOperation,
          name: operation,
          arguments: [size],
          result: result,
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
      
      return result;
      
    } catch (e) {
      // 记录错误
      _recordSyscall(
        SyscallInfo(
          type: SyscallType.memoryOperation,
          name: operation,
          arguments: [size],
          error: e.toString(),
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
      
      rethrow;
    }
  }
  
  /// 拦截设备操作
  Future<T> interceptDeviceOperation<T>(
    String operation,
    String device,
    Future<T> Function() action,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // 检查权限
      if (!securityPolicy.hasPermission(PermissionType.deviceAccess)) {
        throw Exception('没有权限访问设备: $device');
      }
      
      // 执行操作
      final result = await action();
      
      // 记录调用信息
      _recordSyscall(
        SyscallInfo(
          type: SyscallType.deviceOperation,
          name: operation,
          arguments: [device],
          result: result,
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
      
      return result;
      
    } catch (e) {
      // 记录错误
      _recordSyscall(
        SyscallInfo(
          type: SyscallType.deviceOperation,
          name: operation,
          arguments: [device],
          error: e.toString(),
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
      
      rethrow;
    }
  }
  
  /// 检查文件操作权限
  bool _checkFilePermission(String operation, String path) {
    switch (operation.toLowerCase()) {
      case 'read':
        return securityPolicy.hasPermission(PermissionType.fileRead);
      
      case 'write':
      case 'create':
      case 'delete':
      case 'modify':
        return securityPolicy.hasPermission(PermissionType.fileWrite);
      
      default:
        return false;
    }
  }
  
  /// 记录系统调用
  void _recordSyscall(SyscallInfo info) {
    _callHistory.add(info);
    if (_callHistory.length > _maxHistorySize) {
      _callHistory.removeAt(0);
    }
    
    _syscallController.add(info);
  }
  
  /// 获取调用历史
  List<SyscallInfo> getCallHistory() {
    return List.unmodifiable(_callHistory);
  }
  
  /// 获取调用统计
  Map<String, dynamic> getCallStats() {
    if (_callHistory.isEmpty) {
      return {
        'totalCalls': 0,
        'successfulCalls': 0,
        'failedCalls': 0,
        'averageExecutionTime': 0,
        'callsByType': {},
      };
    }
    
    var successfulCalls = 0;
    var failedCalls = 0;
    var totalExecutionTime = 0;
    final callsByType = <String, int>{};
    
    for (final call in _callHistory) {
      if (call.error == null) {
        successfulCalls++;
      } else {
        failedCalls++;
      }
      
      totalExecutionTime += call.executionTimeMs;
      callsByType[call.type.name] = (callsByType[call.type.name] ?? 0) + 1;
    }
    
    return {
      'totalCalls': _callHistory.length,
      'successfulCalls': successfulCalls,
      'failedCalls': failedCalls,
      'averageExecutionTime': totalExecutionTime / _callHistory.length,
      'callsByType': callsByType,
    };
  }
  
  /// 清理资源
  void dispose() {
    _syscallController.close();
  }
} 