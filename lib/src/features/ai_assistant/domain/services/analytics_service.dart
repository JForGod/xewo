import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/logging/logging_service.dart';
import '../../../../core/services/error/error_handling_service.dart';
import '../models/analytics_event.dart';
import '../models/analytics_metric.dart';
import '../models/analytics_report.dart';

/// 分析服务接口
abstract class AnalyticsService {
  /// 获取分析事件流
  Stream<AnalyticsEvent> get eventStream;
  
  /// 获取分析指标流
  Stream<AnalyticsMetric> get metricStream;
  
  /// 记录事件
  // 2025-03-15 + 记录分析事件功能
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? properties});
  
  /// 记录指标
  // 2025-03-15 + 记录分析指标功能
  Future<void> trackMetric(String metricName, num value, {Map<String, dynamic>? dimensions});
  
  /// 获取分析报告
  // 2025-03-15 + 获取分析报告功能
  Future<AnalyticsReport> getReport(DateTime startTime, DateTime endTime);
  
  /// 获取实时指标
  // 2025-03-15 + 获取实时指标功能
  Future<Map<String, num>> getRealTimeMetrics();
  
  /// 设置用户属性
  // 2025-03-15 + 设置用户属性功能
  Future<void> setUserProperties(Map<String, dynamic> properties);
}

/// 分析服务实现
class AnalyticsServiceImpl implements AnalyticsService {
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  
  /// 事件流控制器
  final StreamController<AnalyticsEvent> _eventController = 
      StreamController<AnalyticsEvent>.broadcast();
      
  /// 指标流控制器
  final StreamController<AnalyticsMetric> _metricController = 
      StreamController<AnalyticsMetric>.broadcast();
  
  /// 用户属性
  Map<String, dynamic> _userProperties = {};
  
  /// 指标缓存
  final Map<String, List<AnalyticsMetric>> _metricCache = {};
  
  /// 事件缓存
  final List<AnalyticsEvent> _eventCache = [];
  
  /// 缓存大小限制
  static const int _maxCacheSize = 1000;
  
  /// 构造函数
  AnalyticsServiceImpl({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
  }) : _loggingService = loggingService,
       _errorHandlingService = errorHandlingService {
    _initializeService();
  }
  
  // 2025-03-15 + 初始化服务功能
  void _initializeService() {
    _startPeriodicCleanup();
    _startMetricAggregation();
  }
  
  @override
  Stream<AnalyticsEvent> get eventStream => _eventController.stream;
  
  @override
  Stream<AnalyticsMetric> get metricStream => _metricController.stream;
  
  @override
  // 2025-03-15 + 记录分析事件功能
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? properties}) async {
    try {
      final event = AnalyticsEvent(
        name: eventName,
        timestamp: DateTime.now(),
        properties: properties ?? {},
        userProperties: Map.from(_userProperties),
      );
      
      // 添加到缓存
      _eventCache.add(event);
      if (_eventCache.length > _maxCacheSize) {
        _eventCache.removeAt(0);
      }
      
      // 发送到流
      _eventController.add(event);
      
      _loggingService.info('记录分析事件', tags: {
        'event_name': eventName,
        'properties': properties?.toString() ?? '{}',
      });
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '记录分析事件失败',
      );
    }
  }
  
  @override
  // 2025-03-15 + 记录分析指标功能
  Future<void> trackMetric(String metricName, num value, {Map<String, dynamic>? dimensions}) async {
    try {
      final metric = AnalyticsMetric(
        name: metricName,
        value: value,
        timestamp: DateTime.now(),
        dimensions: dimensions ?? {},
      );
      
      // 添加到缓存
      if (!_metricCache.containsKey(metricName)) {
        _metricCache[metricName] = [];
      }
      
      _metricCache[metricName]!.add(metric);
      
      // 限制缓存大小
      if (_metricCache[metricName]!.length > _maxCacheSize) {
        _metricCache[metricName]!.removeAt(0);
      }
      
      // 发送到流
      _metricController.add(metric);
      
      _loggingService.info('记录分析指标', tags: {
        'metric_name': metricName,
        'value': value.toString(),
        'dimensions': dimensions?.toString() ?? '{}',
      });
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '记录分析指标失败',
      );
    }
  }
  
  @override
  // 2025-03-15 + 获取分析报告功能
  Future<AnalyticsReport> getReport(DateTime startTime, DateTime endTime) async {
    try {
      // 过滤时间范围内的事件
      final events = _eventCache.where((event) =>
        event.timestamp.isAfter(startTime) &&
        event.timestamp.isBefore(endTime)
      ).toList();
      
      // 聚合指标
      final metrics = <String, List<AnalyticsMetric>>{};
      _metricCache.forEach((key, value) {
        metrics[key] = value.where((metric) =>
          metric.timestamp.isAfter(startTime) &&
          metric.timestamp.isBefore(endTime)
        ).toList();
      });
      
      // 生成报告
      return AnalyticsReport(
        startTime: startTime,
        endTime: endTime,
        events: events,
        metrics: metrics,
        summary: await _generateReportSummary(events, metrics),
      );
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '获取分析报告失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-15 + 获取实时指标功能
  Future<Map<String, num>> getRealTimeMetrics() async {
    try {
      final realTimeMetrics = <String, num>{};
      
      // 计算每个指标的最新值
      _metricCache.forEach((key, metrics) {
        if (metrics.isNotEmpty) {
          realTimeMetrics[key] = _calculateLatestMetricValue(metrics);
        }
      });
      
      return realTimeMetrics;
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '获取实时指标失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-15 + 设置用户属性功能
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      _userProperties = Map.from(properties);
      
      _loggingService.info('更新用户属性', tags: {
        'properties': properties.toString(),
      });
      
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '设置用户属性失败',
      );
    }
  }
  
  // 2025-03-15 + 生成报告摘要功能
  Future<Map<String, dynamic>> _generateReportSummary(
    List<AnalyticsEvent> events,
    Map<String, List<AnalyticsMetric>> metrics,
  ) async {
    final summary = <String, dynamic>{};
    
    // 事件统计
    summary['total_events'] = events.length;
    summary['event_types'] = events.map((e) => e.name).toSet().length;
    
    // 指标统计
    summary['metrics'] = {};
    metrics.forEach((key, values) {
      summary['metrics'][key] = {
        'count': values.length,
        'min': values.map((m) => m.value).reduce(min),
        'max': values.map((m) => m.value).reduce(max),
        'avg': values.map((m) => m.value).reduce((a, b) => a + b) / values.length,
      };
    });
    
    return summary;
  }
  
  // 2025-03-15 + 计算最新指标值功能
  num _calculateLatestMetricValue(List<AnalyticsMetric> metrics) {
    // 按时间排序
    metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // 返回最新值
    return metrics.first.value;
  }
  
  // 2025-03-15 + 启动定期清理功能
  void _startPeriodicCleanup() {
    Timer.periodic(Duration(hours: 1), (_) {
      _cleanupOldData();
    });
  }
  
  // 2025-03-15 + 启动指标聚合功能
  void _startMetricAggregation() {
    Timer.periodic(Duration(minutes: 5), (_) {
      _aggregateMetrics();
    });
  }
  
  // 2025-03-15 + 清理旧数据功能
  void _cleanupOldData() {
    final threshold = DateTime.now().subtract(Duration(days: 7));
    
    // 清理事件缓存
    _eventCache.removeWhere((event) => 
      event.timestamp.isBefore(threshold));
    
    // 清理指标缓存
    _metricCache.forEach((key, metrics) {
      metrics.removeWhere((metric) =>
        metric.timestamp.isBefore(threshold));
    });
  }
  
  // 2025-03-15 + 聚合指标功能
  void _aggregateMetrics() {
    _metricCache.forEach((key, metrics) {
      if (metrics.length > 100) {
        // 按时间分组
        final groups = <DateTime, List<AnalyticsMetric>>{};
        
        for (final metric in metrics) {
          final timeKey = DateTime(
            metric.timestamp.year,
            metric.timestamp.month,
            metric.timestamp.day,
            metric.timestamp.hour,
          );
          
          if (!groups.containsKey(timeKey)) {
            groups[timeKey] = [];
          }
          groups[timeKey]!.add(metric);
        }
        
        // 聚合每个时间组
        final aggregatedMetrics = groups.entries.map((entry) {
          final values = entry.value.map((m) => m.value);
          return AnalyticsMetric(
            name: key,
            value: values.reduce((a, b) => a + b) / values.length,
            timestamp: entry.key,
            dimensions: {'aggregated': true},
          );
        }).toList();
        
        // 更新缓存
        _metricCache[key] = aggregatedMetrics;
      }
    });
  }
  
  // 2025-03-15 + 释放资源功能
  void dispose() {
    _eventController.close();
    _metricController.close();
  }
}

/// 分析服务提供者
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final service = AnalyticsServiceImpl(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    if (service is AnalyticsServiceImpl) {
      service.dispose();
    }
  });
  
  return service;
});

/// 分析事件流提供者
final analyticsEventStreamProvider = StreamProvider<AnalyticsEvent>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.eventStream;
});

/// 分析指标流提供者
final analyticsMetricStreamProvider = StreamProvider<AnalyticsMetric>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.metricStream;
});
