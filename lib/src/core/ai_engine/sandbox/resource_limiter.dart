import 'dart:async';
import 'dart:isolate';

/// 资源使用情况
class ResourceUsage {
  /// CPU使用率（0-100）
  final double cpuUsage;
  
  /// 内存使用量（字节）
  final int memoryUsage;
  
  /// 网络带宽使用量（字节/秒）
  final int networkBandwidth;
  
  /// 磁盘使用量（字节）
  final int diskUsage;
  
  /// 创建时间
  final DateTime timestamp;
  
  ResourceUsage({
    this.cpuUsage = 0.0,
    this.memoryUsage = 0,
    this.networkBandwidth = 0,
    this.diskUsage = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 从Map创建
  factory ResourceUsage.fromMap(Map<String, dynamic> map) {
    return ResourceUsage(
      cpuUsage: (map['cpuUsage'] ?? 0.0) as double,
      memoryUsage: (map['memoryUsage'] ?? 0) as int,
      networkBandwidth: (map['networkBandwidth'] ?? 0) as int,
      diskUsage: (map['diskUsage'] ?? 0) as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'networkBandwidth': networkBandwidth,
      'diskUsage': diskUsage,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// 资源限制配置
class ResourceLimits {
  /// 最大CPU使用率（0-100）
  final double maxCpuUsage;
  
  /// 最大内存使用量（字节）
  final int maxMemoryUsage;
  
  /// 最大网络带宽（字节/秒）
  final int maxNetworkBandwidth;
  
  /// 最大磁盘使用量（字节）
  final int maxDiskUsage;
  
  /// 监控间隔（毫秒）
  final int monitoringIntervalMs;
  
  ResourceLimits({
    this.maxCpuUsage = 50.0,
    this.maxMemoryUsage = 100 * 1024 * 1024, // 100MB
    this.maxNetworkBandwidth = 1024 * 1024, // 1MB/s
    this.maxDiskUsage = 1024 * 1024 * 1024, // 1GB
    this.monitoringIntervalMs = 1000,
  });
  
  /// 从Map创建
  factory ResourceLimits.fromMap(Map<String, dynamic> map) {
    return ResourceLimits(
      maxCpuUsage: (map['maxCpuUsage'] ?? 50.0) as double,
      maxMemoryUsage: (map['maxMemoryUsage'] ?? 100 * 1024 * 1024) as int,
      maxNetworkBandwidth: (map['maxNetworkBandwidth'] ?? 1024 * 1024) as int,
      maxDiskUsage: (map['maxDiskUsage'] ?? 1024 * 1024 * 1024) as int,
      monitoringIntervalMs: (map['monitoringIntervalMs'] ?? 1000) as int,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'maxCpuUsage': maxCpuUsage,
      'maxMemoryUsage': maxMemoryUsage,
      'maxNetworkBandwidth': maxNetworkBandwidth,
      'maxDiskUsage': maxDiskUsage,
      'monitoringIntervalMs': monitoringIntervalMs,
    };
  }
}

/// 资源限制器
class ResourceLimiter {
  /// 资源限制配置
  final ResourceLimits limits;
  
  /// 资源使用历史
  final List<ResourceUsage> _usageHistory = [];
  
  /// 最大历史记录数
  final int _maxHistorySize = 100;
  
  /// 监控定时器
  Timer? _monitoringTimer;
  
  /// 资源使用流控制器
  final _usageController = StreamController<ResourceUsage>.broadcast();
  
  /// 资源超限流控制器
  final _limitExceededController = StreamController<String>.broadcast();
  
  /// 构造函数
  ResourceLimiter({
    ResourceLimits? limits,
  }) : limits = limits ?? ResourceLimits();
  
  /// 资源使用流
  Stream<ResourceUsage> get usageStream => _usageController.stream;
  
  /// 资源超限流
  Stream<String> get limitExceededStream => _limitExceededController.stream;
  
  /// 启动监控
  void startMonitoring() {
    if (_monitoringTimer != null) return;
    
    _monitoringTimer = Timer.periodic(
      Duration(milliseconds: limits.monitoringIntervalMs),
      (_) => _monitor(),
    );
  }
  
  /// 停止监控
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }
  
  /// 获取当前资源使用情况
  Future<ResourceUsage> getCurrentUsage() async {
    // TODO: 实现实际的资源使用监控
    // 这里仅作为示例，返回模拟数据
    return ResourceUsage(
      cpuUsage: 30.0,
      memoryUsage: 50 * 1024 * 1024,
      networkBandwidth: 512 * 1024,
      diskUsage: 100 * 1024 * 1024,
    );
  }
  
  /// 检查资源使用是否超限
  void _checkLimits(ResourceUsage usage) {
    if (usage.cpuUsage > limits.maxCpuUsage) {
      _limitExceededController.add('CPU使用率超限: ${usage.cpuUsage}%');
    }
    
    if (usage.memoryUsage > limits.maxMemoryUsage) {
      _limitExceededController.add(
        '内存使用超限: ${usage.memoryUsage ~/ 1024 / 1024}MB',
      );
    }
    
    if (usage.networkBandwidth > limits.maxNetworkBandwidth) {
      _limitExceededController.add(
        '网络带宽超限: ${usage.networkBandwidth ~/ 1024}KB/s',
      );
    }
    
    if (usage.diskUsage > limits.maxDiskUsage) {
      _limitExceededController.add(
        '磁盘使用超限: ${usage.diskUsage ~/ 1024 / 1024}MB',
      );
    }
  }
  
  /// 监控资源使用
  Future<void> _monitor() async {
    try {
      final usage = await getCurrentUsage();
      
      // 添加到历史记录
      _usageHistory.add(usage);
      if (_usageHistory.length > _maxHistorySize) {
        _usageHistory.removeAt(0);
      }
      
      // 发送使用情况
      _usageController.add(usage);
      
      // 检查限制
      _checkLimits(usage);
      
    } catch (e) {
      _limitExceededController.add('监控资源时出错: $e');
    }
  }
  
  /// 获取资源使用历史
  List<ResourceUsage> getUsageHistory() {
    return List.unmodifiable(_usageHistory);
  }
  
  /// 获取资源使用统计
  Map<String, dynamic> getUsageStats() {
    if (_usageHistory.isEmpty) {
      return {
        'avgCpuUsage': 0.0,
        'avgMemoryUsage': 0,
        'avgNetworkBandwidth': 0,
        'avgDiskUsage': 0,
        'maxCpuUsage': 0.0,
        'maxMemoryUsage': 0,
        'maxNetworkBandwidth': 0,
        'maxDiskUsage': 0,
      };
    }
    
    var totalCpu = 0.0;
    var totalMemory = 0;
    var totalNetwork = 0;
    var totalDisk = 0;
    
    var maxCpu = 0.0;
    var maxMemory = 0;
    var maxNetwork = 0;
    var maxDisk = 0;
    
    for (final usage in _usageHistory) {
      totalCpu += usage.cpuUsage;
      totalMemory += usage.memoryUsage;
      totalNetwork += usage.networkBandwidth;
      totalDisk += usage.diskUsage;
      
      maxCpu = usage.cpuUsage > maxCpu ? usage.cpuUsage : maxCpu;
      maxMemory = usage.memoryUsage > maxMemory ? usage.memoryUsage : maxMemory;
      maxNetwork = usage.networkBandwidth > maxNetwork 
          ? usage.networkBandwidth 
          : maxNetwork;
      maxDisk = usage.diskUsage > maxDisk ? usage.diskUsage : maxDisk;
    }
    
    final count = _usageHistory.length;
    
    return {
      'avgCpuUsage': totalCpu / count,
      'avgMemoryUsage': totalMemory ~/ count,
      'avgNetworkBandwidth': totalNetwork ~/ count,
      'avgDiskUsage': totalDisk ~/ count,
      'maxCpuUsage': maxCpu,
      'maxMemoryUsage': maxMemory,
      'maxNetworkBandwidth': maxNetwork,
      'maxDiskUsage': maxDisk,
    };
  }
  
  /// 清理资源
  void dispose() {
    stopMonitoring();
    _usageController.close();
    _limitExceededController.close();
  }
} 