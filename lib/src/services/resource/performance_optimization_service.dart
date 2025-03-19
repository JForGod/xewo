import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'resource_monitoring_service.dart';

/// 优化动作类型
enum OptimizationActionType {
  /// 清理内存
  memoryCleanup,
  
  /// 清理存储
  storageCleanup,
  
  /// 网络优化
  networkOptimization,
  
  /// 电池优化
  batteryOptimization,
  
  /// CPU优化
  cpuOptimization,
  
  /// GPU优化
  gpuOptimization,
  
  /// 缓存优化
  cacheOptimization,
}

/// 优化动作优先级
enum OptimizationPriority {
  /// 低优先级
  low,
  
  /// 中优先级
  medium,
  
  /// 高优先级
  high,
  
  /// 紧急
  critical,
}

/// 优化动作状态
enum OptimizationActionStatus {
  /// 等待执行
  pending,
  
  /// 执行中
  running,
  
  /// 已完成
  completed,
  
  /// 失败
  failed,
  
  /// 已取消
  cancelled,
}

/// 优化动作
class OptimizationAction {
  /// 唯一标识符
  final String id;
  
  /// 动作类型
  final OptimizationActionType type;
  
  /// 优先级
  final OptimizationPriority priority;
  
  /// 状态
  final OptimizationActionStatus status;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 开始时间
  final DateTime? startedAt;
  
  /// 完成时间
  final DateTime? completedAt;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 错误信息
  final String? error;
  
  /// 构造函数
  OptimizationAction({
    String? id,
    required this.type,
    required this.priority,
    this.status = OptimizationActionStatus.pending,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    this.details = const {},
    this.error,
  }) : 
    id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    createdAt = createdAt ?? DateTime.now();
  
  /// 从Map创建优化动作
  factory OptimizationAction.fromMap(Map<String, dynamic> map) {
    return OptimizationAction(
      id: map['id'] as String,
      type: OptimizationActionType.values.byName(map['type']),
      priority: OptimizationPriority.values.byName(map['priority']),
      status: OptimizationActionStatus.values.byName(map['status']),
      createdAt: DateTime.parse(map['createdAt']),
      startedAt: map['startedAt'] != null 
        ? DateTime.parse(map['startedAt']) 
        : null,
      completedAt: map['completedAt'] != null 
        ? DateTime.parse(map['completedAt']) 
        : null,
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      error: map['error'] as String?,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'details': details,
      'error': error,
    };
  }
  
  /// 复制并修改
  OptimizationAction copyWith({
    String? id,
    OptimizationActionType? type,
    OptimizationPriority? priority,
    OptimizationActionStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? details,
    String? error,
  }) {
    return OptimizationAction(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      details: details ?? Map<String, dynamic>.from(this.details),
      error: error ?? this.error,
    );
  }
}

/// 性能优化配置
class PerformanceOptimizationConfig {
  /// 是否启用自动优化
  final bool enableAutoOptimization;
  
  /// 优化检查间隔（毫秒）
  final int optimizationCheckIntervalMs;
  
  /// 最大并发优化动作数
  final int maxConcurrentActions;
  
  /// 历史记录保留时间（天）
  final int historyRetentionDays;
  
  /// 资源类型到优化动作类型的映射
  final Map<ResourceType, List<OptimizationActionType>> resourceOptimizationMap;
  
  /// 构造函数
  PerformanceOptimizationConfig({
    this.enableAutoOptimization = true,
    this.optimizationCheckIntervalMs = 60000,
    this.maxConcurrentActions = 3,
    this.historyRetentionDays = 7,
    Map<ResourceType, List<OptimizationActionType>>? resourceOptimizationMap,
  }) : resourceOptimizationMap = resourceOptimizationMap ?? {
    ResourceType.memory: [
      OptimizationActionType.memoryCleanup,
      OptimizationActionType.cacheOptimization,
    ],
    ResourceType.storage: [
      OptimizationActionType.storageCleanup,
      OptimizationActionType.cacheOptimization,
    ],
    ResourceType.network: [
      OptimizationActionType.networkOptimization,
      OptimizationActionType.cacheOptimization,
    ],
    ResourceType.battery: [
      OptimizationActionType.batteryOptimization,
      OptimizationActionType.cpuOptimization,
      OptimizationActionType.gpuOptimization,
    ],
    ResourceType.cpu: [
      OptimizationActionType.cpuOptimization,
      OptimizationActionType.memoryCleanup,
    ],
    ResourceType.gpu: [
      OptimizationActionType.gpuOptimization,
      OptimizationActionType.memoryCleanup,
    ],
  };
  
  /// 从Map创建配置
  factory PerformanceOptimizationConfig.fromMap(Map<String, dynamic> map) {
    final resourceOptimizationMapJson = 
      map['resourceOptimizationMap'] as Map<String, dynamic>? ?? {};
    
    final resourceOptimizationMap = <ResourceType, List<OptimizationActionType>>{};
    
    for (final entry in resourceOptimizationMapJson.entries) {
      try {
        final resourceType = ResourceType.values.byName(entry.key);
        final actionTypes = (entry.value as List<dynamic>)
          .map((e) => OptimizationActionType.values.byName(e as String))
          .toList();
        resourceOptimizationMap[resourceType] = actionTypes;
      } catch (e) {
        print('解析资源优化映射失败: $e');
      }
    }
    
    return PerformanceOptimizationConfig(
      enableAutoOptimization: map['enableAutoOptimization'] ?? true,
      optimizationCheckIntervalMs: map['optimizationCheckIntervalMs'] ?? 60000,
      maxConcurrentActions: map['maxConcurrentActions'] ?? 3,
      historyRetentionDays: map['historyRetentionDays'] ?? 7,
      resourceOptimizationMap: resourceOptimizationMap,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'enableAutoOptimization': enableAutoOptimization,
      'optimizationCheckIntervalMs': optimizationCheckIntervalMs,
      'maxConcurrentActions': maxConcurrentActions,
      'historyRetentionDays': historyRetentionDays,
      'resourceOptimizationMap': {
        for (final entry in resourceOptimizationMap.entries)
          entry.key.name: entry.value.map((e) => e.name).toList(),
      },
    };
  }
}

/// 性能优化服务
class PerformanceOptimizationService {
  /// 资源监控服务
  final ResourceMonitoringService _monitoringService;
  
  /// 配置
  PerformanceOptimizationConfig _config;
  
  /// 定时器
  Timer? _optimizationTimer;
  
  /// 优化动作队列
  final List<OptimizationAction> _actionQueue = [];
  
  /// 正在执行的优化动作
  final List<OptimizationAction> _runningActions = [];
  
  /// 已完成的优化动作历史
  final List<OptimizationAction> _actionHistory = [];
  
  /// 优化动作流控制器
  final StreamController<OptimizationAction> _actionController =
      StreamController<OptimizationAction>.broadcast();
  
  /// 优化动作流
  Stream<OptimizationAction> get actionStream => _actionController.stream;
  
  /// 构造函数
  PerformanceOptimizationService({
    required ResourceMonitoringService monitoringService,
    PerformanceOptimizationConfig? config,
  }) : 
    _monitoringService = monitoringService,
    _config = config ?? PerformanceOptimizationConfig() {
    // 监听资源警告
    _monitoringService.warningStream.listen(_handleResourceWarning);
  }
  
  /// 初始化
  Future<void> initialize() async {
    // 停止现有的优化检查
    await stop();
    
    // 清理过期历史记录
    _cleanupHistory();
    
    // 如果启用了自动优化，开始优化检查
    if (_config.enableAutoOptimization) {
      _startOptimizationCheck();
    }
  }
  
  /// 开始优化检查
  void _startOptimizationCheck() {
    _optimizationTimer = Timer.periodic(
      Duration(milliseconds: _config.optimizationCheckIntervalMs),
      (_) => _checkAndOptimize(),
    );
  }
  
  /// 停止优化检查
  Future<void> stop() async {
    _optimizationTimer?.cancel();
    _optimizationTimer = null;
  }
  
  /// 处理资源警告
  void _handleResourceWarning(ResourceUsageData warning) {
    // 获取适用于该资源类型的优化动作
    final actionTypes = _config.resourceOptimizationMap[warning.type] ?? [];
    
    // 根据资源状态确定优先级
    final priority = warning.state == ResourceUsageState.danger
      ? OptimizationPriority.critical
      : OptimizationPriority.high;
    
    // 创建优化动作
    for (final actionType in actionTypes) {
      final action = OptimizationAction(
        type: actionType,
        priority: priority,
        details: {
          'triggerType': 'resourceWarning',
          'resourceType': warning.type.name,
          'resourceState': warning.state.name,
          'usagePercentage': warning.usagePercentage,
          'timestamp': warning.timestamp.toIso8601String(),
        },
      );
      
      // 添加到队列
      _enqueueAction(action);
    }
  }
  
  /// 检查并执行优化
  Future<void> _checkAndOptimize() async {
    try {
      // 获取所有资源的最新使用数据
      final resourceData = _monitoringService.getAllLatestUsageData();
      
      // 检查每种资源
      for (final entry in resourceData.entries) {
        final resourceType = entry.key;
        final usageData = entry.value;
        
        // 如果资源使用率超过警告阈值
        if (usageData.state != ResourceUsageState.normal) {
          // 获取适用的优化动作
          final actionTypes = _config.resourceOptimizationMap[resourceType] ?? [];
          
          // 确定优先级
          final priority = usageData.state == ResourceUsageState.danger
            ? OptimizationPriority.high
            : OptimizationPriority.medium;
          
          // 创建优化动作
          for (final actionType in actionTypes) {
            final action = OptimizationAction(
              type: actionType,
              priority: priority,
              details: {
                'triggerType': 'scheduledCheck',
                'resourceType': resourceType.name,
                'resourceState': usageData.state.name,
                'usagePercentage': usageData.usagePercentage,
                'timestamp': usageData.timestamp.toIso8601String(),
              },
            );
            
            // 添加到队列
            _enqueueAction(action);
          }
        }
      }
      
      // 执行队列中的动作
      await _processActionQueue();
    } catch (e) {
      print('执行优化检查时出错: $e');
    }
  }
  
  /// 将优化动作添加到队列
  void _enqueueAction(OptimizationAction action) {
    // 检查是否已有相同类型的动作在队列中
    final hasExisting = _actionQueue.any((a) => 
      a.type == action.type && 
      a.status == OptimizationActionStatus.pending
    );
    
    if (!hasExisting) {
      _actionQueue.add(action);
      
      // 按优先级排序
      _actionQueue.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      
      // 发送到流
      _actionController.add(action);
    }
  }
  
  /// 处理优化动作队列
  Future<void> _processActionQueue() async {
    // 检查是否可以执行更多动作
    while (_runningActions.length < _config.maxConcurrentActions && 
           _actionQueue.isNotEmpty) {
      final action = _actionQueue.removeAt(0);
      
      // 更新状态为执行中
      final runningAction = action.copyWith(
        status: OptimizationActionStatus.running,
        startedAt: DateTime.now(),
      );
      
      _runningActions.add(runningAction);
      _actionController.add(runningAction);
      
      // 执行优化动作
      _executeAction(runningAction).then((result) {
        _runningActions.remove(runningAction);
        
        // 添加到历史记录
        _actionHistory.add(result);
        _actionController.add(result);
        
        // 清理过期历史记录
        _cleanupHistory();
      });
    }
  }
  
  /// 执行优化动作
  Future<OptimizationAction> _executeAction(OptimizationAction action) async {
    try {
      switch (action.type) {
        case OptimizationActionType.memoryCleanup:
          return await _executeMemoryCleanup(action);
        case OptimizationActionType.storageCleanup:
          return await _executeStorageCleanup(action);
        case OptimizationActionType.networkOptimization:
          return await _executeNetworkOptimization(action);
        case OptimizationActionType.batteryOptimization:
          return await _executeBatteryOptimization(action);
        case OptimizationActionType.cpuOptimization:
          return await _executeCpuOptimization(action);
        case OptimizationActionType.gpuOptimization:
          return await _executeGpuOptimization(action);
        case OptimizationActionType.cacheOptimization:
          return await _executeCacheOptimization(action);
      }
    } catch (e) {
      return action.copyWith(
        status: OptimizationActionStatus.failed,
        completedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }
  
  /// 执行内存清理
  Future<OptimizationAction> _executeMemoryCleanup(OptimizationAction action) async {
    // 在实际应用中，这里应该实现内存清理逻辑
    await Future.delayed(Duration(seconds: 2));
    
    return action.copyWith(
      status: OptimizationActionStatus.completed,
      completedAt: DateTime.now(),
      details: {
        ...action.details,
        'cleanedMemory': '500MB',
        'duration': '2s',
      },
    );
  }
  
  /// 执行存储清理
  Future<OptimizationAction> _executeStorageCleanup(OptimizationAction action) async {
    // 在实际应用中，这里应该实现存储清理逻辑
    await Future.delayed(Duration(seconds: 3));
    
    return action.copyWith(
      status: OptimizationActionStatus.completed,
      completedAt: DateTime.now(),
      details: {
        ...action.details,
        'cleanedStorage': '1.2GB',
        'duration': '3s',
      },
    );
  }
  
  /// 执行网络优化
  Future<OptimizationAction> _executeNetworkOptimization(OptimizationAction action) async {
    // 在实际应用中，这里应该实现网络优化逻辑
    await Future.delayed(Duration(seconds: 1));
    
    return action.copyWith(
      status: OptimizationActionStatus.completed,
      completedAt: DateTime.now(),
      details: {
        ...action.details,
        'optimizedConnections': '5',
        'duration': '1s',
      },
    );
  }
  
  /// 执行电池优化
  Future<OptimizationAction> _executeBatteryOptimization(OptimizationAction action) async {
    // 在实际应用中，这里应该实现电池优化逻辑
    await Future.delayed(Duration(seconds: 2));
    
    return action.copyWith(
      status: OptimizationActionStatus.completed,
      completedAt: DateTime.now(),
      details: {
        ...action.details,
        'powerSavingMode': 'enabled',
        'duration': '2s',
      },
    );
  }
  
  /// 执行CPU优化
  Future<OptimizationAction> _executeCpuOptimization(OptimizationAction action) async {
    // 在实际应用中，这里应该实现CPU优化逻辑
    await Future.delayed(Duration(seconds: 1));
    
    return action.copyWith(
      status: OptimizationActionStatus.completed,
      completedAt: DateTime.now(),
      details: {
        ...action.details,
        'optimizedProcesses': '3',
        'duration': '1s',
      },
    );
  }
  
  /// 执行GPU优化
  Future<OptimizationAction> _executeGpuOptimization(OptimizationAction action) async {
    // 在实际应用中，这里应该实现GPU优化逻辑
    await Future.delayed(Duration(seconds: 1));
    
    return action.copyWith(
      status: OptimizationActionStatus.completed,
      completedAt: DateTime.now(),
      details: {
        ...action.details,
        'optimizedRendering': 'true',
        'duration': '1s',
      },
    );
  }
  
  /// 执行缓存优化
  Future<OptimizationAction> _executeCacheOptimization(OptimizationAction action) async {
    // 在实际应用中，这里应该实现缓存优化逻辑
    await Future.delayed(Duration(seconds: 2));
    
    return action.copyWith(
      status: OptimizationActionStatus.completed,
      completedAt: DateTime.now(),
      details: {
        ...action.details,
        'cleanedCache': '800MB',
        'duration': '2s',
      },
    );
  }
  
  /// 清理过期历史记录
  void _cleanupHistory() {
    final cutoffDate = DateTime.now().subtract(
      Duration(days: _config.historyRetentionDays),
    );
    
    _actionHistory.removeWhere((action) => 
      action.completedAt?.isBefore(cutoffDate) ?? false
    );
  }
  
  /// 获取优化动作历史
  List<OptimizationAction> getActionHistory({
    OptimizationActionType? type,
    OptimizationActionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) {
    var filteredHistory = List<OptimizationAction>.from(_actionHistory);
    
    if (type != null) {
      filteredHistory = filteredHistory.where((action) => 
        action.type == type
      ).toList();
    }
    
    if (status != null) {
      filteredHistory = filteredHistory.where((action) => 
        action.status == status
      ).toList();
    }
    
    if (startTime != null) {
      filteredHistory = filteredHistory.where((action) => 
        action.createdAt.isAfter(startTime)
      ).toList();
    }
    
    if (endTime != null) {
      filteredHistory = filteredHistory.where((action) => 
        action.createdAt.isBefore(endTime)
      ).toList();
    }
    
    // 按时间倒序排序
    filteredHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (limit != null && filteredHistory.length > limit) {
      filteredHistory = filteredHistory.sublist(0, limit);
    }
    
    return filteredHistory;
  }
  
  /// 获取正在执行的优化动作
  List<OptimizationAction> getRunningActions() {
    return List<OptimizationAction>.from(_runningActions);
  }
  
  /// 获取等待执行的优化动作
  List<OptimizationAction> getPendingActions() {
    return List<OptimizationAction>.from(_actionQueue);
  }
  
  /// 取消优化动作
  Future<bool> cancelAction(String actionId) async {
    // 检查队列中的动作
    final queueIndex = _actionQueue.indexWhere((action) => action.id == actionId);
    if (queueIndex != -1) {
      final action = _actionQueue.removeAt(queueIndex);
      final cancelledAction = action.copyWith(
        status: OptimizationActionStatus.cancelled,
        completedAt: DateTime.now(),
      );
      _actionHistory.add(cancelledAction);
      _actionController.add(cancelledAction);
      return true;
    }
    
    // 检查正在执行的动作
    final runningIndex = _runningActions.indexWhere((action) => action.id == actionId);
    if (runningIndex != -1) {
      // 注意：在实际应用中，这里应该实现取消正在执行的优化动作的逻辑
      return false;
    }
    
    return false;
  }
  
  /// 更新配置
  Future<void> updateConfig(PerformanceOptimizationConfig config) async {
    _config = config;
    
    // 重新启动优化检查
    await stop();
    if (_config.enableAutoOptimization) {
      _startOptimizationCheck();
    }
  }
  
  /// 获取当前配置
  PerformanceOptimizationConfig getConfig() {
    return _config;
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    await stop();
    await _actionController.close();
  }
}

/// 性能优化服务提供者
final performanceOptimizationServiceProvider = Provider<PerformanceOptimizationService>((ref) {
  final monitoringService = ref.watch(resourceMonitoringServiceProvider);
  
  final service = PerformanceOptimizationService(
    monitoringService: monitoringService,
  );
  
  // 初始化服务
  service.initialize();
  
  // 在提供者被释放时关闭服务
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 优化动作流提供者
final optimizationActionStreamProvider = StreamProvider<OptimizationAction>((ref) {
  final service = ref.watch(performanceOptimizationServiceProvider);
  
  return service.actionStream;
});

/// 优化动作历史提供者
final optimizationActionHistoryProvider = Provider.family<List<OptimizationAction>, Map<String, dynamic>>((ref, filters) {
  final service = ref.watch(performanceOptimizationServiceProvider);
  
  return service.getActionHistory(
    type: filters['type'] as OptimizationActionType?,
    status: filters['status'] as OptimizationActionStatus?,
    startTime: filters['startTime'] as DateTime?,
    endTime: filters['endTime'] as DateTime?,
    limit: filters['limit'] as int?,
  );
});

/// 运行中的优化动作提供者
final runningOptimizationActionsProvider = Provider<List<OptimizationAction>>((ref) {
  final service = ref.watch(performanceOptimizationServiceProvider);
  
  return service.getRunningActions();
});

/// 等待中的优化动作提供者
final pendingOptimizationActionsProvider = Provider<List<OptimizationAction>>((ref) {
  final service = ref.watch(performanceOptimizationServiceProvider);
  
  return service.getPendingActions();
}); 