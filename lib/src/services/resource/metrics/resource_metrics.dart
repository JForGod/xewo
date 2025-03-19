import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../resource_monitoring_service.dart';

/// 指标类型
enum MetricType {
  /// 计数器
  counter,
  
  /// 仪表
  gauge,
  
  /// 直方图
  histogram,
  
  /// 摘要
  summary,
}

/// 指标值
class MetricValue {
  /// 时间戳
  final DateTime timestamp;
  
  /// 值
  final double value;
  
  /// 标签
  final Map<String, String> labels;
  
  /// 构造函数
  MetricValue({
    DateTime? timestamp,
    required this.value,
    this.labels = const {},
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 从Map创建指标值
  factory MetricValue.fromMap(Map<String, dynamic> map) {
    return MetricValue(
      timestamp: DateTime.parse(map['timestamp'] as String),
      value: map['value'] as double,
      labels: Map<String, String>.from(map['labels'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'labels': labels,
    };
  }
}

/// 指标定义
class MetricDefinition {
  /// 名称
  final String name;
  
  /// 描述
  final String description;
  
  /// 类型
  final MetricType type;
  
  /// 单位
  final String unit;
  
  /// 标签键
  final List<String> labelKeys;
  
  /// 构造函数
  MetricDefinition({
    required this.name,
    required this.description,
    required this.type,
    required this.unit,
    this.labelKeys = const [],
  });
  
  /// 从Map创建指标定义
  factory MetricDefinition.fromMap(Map<String, dynamic> map) {
    return MetricDefinition(
      name: map['name'] as String,
      description: map['description'] as String,
      type: MetricType.values.byName(map['type'] as String),
      unit: map['unit'] as String,
      labelKeys: List<String>.from(map['labelKeys'] ?? []),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'unit': unit,
      'labelKeys': labelKeys,
    };
  }
}

/// 指标
class Metric {
  /// 定义
  final MetricDefinition definition;
  
  /// 值列表
  final List<MetricValue> values;
  
  /// 构造函数
  Metric({
    required this.definition,
    List<MetricValue>? values,
  }) : values = values ?? [];
  
  /// 从Map创建指标
  factory Metric.fromMap(Map<String, dynamic> map) {
    return Metric(
      definition: MetricDefinition.fromMap(map['definition']),
      values: (map['values'] as List<dynamic>)
        .map((e) => MetricValue.fromMap(e as Map<String, dynamic>))
        .toList(),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'definition': definition.toMap(),
      'values': values.map((e) => e.toMap()).toList(),
    };
  }
  
  /// 添加值
  void addValue(double value, [Map<String, String>? labels]) {
    values.add(MetricValue(
      value: value,
      labels: labels ?? {},
    ));
  }
  
  /// 获取最新值
  MetricValue? getLatestValue() {
    if (values.isEmpty) return null;
    return values.last;
  }
  
  /// 获取指定时间范围内的值
  List<MetricValue> getValuesBetween(DateTime start, DateTime end) {
    return values.where((v) => 
      v.timestamp.isAfter(start) && v.timestamp.isBefore(end)
    ).toList();
  }
  
  /// 获取指定标签的值
  List<MetricValue> getValuesWithLabels(Map<String, String> labels) {
    return values.where((v) => 
      labels.entries.every((e) => v.labels[e.key] == e.value)
    ).toList();
  }
  
  /// 计算平均值
  double? calculateAverage([DateTime? start, DateTime? end]) {
    final filteredValues = start != null && end != null
      ? getValuesBetween(start, end)
      : values;
    
    if (filteredValues.isEmpty) return null;
    
    final sum = filteredValues.fold<double>(
      0, (sum, v) => sum + v.value
    );
    
    return sum / filteredValues.length;
  }
  
  /// 计算最大值
  double? calculateMax([DateTime? start, DateTime? end]) {
    final filteredValues = start != null && end != null
      ? getValuesBetween(start, end)
      : values;
    
    if (filteredValues.isEmpty) return null;
    
    return filteredValues.map((v) => v.value).reduce(
      (a, b) => a > b ? a : b
    );
  }
  
  /// 计算最小值
  double? calculateMin([DateTime? start, DateTime? end]) {
    final filteredValues = start != null && end != null
      ? getValuesBetween(start, end)
      : values;
    
    if (filteredValues.isEmpty) return null;
    
    return filteredValues.map((v) => v.value).reduce(
      (a, b) => a < b ? a : b
    );
  }
  
  /// 计算百分位数
  double? calculatePercentile(
    double percentile, [
    DateTime? start,
    DateTime? end,
  ]) {
    if (percentile < 0 || percentile > 100) {
      throw ArgumentError('百分位数必须在0到100之间');
    }
    
    final filteredValues = start != null && end != null
      ? getValuesBetween(start, end)
      : values;
    
    if (filteredValues.isEmpty) return null;
    
    // 排序值
    final sortedValues = filteredValues.map((v) => v.value).toList()..sort();
    
    // 计算索引
    final index = (percentile / 100 * (sortedValues.length - 1)).round();
    
    return sortedValues[index];
  }
}

/// 资源指标服务
class ResourceMetricsService {
  /// 资源监控服务
  final ResourceMonitoringService _monitoringService;
  
  /// 指标映射
  final Map<String, Metric> _metrics = {};
  
  /// 指标流控制器
  final StreamController<Metric> _metricController =
      StreamController<Metric>.broadcast();
  
  /// 指标流
  Stream<Metric> get metricStream => _metricController.stream;
  
  /// 构造函数
  ResourceMetricsService({
    required ResourceMonitoringService monitoringService,
  }) : _monitoringService = monitoringService {
    // 初始化默认指标
    _initializeDefaultMetrics();
    
    // 监听资源使用数据
    _monitoringService.usageStream.listen(_handleResourceUsage);
  }
  
  /// 初始化默认指标
  void _initializeDefaultMetrics() {
    // CPU使用率
    registerMetric(MetricDefinition(
      name: 'cpu_usage',
      description: 'CPU使用率',
      type: MetricType.gauge,
      unit: '%',
      labelKeys: ['core'],
    ));
    
    // 内存使用率
    registerMetric(MetricDefinition(
      name: 'memory_usage',
      description: '内存使用率',
      type: MetricType.gauge,
      unit: '%',
      labelKeys: ['type'],
    ));
    
    // 存储使用率
    registerMetric(MetricDefinition(
      name: 'storage_usage',
      description: '存储使用率',
      type: MetricType.gauge,
      unit: '%',
      labelKeys: ['device'],
    ));
    
    // 网络使用率
    registerMetric(MetricDefinition(
      name: 'network_usage',
      description: '网络使用率',
      type: MetricType.gauge,
      unit: '%',
      labelKeys: ['interface'],
    ));
    
    // GPU使用率
    registerMetric(MetricDefinition(
      name: 'gpu_usage',
      description: 'GPU使用率',
      type: MetricType.gauge,
      unit: '%',
      labelKeys: ['device'],
    ));
    
    // 电池使用率
    registerMetric(MetricDefinition(
      name: 'battery_usage',
      description: '电池使用率',
      type: MetricType.gauge,
      unit: '%',
      labelKeys: ['status'],
    ));
  }
  
  /// 处理资源使用数据
  void _handleResourceUsage(ResourceUsageData data) {
    switch (data.type) {
      case ResourceType.cpu:
        recordMetric(
          'cpu_usage',
          data.usagePercentage,
          {'core': 'all'},
        );
        break;
      case ResourceType.memory:
        recordMetric(
          'memory_usage',
          data.usagePercentage,
          {'type': 'physical'},
        );
        break;
      case ResourceType.storage:
        recordMetric(
          'storage_usage',
          data.usagePercentage,
          {'device': 'main'},
        );
        break;
      case ResourceType.network:
        recordMetric(
          'network_usage',
          data.usagePercentage,
          {'interface': 'all'},
        );
        break;
      case ResourceType.gpu:
        recordMetric(
          'gpu_usage',
          data.usagePercentage,
          {'device': 'main'},
        );
        break;
      case ResourceType.battery:
        recordMetric(
          'battery_usage',
          data.usagePercentage,
          {'status': data.details['charging'] == true ? 'charging' : 'discharging'},
        );
        break;
    }
  }
  
  /// 注册指标
  void registerMetric(MetricDefinition definition) {
    if (!_metrics.containsKey(definition.name)) {
      _metrics[definition.name] = Metric(definition: definition);
    }
  }
  
  /// 记录指标值
  void recordMetric(
    String name,
    double value, [
    Map<String, String>? labels,
  ]) {
    final metric = _metrics[name];
    if (metric == null) {
      throw ArgumentError('指标 $name 未注册');
    }
    
    // 验证标签
    if (labels != null) {
      final invalidLabels = labels.keys
        .where((key) => !metric.definition.labelKeys.contains(key))
        .toList();
      
      if (invalidLabels.isNotEmpty) {
        throw ArgumentError('无效的标签: $invalidLabels');
      }
    }
    
    // 添加值
    metric.addValue(value, labels);
    
    // 发送到流
    _metricController.add(metric);
  }
  
  /// 获取指标
  Metric? getMetric(String name) {
    return _metrics[name];
  }
  
  /// 获取所有指标
  List<Metric> getAllMetrics() {
    return _metrics.values.toList();
  }
  
  /// 获取指标值
  List<MetricValue>? getMetricValues(
    String name, {
    DateTime? start,
    DateTime? end,
    Map<String, String>? labels,
  }) {
    final metric = _metrics[name];
    if (metric == null) return null;
    
    var values = metric.values;
    
    if (start != null && end != null) {
      values = metric.getValuesBetween(start, end);
    }
    
    if (labels != null) {
      values = values.where((v) => 
        labels.entries.every((e) => v.labels[e.key] == e.value)
      ).toList();
    }
    
    return values;
  }
  
  /// 计算指标统计信息
  Map<String, double>? calculateMetricStats(
    String name, {
    DateTime? start,
    DateTime? end,
    Map<String, String>? labels,
  }) {
    final metric = _metrics[name];
    if (metric == null) return null;
    
    var values = metric.values;
    
    if (start != null && end != null) {
      values = metric.getValuesBetween(start, end);
    }
    
    if (labels != null) {
      values = metric.getValuesWithLabels(labels);
    }
    
    if (values.isEmpty) return null;
    
    return {
      'min': values.map((v) => v.value).reduce((a, b) => a < b ? a : b),
      'max': values.map((v) => v.value).reduce((a, b) => a > b ? a : b),
      'avg': values.map((v) => v.value).reduce((a, b) => a + b) / values.length,
      'p50': metric.calculatePercentile(50, start, end) ?? 0,
      'p90': metric.calculatePercentile(90, start, end) ?? 0,
      'p95': metric.calculatePercentile(95, start, end) ?? 0,
      'p99': metric.calculatePercentile(99, start, end) ?? 0,
    };
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    await _metricController.close();
  }
}

/// 资源指标服务提供者
final resourceMetricsServiceProvider = Provider<ResourceMetricsService>((ref) {
  final monitoringService = ref.watch(resourceMonitoringServiceProvider);
  
  final service = ResourceMetricsService(
    monitoringService: monitoringService,
  );
  
  // 在提供者被释放时关闭服务
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 指标流提供者
final metricStreamProvider = StreamProvider.family<Metric, String>((ref, name) {
  final service = ref.watch(resourceMetricsServiceProvider);
  
  return service.metricStream.where((metric) => metric.definition.name == name);
});

/// 指标值提供者
final metricValuesProvider = Provider.family<List<MetricValue>?, Map<String, dynamic>>((ref, params) {
  final service = ref.watch(resourceMetricsServiceProvider);
  
  return service.getMetricValues(
    params['name'] as String,
    start: params['start'] as DateTime?,
    end: params['end'] as DateTime?,
    labels: params['labels'] as Map<String, String>?,
  );
});

/// 指标统计信息提供者
final metricStatsProvider = Provider.family<Map<String, double>?, Map<String, dynamic>>((ref, params) {
  final service = ref.watch(resourceMetricsServiceProvider);
  
  return service.calculateMetricStats(
    params['name'] as String,
    start: params['start'] as DateTime?,
    end: params['end'] as DateTime?,
    labels: params['labels'] as Map<String, String>?,
  );
}); 