import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 资源类型枚举
enum ResourceType {
  /// CPU资源
  cpu,
  
  /// 内存资源
  memory,
  
  /// 存储资源
  storage,
  
  /// 网络资源
  network,
  
  /// GPU资源
  gpu,
  
  /// 电池资源
  battery,
}

/// 资源使用状态枚举
enum ResourceUsageState {
  /// 正常
  normal,
  
  /// 警告
  warning,
  
  /// 危险
  danger,
  
  /// 未知
  unknown,
}

/// 资源使用数据
class ResourceUsageData {
  /// 资源类型
  final ResourceType type;
  
  /// 使用率（百分比）
  final double usagePercentage;
  
  /// 总量（单位取决于资源类型）
  final double total;
  
  /// 已使用（单位取决于资源类型）
  final double used;
  
  /// 可用（单位取决于资源类型）
  final double available;
  
  /// 状态
  final ResourceUsageState state;
  
  /// 时间戳
  final DateTime timestamp;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 构造函数
  ResourceUsageData({
    required this.type,
    required this.usagePercentage,
    required this.total,
    required this.used,
    required this.available,
    required this.state,
    DateTime? timestamp,
    this.details = const {},
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 从Map创建资源使用数据
  factory ResourceUsageData.fromMap(Map<String, dynamic> map) {
    return ResourceUsageData(
      type: ResourceType.values.byName(map['type']),
      usagePercentage: map['usagePercentage'],
      total: map['total'],
      used: map['used'],
      available: map['available'],
      state: ResourceUsageState.values.byName(map['state']),
      timestamp: DateTime.parse(map['timestamp']),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'usagePercentage': usagePercentage,
      'total': total,
      'used': used,
      'available': available,
      'state': state.name,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
  
  /// 复制并修改
  ResourceUsageData copyWith({
    ResourceType? type,
    double? usagePercentage,
    double? total,
    double? used,
    double? available,
    ResourceUsageState? state,
    DateTime? timestamp,
    Map<String, dynamic>? details,
  }) {
    return ResourceUsageData(
      type: type ?? this.type,
      usagePercentage: usagePercentage ?? this.usagePercentage,
      total: total ?? this.total,
      used: used ?? this.used,
      available: available ?? this.available,
      state: state ?? this.state,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? Map<String, dynamic>.from(this.details),
    );
  }
}

/// 资源阈值配置
class ResourceThresholdConfig {
  /// 警告阈值（百分比）
  final double warningThreshold;
  
  /// 危险阈值（百分比）
  final double dangerThreshold;
  
  /// 构造函数
  ResourceThresholdConfig({
    this.warningThreshold = 70.0,
    this.dangerThreshold = 90.0,
  });
  
  /// 从Map创建资源阈值配置
  factory ResourceThresholdConfig.fromMap(Map<String, dynamic> map) {
    return ResourceThresholdConfig(
      warningThreshold: map['warningThreshold'] ?? 70.0,
      dangerThreshold: map['dangerThreshold'] ?? 90.0,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'warningThreshold': warningThreshold,
      'dangerThreshold': dangerThreshold,
    };
  }
}

/// 资源监控配置
class ResourceMonitoringConfig {
  /// 监控间隔（毫秒）
  final int monitoringIntervalMs;
  
  /// 是否启用CPU监控
  final bool enableCpuMonitoring;
  
  /// 是否启用内存监控
  final bool enableMemoryMonitoring;
  
  /// 是否启用存储监控
  final bool enableStorageMonitoring;
  
  /// 是否启用网络监控
  final bool enableNetworkMonitoring;
  
  /// 是否启用GPU监控
  final bool enableGpuMonitoring;
  
  /// 是否启用电池监控
  final bool enableBatteryMonitoring;
  
  /// 资源阈值配置
  final Map<ResourceType, ResourceThresholdConfig> thresholds;
  
  /// 构造函数
  ResourceMonitoringConfig({
    this.monitoringIntervalMs = 5000,
    this.enableCpuMonitoring = true,
    this.enableMemoryMonitoring = true,
    this.enableStorageMonitoring = true,
    this.enableNetworkMonitoring = true,
    this.enableGpuMonitoring = false,
    this.enableBatteryMonitoring = true,
    Map<ResourceType, ResourceThresholdConfig>? thresholds,
  }) : thresholds = thresholds ?? {
    for (final type in ResourceType.values)
      type: ResourceThresholdConfig(),
  };
  
  /// 从Map创建资源监控配置
  factory ResourceMonitoringConfig.fromMap(Map<String, dynamic> map) {
    final thresholdsMap = map['thresholds'] as Map<String, dynamic>? ?? {};
    final thresholds = <ResourceType, ResourceThresholdConfig>{};
    
    for (final entry in thresholdsMap.entries) {
      try {
        final type = ResourceType.values.byName(entry.key);
        final config = ResourceThresholdConfig.fromMap(entry.value);
        thresholds[type] = config;
      } catch (e) {
        print('解析资源阈值配置失败: $e');
      }
    }
    
    return ResourceMonitoringConfig(
      monitoringIntervalMs: map['monitoringIntervalMs'] ?? 5000,
      enableCpuMonitoring: map['enableCpuMonitoring'] ?? true,
      enableMemoryMonitoring: map['enableMemoryMonitoring'] ?? true,
      enableStorageMonitoring: map['enableStorageMonitoring'] ?? true,
      enableNetworkMonitoring: map['enableNetworkMonitoring'] ?? true,
      enableGpuMonitoring: map['enableGpuMonitoring'] ?? false,
      enableBatteryMonitoring: map['enableBatteryMonitoring'] ?? true,
      thresholds: thresholds,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'monitoringIntervalMs': monitoringIntervalMs,
      'enableCpuMonitoring': enableCpuMonitoring,
      'enableMemoryMonitoring': enableMemoryMonitoring,
      'enableStorageMonitoring': enableStorageMonitoring,
      'enableNetworkMonitoring': enableNetworkMonitoring,
      'enableGpuMonitoring': enableGpuMonitoring,
      'enableBatteryMonitoring': enableBatteryMonitoring,
      'thresholds': {
        for (final entry in thresholds.entries)
          entry.key.name: entry.value.toMap(),
      },
    };
  }
}

/// 资源监控服务
class ResourceMonitoringService {
  /// 配置
  ResourceMonitoringConfig _config;
  
  /// 定时器
  Timer? _monitoringTimer;
  
  /// 资源使用数据流控制器
  final StreamController<ResourceUsageData> _usageController =
      StreamController<ResourceUsageData>.broadcast();
  
  /// 资源警告流控制器
  final StreamController<ResourceUsageData> _warningController =
      StreamController<ResourceUsageData>.broadcast();
  
  /// 最新资源使用数据
  final Map<ResourceType, ResourceUsageData> _latestUsageData = {};
  
  /// 历史资源使用数据
  final Map<ResourceType, List<ResourceUsageData>> _historicalUsageData = {
    for (final type in ResourceType.values) type: [],
  };
  
  /// 历史数据最大长度
  final int _maxHistoricalDataLength = 100;
  
  /// 资源使用数据流
  Stream<ResourceUsageData> get usageStream => _usageController.stream;
  
  /// 资源警告流
  Stream<ResourceUsageData> get warningStream => _warningController.stream;
  
  /// 构造函数
  ResourceMonitoringService({
    ResourceMonitoringConfig? config,
  }) : _config = config ?? ResourceMonitoringConfig();
  
  /// 初始化
  Future<void> initialize() async {
    // 停止现有的监控
    await stop();
    
    // 开始监控
    _startMonitoring();
  }
  
  /// 开始监控
  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(
      Duration(milliseconds: _config.monitoringIntervalMs),
      (_) => _collectResourceUsage(),
    );
  }
  
  /// 停止监控
  Future<void> stop() async {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }
  
  /// 收集资源使用情况
  Future<void> _collectResourceUsage() async {
    try {
      // 收集CPU使用情况
      if (_config.enableCpuMonitoring) {
        final cpuUsage = await _collectCpuUsage();
        _processUsageData(cpuUsage);
      }
      
      // 收集内存使用情况
      if (_config.enableMemoryMonitoring) {
        final memoryUsage = await _collectMemoryUsage();
        _processUsageData(memoryUsage);
      }
      
      // 收集存储使用情况
      if (_config.enableStorageMonitoring) {
        final storageUsage = await _collectStorageUsage();
        _processUsageData(storageUsage);
      }
      
      // 收集网络使用情况
      if (_config.enableNetworkMonitoring) {
        final networkUsage = await _collectNetworkUsage();
        _processUsageData(networkUsage);
      }
      
      // 收集GPU使用情况
      if (_config.enableGpuMonitoring) {
        final gpuUsage = await _collectGpuUsage();
        _processUsageData(gpuUsage);
      }
      
      // 收集电池使用情况
      if (_config.enableBatteryMonitoring) {
        final batteryUsage = await _collectBatteryUsage();
        _processUsageData(batteryUsage);
      }
    } catch (e) {
      print('收集资源使用情况时出错: $e');
    }
  }
  
  /// 处理使用数据
  void _processUsageData(ResourceUsageData data) {
    // 更新最新数据
    _latestUsageData[data.type] = data;
    
    // 添加到历史数据
    final historicalData = _historicalUsageData[data.type]!;
    historicalData.add(data);
    
    // 限制历史数据长度
    if (historicalData.length > _maxHistoricalDataLength) {
      historicalData.removeAt(0);
    }
    
    // 发送到流
    _usageController.add(data);
    
    // 检查是否需要发送警告
    if (data.state == ResourceUsageState.warning || 
        data.state == ResourceUsageState.danger) {
      _warningController.add(data);
    }
  }
  
  /// 获取最新资源使用数据
  ResourceUsageData? getLatestUsageData(ResourceType type) {
    return _latestUsageData[type];
  }
  
  /// 获取历史资源使用数据
  List<ResourceUsageData> getHistoricalUsageData(
    ResourceType type, {
    int? limit,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final data = _historicalUsageData[type] ?? [];
    
    // 过滤数据
    var filteredData = data;
    
    if (startTime != null) {
      filteredData = filteredData
          .where((item) => item.timestamp.isAfter(startTime))
          .toList();
    }
    
    if (endTime != null) {
      filteredData = filteredData
          .where((item) => item.timestamp.isBefore(endTime))
          .toList();
    }
    
    // 限制数量
    if (limit != null && filteredData.length > limit) {
      filteredData = filteredData.sublist(filteredData.length - limit);
    }
    
    return filteredData;
  }
  
  /// 获取所有资源的最新使用数据
  Map<ResourceType, ResourceUsageData> getAllLatestUsageData() {
    return Map<ResourceType, ResourceUsageData>.from(_latestUsageData);
  }
  
  /// 更新配置
  Future<void> updateConfig(ResourceMonitoringConfig config) async {
    _config = config;
    
    // 重新启动监控
    await stop();
    _startMonitoring();
  }
  
  /// 获取当前配置
  ResourceMonitoringConfig getConfig() {
    return _config;
  }
  
  /// 收集CPU使用情况
  Future<ResourceUsageData> _collectCpuUsage() async {
    try {
      // 在实际应用中，这里应该使用平台特定的方法获取CPU使用情况
      // 这里使用模拟数据
      final usagePercentage = 30.0 + (DateTime.now().millisecondsSinceEpoch % 50);
      final total = 100.0;
      final used = usagePercentage;
      final available = total - used;
      
      // 确定状态
      final thresholds = _config.thresholds[ResourceType.cpu]!;
      final state = _determineState(usagePercentage, thresholds);
      
      return ResourceUsageData(
        type: ResourceType.cpu,
        usagePercentage: usagePercentage,
        total: total,
        used: used,
        available: available,
        state: state,
        details: {
          'cores': Platform.numberOfProcessors,
          'architecture': Platform.operatingSystemVersion,
        },
      );
    } catch (e) {
      print('收集CPU使用情况时出错: $e');
      return ResourceUsageData(
        type: ResourceType.cpu,
        usagePercentage: 0.0,
        total: 100.0,
        used: 0.0,
        available: 100.0,
        state: ResourceUsageState.unknown,
        details: {'error': e.toString()},
      );
    }
  }
  
  /// 收集内存使用情况
  Future<ResourceUsageData> _collectMemoryUsage() async {
    try {
      // 在实际应用中，这里应该使用平台特定的方法获取内存使用情况
      // 这里使用模拟数据
      final usagePercentage = 40.0 + (DateTime.now().millisecondsSinceEpoch % 30);
      final total = 16.0 * 1024; // 16 GB in MB
      final used = total * usagePercentage / 100;
      final available = total - used;
      
      // 确定状态
      final thresholds = _config.thresholds[ResourceType.memory]!;
      final state = _determineState(usagePercentage, thresholds);
      
      return ResourceUsageData(
        type: ResourceType.memory,
        usagePercentage: usagePercentage,
        total: total,
        used: used,
        available: available,
        state: state,
        details: {
          'unit': 'MB',
          'appUsage': used * 0.1, // 应用使用的内存
        },
      );
    } catch (e) {
      print('收集内存使用情况时出错: $e');
      return ResourceUsageData(
        type: ResourceType.memory,
        usagePercentage: 0.0,
        total: 100.0,
        used: 0.0,
        available: 100.0,
        state: ResourceUsageState.unknown,
        details: {'error': e.toString()},
      );
    }
  }
  
  /// 收集存储使用情况
  Future<ResourceUsageData> _collectStorageUsage() async {
    try {
      // 在实际应用中，这里应该使用平台特定的方法获取存储使用情况
      // 这里使用模拟数据
      final usagePercentage = 60.0 + (DateTime.now().millisecondsSinceEpoch % 20);
      final total = 512.0 * 1024; // 512 GB in MB
      final used = total * usagePercentage / 100;
      final available = total - used;
      
      // 确定状态
      final thresholds = _config.thresholds[ResourceType.storage]!;
      final state = _determineState(usagePercentage, thresholds);
      
      return ResourceUsageData(
        type: ResourceType.storage,
        usagePercentage: usagePercentage,
        total: total,
        used: used,
        available: available,
        state: state,
        details: {
          'unit': 'MB',
          'appStorage': used * 0.05, // 应用使用的存储
        },
      );
    } catch (e) {
      print('收集存储使用情况时出错: $e');
      return ResourceUsageData(
        type: ResourceType.storage,
        usagePercentage: 0.0,
        total: 100.0,
        used: 0.0,
        available: 100.0,
        state: ResourceUsageState.unknown,
        details: {'error': e.toString()},
      );
    }
  }
  
  /// 收集网络使用情况
  Future<ResourceUsageData> _collectNetworkUsage() async {
    try {
      // 在实际应用中，这里应该使用平台特定的方法获取网络使用情况
      // 这里使用模拟数据
      final usagePercentage = 20.0 + (DateTime.now().millisecondsSinceEpoch % 60);
      final total = 100.0; // 带宽百分比
      final used = usagePercentage;
      final available = total - used;
      
      // 确定状态
      final thresholds = _config.thresholds[ResourceType.network]!;
      final state = _determineState(usagePercentage, thresholds);
      
      return ResourceUsageData(
        type: ResourceType.network,
        usagePercentage: usagePercentage,
        total: total,
        used: used,
        available: available,
        state: state,
        details: {
          'downloadSpeed': 10.0 + (DateTime.now().millisecondsSinceEpoch % 50), // Mbps
          'uploadSpeed': 5.0 + (DateTime.now().millisecondsSinceEpoch % 20), // Mbps
          'latency': 20 + (DateTime.now().millisecondsSinceEpoch % 100), // ms
        },
      );
    } catch (e) {
      print('收集网络使用情况时出错: $e');
      return ResourceUsageData(
        type: ResourceType.network,
        usagePercentage: 0.0,
        total: 100.0,
        used: 0.0,
        available: 100.0,
        state: ResourceUsageState.unknown,
        details: {'error': e.toString()},
      );
    }
  }
  
  /// 收集GPU使用情况
  Future<ResourceUsageData> _collectGpuUsage() async {
    try {
      // 在实际应用中，这里应该使用平台特定的方法获取GPU使用情况
      // 这里使用模拟数据
      final usagePercentage = 50.0 + (DateTime.now().millisecondsSinceEpoch % 40);
      final total = 100.0;
      final used = usagePercentage;
      final available = total - used;
      
      // 确定状态
      final thresholds = _config.thresholds[ResourceType.gpu]!;
      final state = _determineState(usagePercentage, thresholds);
      
      return ResourceUsageData(
        type: ResourceType.gpu,
        usagePercentage: usagePercentage,
        total: total,
        used: used,
        available: available,
        state: state,
        details: {
          'temperature': 50 + (DateTime.now().millisecondsSinceEpoch % 30), // °C
          'memoryUsage': 2048 + (DateTime.now().millisecondsSinceEpoch % 1024), // MB
        },
      );
    } catch (e) {
      print('收集GPU使用情况时出错: $e');
      return ResourceUsageData(
        type: ResourceType.gpu,
        usagePercentage: 0.0,
        total: 100.0,
        used: 0.0,
        available: 100.0,
        state: ResourceUsageState.unknown,
        details: {'error': e.toString()},
      );
    }
  }
  
  /// 收集电池使用情况
  Future<ResourceUsageData> _collectBatteryUsage() async {
    try {
      // 在实际应用中，这里应该使用平台特定的方法获取电池使用情况
      // 这里使用模拟数据
      final usagePercentage = 100.0 - (DateTime.now().hour * 4 + DateTime.now().minute / 15);
      final total = 100.0;
      final used = 100.0 - usagePercentage;
      final available = usagePercentage;
      
      // 确定状态
      final thresholds = _config.thresholds[ResourceType.battery]!;
      final state = _determineState(100.0 - usagePercentage, thresholds);
      
      return ResourceUsageData(
        type: ResourceType.battery,
        usagePercentage: 100.0 - usagePercentage, // 电池消耗百分比
        total: total,
        used: used,
        available: available,
        state: state,
        details: {
          'charging': DateTime.now().minute % 2 == 0,
          'temperature': 30 + (DateTime.now().millisecondsSinceEpoch % 10), // °C
          'remainingTime': (available / 10 * 60).round(), // 剩余分钟数
        },
      );
    } catch (e) {
      print('收集电池使用情况时出错: $e');
      return ResourceUsageData(
        type: ResourceType.battery,
        usagePercentage: 0.0,
        total: 100.0,
        used: 0.0,
        available: 100.0,
        state: ResourceUsageState.unknown,
        details: {'error': e.toString()},
      );
    }
  }
  
  /// 确定资源状态
  ResourceUsageState _determineState(
    double usagePercentage,
    ResourceThresholdConfig thresholds,
  ) {
    if (usagePercentage >= thresholds.dangerThreshold) {
      return ResourceUsageState.danger;
    } else if (usagePercentage >= thresholds.warningThreshold) {
      return ResourceUsageState.warning;
    } else {
      return ResourceUsageState.normal;
    }
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    await stop();
    await _usageController.close();
    await _warningController.close();
  }
}

/// 资源监控服务提供者
final resourceMonitoringServiceProvider = Provider<ResourceMonitoringService>((ref) {
  final service = ResourceMonitoringService();
  
  // 初始化服务
  service.initialize();
  
  // 在提供者被释放时关闭服务
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 资源使用数据提供者
final resourceUsageDataProvider = StreamProvider.family<ResourceUsageData, ResourceType>((ref, type) {
  final service = ref.watch(resourceMonitoringServiceProvider);
  
  return service.usageStream.where((data) => data.type == type);
});

/// 资源警告提供者
final resourceWarningProvider = StreamProvider<ResourceUsageData>((ref) {
  final service = ref.watch(resourceMonitoringServiceProvider);
  
  return service.warningStream;
});

/// 所有资源最新使用数据提供者
final allResourceUsageDataProvider = Provider<Map<ResourceType, ResourceUsageData>>((ref) {
  final service = ref.watch(resourceMonitoringServiceProvider);
  
  return service.getAllLatestUsageData();
}); 