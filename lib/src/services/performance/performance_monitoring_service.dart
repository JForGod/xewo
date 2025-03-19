import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/logging_service.dart';
import '../error/error_handling_service.dart';

/// 性能指标类型
enum MetricType {
  /// CPU使用率
  cpuUsage,
  
  /// 内存使用量
  memoryUsage,
  
  /// 帧率
  frameRate,
  
  /// 帧时间
  frameTime,
  
  /// 网络延迟
  networkLatency,
  
  /// 网络带宽
  networkBandwidth,
  
  /// 磁盘使用量
  diskUsage,
  
  /// 磁盘IO
  diskIO,
  
  /// 电池使用量
  batteryUsage,
  
  /// 温度
  temperature,
}

/// 性能数据点
class PerformanceDataPoint {
  /// 时间戳
  final DateTime timestamp;
  
  /// 指标类型
  final MetricType type;
  
  /// 值
  final double value;
  
  /// 单位
  final String unit;
  
  /// 标签
  final Map<String, String> tags;
  
  /// 构造函数
  PerformanceDataPoint({
    DateTime? timestamp,
    required this.type,
    required this.value,
    required this.unit,
    this.tags = const {},
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 从Map创建性能数据点
  factory PerformanceDataPoint.fromMap(Map<String, dynamic> map) {
    return PerformanceDataPoint(
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: MetricType.values.byName(map['type'] as String),
      value: map['value'] as double,
      unit: map['unit'] as String,
      tags: Map<String, String>.from(map['tags'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'value': value,
      'unit': unit,
      'tags': tags,
    };
  }
}

/// 性能阈值配置
class PerformanceThreshold {
  /// 指标类型
  final MetricType type;
  
  /// 警告阈值
  final double warningThreshold;
  
  /// 错误阈值
  final double errorThreshold;
  
  /// 单位
  final String unit;
  
  /// 构造函数
  PerformanceThreshold({
    required this.type,
    required this.warningThreshold,
    required this.errorThreshold,
    required this.unit,
  });
  
  /// 从Map创建性能阈值
  factory PerformanceThreshold.fromMap(Map<String, dynamic> map) {
    return PerformanceThreshold(
      type: MetricType.values.byName(map['type'] as String),
      warningThreshold: map['warningThreshold'] as double,
      errorThreshold: map['errorThreshold'] as double,
      unit: map['unit'] as String,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'warningThreshold': warningThreshold,
      'errorThreshold': errorThreshold,
      'unit': unit,
    };
  }
}

/// 性能监控配置
class PerformanceMonitoringConfig {
  /// 采样间隔（毫秒）
  final int samplingInterval;
  
  /// 数据保留时间（毫秒）
  final int dataRetentionTime;
  
  /// 是否启用CPU监控
  final bool enableCpuMonitoring;
  
  /// 是否启用内存监控
  final bool enableMemoryMonitoring;
  
  /// 是否启用帧率监控
  final bool enableFrameMonitoring;
  
  /// 是否启用网络监控
  final bool enableNetworkMonitoring;
  
  /// 是否启用磁盘监控
  final bool enableDiskMonitoring;
  
  /// 是否启用电池监控
  final bool enableBatteryMonitoring;
  
  /// 是否启用温度监控
  final bool enableTemperatureMonitoring;
  
  /// 性能阈值列表
  final List<PerformanceThreshold> thresholds;
  
  /// 构造函数
  PerformanceMonitoringConfig({
    this.samplingInterval = 1000,
    this.dataRetentionTime = 24 * 60 * 60 * 1000, // 24小时
    this.enableCpuMonitoring = true,
    this.enableMemoryMonitoring = true,
    this.enableFrameMonitoring = true,
    this.enableNetworkMonitoring = true,
    this.enableDiskMonitoring = true,
    this.enableBatteryMonitoring = true,
    this.enableTemperatureMonitoring = true,
    this.thresholds = const [],
  });
  
  /// 从Map创建配置
  factory PerformanceMonitoringConfig.fromMap(Map<String, dynamic> map) {
    return PerformanceMonitoringConfig(
      samplingInterval: map['samplingInterval'] ?? 1000,
      dataRetentionTime: map['dataRetentionTime'] ?? 24 * 60 * 60 * 1000,
      enableCpuMonitoring: map['enableCpuMonitoring'] ?? true,
      enableMemoryMonitoring: map['enableMemoryMonitoring'] ?? true,
      enableFrameMonitoring: map['enableFrameMonitoring'] ?? true,
      enableNetworkMonitoring: map['enableNetworkMonitoring'] ?? true,
      enableDiskMonitoring: map['enableDiskMonitoring'] ?? true,
      enableBatteryMonitoring: map['enableBatteryMonitoring'] ?? true,
      enableTemperatureMonitoring: map['enableTemperatureMonitoring'] ?? true,
      thresholds: (map['thresholds'] as List<dynamic>?)
          ?.map((e) => PerformanceThreshold.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'samplingInterval': samplingInterval,
      'dataRetentionTime': dataRetentionTime,
      'enableCpuMonitoring': enableCpuMonitoring,
      'enableMemoryMonitoring': enableMemoryMonitoring,
      'enableFrameMonitoring': enableFrameMonitoring,
      'enableNetworkMonitoring': enableNetworkMonitoring,
      'enableDiskMonitoring': enableDiskMonitoring,
      'enableBatteryMonitoring': enableBatteryMonitoring,
      'enableTemperatureMonitoring': enableTemperatureMonitoring,
      'thresholds': thresholds.map((e) => e.toMap()).toList(),
    };
  }
}

/// 性能监控服务
class PerformanceMonitoringService {
  /// 配置
  PerformanceMonitoringConfig _config;
  
  /// 日志服务
  final LoggingService _loggingService;
  
  /// 错误处理服务
  final ErrorHandlingService _errorHandlingService;
  
  /// 性能数据点流控制器
  final StreamController<PerformanceDataPoint> _dataController =
      StreamController<PerformanceDataPoint>.broadcast();
  
  /// 性能数据点流
  Stream<PerformanceDataPoint> get dataStream => _dataController.stream;
  
  /// 定时器
  Timer? _timer;
  
  /// 性能数据缓存
  final Map<MetricType, List<PerformanceDataPoint>> _dataCache = {};
  
  /// 构造函数
  PerformanceMonitoringService({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    PerformanceMonitoringConfig? config,
  })  : _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _config = config ?? PerformanceMonitoringConfig() {
    _initializeMonitoring();
  }
  
  /// 初始化监控
  void _initializeMonitoring() {
    // 停止现有定时器
    _timer?.cancel();
    
    // 创建新定时器
    _timer = Timer.periodic(
      Duration(milliseconds: _config.samplingInterval),
      (_) => _collectMetrics(),
    );
  }
  
  /// 收集指标
  Future<void> _collectMetrics() async {
    try {
      if (_config.enableCpuMonitoring) {
        await _collectCpuMetrics();
      }
      
      if (_config.enableMemoryMonitoring) {
        await _collectMemoryMetrics();
      }
      
      if (_config.enableFrameMonitoring) {
        await _collectFrameMetrics();
      }
      
      if (_config.enableNetworkMonitoring) {
        await _collectNetworkMetrics();
      }
      
      if (_config.enableDiskMonitoring) {
        await _collectDiskMetrics();
      }
      
      if (_config.enableBatteryMonitoring) {
        await _collectBatteryMetrics();
      }
      
      if (_config.enableTemperatureMonitoring) {
        await _collectTemperatureMetrics();
      }
      
      // 清理过期数据
      _cleanupOldData();
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '性能指标收集失败',
      );
    }
  }
  
  /// 收集CPU指标
  Future<void> _collectCpuMetrics() async {
    // TODO: 实现CPU指标收集
    final dataPoint = PerformanceDataPoint(
      type: MetricType.cpuUsage,
      value: 0.0, // 替换为实际值
      unit: '%',
    );
    
    _addDataPoint(dataPoint);
  }
  
  /// 收集内存指标
  Future<void> _collectMemoryMetrics() async {
    // TODO: 实现内存指标收集
    final dataPoint = PerformanceDataPoint(
      type: MetricType.memoryUsage,
      value: 0.0, // 替换为实际值
      unit: 'MB',
    );
    
    _addDataPoint(dataPoint);
  }
  
  /// 收集帧率指标
  Future<void> _collectFrameMetrics() async {
    // TODO: 实现帧率指标收集
    final dataPoint = PerformanceDataPoint(
      type: MetricType.frameRate,
      value: 0.0, // 替换为实际值
      unit: 'FPS',
    );
    
    _addDataPoint(dataPoint);
  }
  
  /// 收集网络指标
  Future<void> _collectNetworkMetrics() async {
    // TODO: 实现网络指标收集
    final latencyPoint = PerformanceDataPoint(
      type: MetricType.networkLatency,
      value: 0.0, // 替换为实际值
      unit: 'ms',
    );
    
    final bandwidthPoint = PerformanceDataPoint(
      type: MetricType.networkBandwidth,
      value: 0.0, // 替换为实际值
      unit: 'MB/s',
    );
    
    _addDataPoint(latencyPoint);
    _addDataPoint(bandwidthPoint);
  }
  
  /// 收集磁盘指标
  Future<void> _collectDiskMetrics() async {
    // TODO: 实现磁盘指标收集
    final usagePoint = PerformanceDataPoint(
      type: MetricType.diskUsage,
      value: 0.0, // 替换为实际值
      unit: '%',
    );
    
    final ioPoint = PerformanceDataPoint(
      type: MetricType.diskIO,
      value: 0.0, // 替换为实际值
      unit: 'MB/s',
    );
    
    _addDataPoint(usagePoint);
    _addDataPoint(ioPoint);
  }
  
  /// 收集电池指标
  Future<void> _collectBatteryMetrics() async {
    // TODO: 实现电池指标收集
    final dataPoint = PerformanceDataPoint(
      type: MetricType.batteryUsage,
      value: 0.0, // 替换为实际值
      unit: '%',
    );
    
    _addDataPoint(dataPoint);
  }
  
  /// 收集温度指标
  Future<void> _collectTemperatureMetrics() async {
    // TODO: 实现温度指标收集
    final dataPoint = PerformanceDataPoint(
      type: MetricType.temperature,
      value: 0.0, // 替换为实际值
      unit: '°C',
    );
    
    _addDataPoint(dataPoint);
  }
  
  /// 添加数据点
  void _addDataPoint(PerformanceDataPoint point) {
    // 添加到缓存
    _dataCache.putIfAbsent(point.type, () => []).add(point);
    
    // 发送到流
    _dataController.add(point);
    
    // 检查阈值
    _checkThresholds(point);
  }
  
  /// 检查阈值
  void _checkThresholds(PerformanceDataPoint point) {
    final threshold = _config.thresholds
        .firstWhere((t) => t.type == point.type, orElse: () => null);
    
    if (threshold != null) {
      if (point.value >= threshold.errorThreshold) {
        _errorHandlingService.handleError(
          '性能指标超出错误阈值',
          null,
          type: ErrorType.system,
          severity: ErrorSeverity.high,
          message:
              '${point.type.name} = ${point.value} ${point.unit} >= ${threshold.errorThreshold} ${threshold.unit}',
        );
      } else if (point.value >= threshold.warningThreshold) {
        _loggingService.warning(
          '性能指标超出警告阈值',
          tags: {
            'metric_type': point.type.name,
            'value': point.value.toString(),
            'unit': point.unit,
            'threshold': threshold.warningThreshold.toString(),
          },
        );
      }
    }
  }
  
  /// 清理过期数据
  void _cleanupOldData() {
    final now = DateTime.now();
    final cutoff = now.subtract(
      Duration(milliseconds: _config.dataRetentionTime),
    );
    
    for (final type in _dataCache.keys) {
      _dataCache[type]?.removeWhere((point) => point.timestamp.isBefore(cutoff));
    }
  }
  
  /// 获取指标数据
  List<PerformanceDataPoint> getMetricData(
    MetricType type, {
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final data = _dataCache[type] ?? [];
    
    if (startTime == null && endTime == null) {
      return List.from(data);
    }
    
    return data.where((point) {
      if (startTime != null && point.timestamp.isBefore(startTime)) {
        return false;
      }
      if (endTime != null && point.timestamp.isAfter(endTime)) {
        return false;
      }
      return true;
    }).toList();
  }
  
  /// 更新配置
  void updateConfig(PerformanceMonitoringConfig config) {
    _config = config;
    _initializeMonitoring();
  }
  
  /// 获取当前配置
  PerformanceMonitoringConfig getConfig() {
    return _config;
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    _timer?.cancel();
    await _dataController.close();
  }
}

/// 性能监控服务提供者
final performanceMonitoringServiceProvider =
    Provider<PerformanceMonitoringService>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final service = PerformanceMonitoringService(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 性能数据点流提供者
final performanceDataStreamProvider =
    StreamProvider<PerformanceDataPoint>((ref) {
  final service = ref.watch(performanceMonitoringServiceProvider);
  return service.dataStream;
}); 