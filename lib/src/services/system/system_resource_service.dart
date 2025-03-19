import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/logging_service.dart';
import '../error/error_handling_service.dart';

/// 系统资源类型
enum SystemResourceType {
  /// CPU
  cpu,
  
  /// 内存
  memory,
  
  /// 存储
  storage,
  
  /// 网络
  network,
  
  /// GPU
  gpu,
  
  /// 电池
  battery,
}

/// 资源状态
enum ResourceState {
  /// 正常
  normal,
  
  /// 警告
  warning,
  
  /// 错误
  error,
  
  /// 不可用
  unavailable,
}

/// 资源使用情况
class ResourceUsage {
  /// 资源类型
  final SystemResourceType type;
  
  /// 总量
  final double total;
  
  /// 已用量
  final double used;
  
  /// 可用量
  final double available;
  
  /// 使用率
  final double usageRate;
  
  /// 单位
  final String unit;
  
  /// 状态
  final ResourceState state;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 构造函数
  ResourceUsage({
    required this.type,
    required this.total,
    required this.used,
    required this.available,
    required this.usageRate,
    required this.unit,
    this.state = ResourceState.normal,
    this.details = const {},
  });
  
  /// 从Map创建资源使用情况
  factory ResourceUsage.fromMap(Map<String, dynamic> map) {
    return ResourceUsage(
      type: SystemResourceType.values.byName(map['type'] as String),
      total: map['total'] as double,
      used: map['used'] as double,
      available: map['available'] as double,
      usageRate: map['usageRate'] as double,
      unit: map['unit'] as String,
      state: ResourceState.values.byName(map['state'] as String),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'total': total,
      'used': used,
      'available': available,
      'usageRate': usageRate,
      'unit': unit,
      'state': state.name,
      'details': details,
    };
  }
}

/// 资源限制配置
class ResourceLimit {
  /// 资源类型
  final SystemResourceType type;
  
  /// 警告阈值（百分比）
  final double warningThreshold;
  
  /// 错误阈值（百分比）
  final double errorThreshold;
  
  /// 最小可用量
  final double minAvailable;
  
  /// 单位
  final String unit;
  
  /// 构造函数
  ResourceLimit({
    required this.type,
    required this.warningThreshold,
    required this.errorThreshold,
    required this.minAvailable,
    required this.unit,
  });
  
  /// 从Map创建资源限制
  factory ResourceLimit.fromMap(Map<String, dynamic> map) {
    return ResourceLimit(
      type: SystemResourceType.values.byName(map['type'] as String),
      warningThreshold: map['warningThreshold'] as double,
      errorThreshold: map['errorThreshold'] as double,
      minAvailable: map['minAvailable'] as double,
      unit: map['unit'] as String,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'warningThreshold': warningThreshold,
      'errorThreshold': errorThreshold,
      'minAvailable': minAvailable,
      'unit': unit,
    };
  }
}

/// 系统资源配置
class SystemResourceConfig {
  /// 监控间隔（毫秒）
  final int monitoringInterval;
  
  /// 资源限制列表
  final List<ResourceLimit> limits;
  
  /// 是否启用自动清理
  final bool enableAutoCleanup;
  
  /// 自动清理阈值（百分比）
  final double autoCleanupThreshold;
  
  /// 构造函数
  SystemResourceConfig({
    this.monitoringInterval = 5000,
    this.limits = const [],
    this.enableAutoCleanup = true,
    this.autoCleanupThreshold = 90.0,
  });
  
  /// 从Map创建配置
  factory SystemResourceConfig.fromMap(Map<String, dynamic> map) {
    return SystemResourceConfig(
      monitoringInterval: map['monitoringInterval'] ?? 5000,
      limits: (map['limits'] as List<dynamic>?)
          ?.map((e) => ResourceLimit.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
      enableAutoCleanup: map['enableAutoCleanup'] ?? true,
      autoCleanupThreshold: map['autoCleanupThreshold'] ?? 90.0,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'monitoringInterval': monitoringInterval,
      'limits': limits.map((e) => e.toMap()).toList(),
      'enableAutoCleanup': enableAutoCleanup,
      'autoCleanupThreshold': autoCleanupThreshold,
    };
  }
}

/// 系统资源服务
class SystemResourceService {
  /// 配置
  SystemResourceConfig _config;
  
  /// 日志服务
  final LoggingService _loggingService;
  
  /// 错误处理服务
  final ErrorHandlingService _errorHandlingService;
  
  /// 资源使用情况流控制器
  final StreamController<ResourceUsage> _usageController =
      StreamController<ResourceUsage>.broadcast();
  
  /// 资源使用情况流
  Stream<ResourceUsage> get usageStream => _usageController.stream;
  
  /// 定时器
  Timer? _timer;
  
  /// 资源使用情况缓存
  final Map<SystemResourceType, ResourceUsage> _usageCache = {};
  
  /// 构造函数
  SystemResourceService({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    SystemResourceConfig? config,
  })  : _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _config = config ?? SystemResourceConfig() {
    _initializeMonitoring();
  }
  
  /// 初始化监控
  void _initializeMonitoring() {
    // 停止现有定时器
    _timer?.cancel();
    
    // 创建新定时器
    _timer = Timer.periodic(
      Duration(milliseconds: _config.monitoringInterval),
      (_) => _monitorResources(),
    );
  }
  
  /// 监控资源
  Future<void> _monitorResources() async {
    try {
      await _monitorCpu();
      await _monitorMemory();
      await _monitorStorage();
      await _monitorNetwork();
      await _monitorGpu();
      await _monitorBattery();
      
      // 检查是否需要自动清理
      if (_config.enableAutoCleanup) {
        await _checkAutoCleanup();
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '系统资源监控失败',
      );
    }
  }
  
  /// 监控CPU
  Future<void> _monitorCpu() async {
    // TODO: 实现CPU监控
    final usage = ResourceUsage(
      type: SystemResourceType.cpu,
      total: 100.0,
      used: 0.0,
      available: 100.0,
      usageRate: 0.0,
      unit: '%',
    );
    
    _updateResourceUsage(usage);
  }
  
  /// 监控内存
  Future<void> _monitorMemory() async {
    // TODO: 实现内存监控
    final usage = ResourceUsage(
      type: SystemResourceType.memory,
      total: 0.0,
      used: 0.0,
      available: 0.0,
      usageRate: 0.0,
      unit: 'MB',
    );
    
    _updateResourceUsage(usage);
  }
  
  /// 监控存储
  Future<void> _monitorStorage() async {
    // TODO: 实现存储监控
    final usage = ResourceUsage(
      type: SystemResourceType.storage,
      total: 0.0,
      used: 0.0,
      available: 0.0,
      usageRate: 0.0,
      unit: 'GB',
    );
    
    _updateResourceUsage(usage);
  }
  
  /// 监控网络
  Future<void> _monitorNetwork() async {
    // TODO: 实现网络监控
    final usage = ResourceUsage(
      type: SystemResourceType.network,
      total: 0.0,
      used: 0.0,
      available: 0.0,
      usageRate: 0.0,
      unit: 'MB/s',
    );
    
    _updateResourceUsage(usage);
  }
  
  /// 监控GPU
  Future<void> _monitorGpu() async {
    // TODO: 实现GPU监控
    final usage = ResourceUsage(
      type: SystemResourceType.gpu,
      total: 0.0,
      used: 0.0,
      available: 0.0,
      usageRate: 0.0,
      unit: '%',
    );
    
    _updateResourceUsage(usage);
  }
  
  /// 监控电池
  Future<void> _monitorBattery() async {
    // TODO: 实现电池监控
    final usage = ResourceUsage(
      type: SystemResourceType.battery,
      total: 100.0,
      used: 0.0,
      available: 100.0,
      usageRate: 0.0,
      unit: '%',
    );
    
    _updateResourceUsage(usage);
  }
  
  /// 更新资源使用情况
  void _updateResourceUsage(ResourceUsage usage) {
    // 检查资源限制
    final limit = _config.limits.firstWhere(
      (l) => l.type == usage.type,
      orElse: () => null,
    );
    
    if (limit != null) {
      final state = _checkResourceState(usage, limit);
      usage = ResourceUsage(
        type: usage.type,
        total: usage.total,
        used: usage.used,
        available: usage.available,
        usageRate: usage.usageRate,
        unit: usage.unit,
        state: state,
        details: usage.details,
      );
    }
    
    // 更新缓存
    _usageCache[usage.type] = usage;
    
    // 发送到流
    _usageController.add(usage);
    
    // 记录日志
    if (usage.state != ResourceState.normal) {
      _loggingService.warning(
        '系统资源状态异常',
        tags: {
          'resource_type': usage.type.name,
          'state': usage.state.name,
          'usage_rate': usage.usageRate.toString(),
          'unit': usage.unit,
        },
      );
    }
  }
  
  /// 检查资源状态
  ResourceState _checkResourceState(ResourceUsage usage, ResourceLimit limit) {
    if (usage.available < limit.minAvailable) {
      return ResourceState.error;
    }
    
    if (usage.usageRate >= limit.errorThreshold) {
      return ResourceState.error;
    }
    
    if (usage.usageRate >= limit.warningThreshold) {
      return ResourceState.warning;
    }
    
    return ResourceState.normal;
  }
  
  /// 检查是否需要自动清理
  Future<void> _checkAutoCleanup() async {
    final memoryUsage = _usageCache[SystemResourceType.memory];
    final storageUsage = _usageCache[SystemResourceType.storage];
    
    if (memoryUsage != null &&
        memoryUsage.usageRate >= _config.autoCleanupThreshold) {
      await _cleanupMemory();
    }
    
    if (storageUsage != null &&
        storageUsage.usageRate >= _config.autoCleanupThreshold) {
      await _cleanupStorage();
    }
  }
  
  /// 清理内存
  Future<void> _cleanupMemory() async {
    // TODO: 实现内存清理
    _loggingService.info('正在清理内存...');
  }
  
  /// 清理存储
  Future<void> _cleanupStorage() async {
    // TODO: 实现存储清理
    _loggingService.info('正在清理存储...');
  }
  
  /// 获取资源使用情况
  ResourceUsage? getResourceUsage(SystemResourceType type) {
    return _usageCache[type];
  }
  
  /// 获取所有资源使用情况
  List<ResourceUsage> getAllResourceUsage() {
    return List.unmodifiable(_usageCache.values);
  }
  
  /// 更新配置
  void updateConfig(SystemResourceConfig config) {
    _config = config;
    _initializeMonitoring();
  }
  
  /// 获取当前配置
  SystemResourceConfig getConfig() {
    return _config;
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    _timer?.cancel();
    await _usageController.close();
  }
}

/// 系统资源服务提供者
final systemResourceServiceProvider = Provider<SystemResourceService>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final service = SystemResourceService(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 资源使用情况流提供者
final resourceUsageStreamProvider = StreamProvider<ResourceUsage>((ref) {
  final service = ref.watch(systemResourceServiceProvider);
  return service.usageStream;
}); 