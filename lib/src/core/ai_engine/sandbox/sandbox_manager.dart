import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'security_policy.dart';
import 'resource_limiter.dart';

/// 沙盒类型
enum SandboxType {
  /// 代码执行沙盒
  codeExecution,
  
  /// 文件操作沙盒
  fileOperation,
  
  /// 网络请求沙盒
  networkRequest,
  
  /// 系统调用沙盒
  systemCall,
  
  /// 数据处理沙盒
  dataProcessing,
}

/// 沙盒状态
enum SandboxStatus {
  /// 初始化
  initializing,
  
  /// 运行中
  running,
  
  /// 暂停
  paused,
  
  /// 停止
  stopped,
  
  /// 错误
  error,
}

/// 安全事件类型
enum SecurityEventType {
  /// 权限违规
  permissionViolation,
  
  /// 资源超限
  resourceExceeded,
  
  /// 非法操作
  illegalOperation,
  
  /// 安全策略违反
  policyViolation,
  
  /// 可疑行为
  suspiciousActivity,
}

/// 安全事件严重程度
enum SecurityEventSeverity {
  /// 低
  low,
  
  /// 中
  medium,
  
  /// 高
  high,
  
  /// 严重
  critical,
}

/// 沙盒数据
class SandboxData {
  /// 沙盒ID
  final String id;
  
  /// 沙盒类型
  final SandboxType type;
  
  /// 沙盒状态
  final SandboxStatus status;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后活动时间
  final DateTime lastActivityAt;
  
  /// 安全策略
  final SecurityPolicy securityPolicy;
  
  /// 资源限制器
  final ResourceLimiter resourceLimiter;
  
  /// 元数据
  final Map<String, dynamic> metadata;
  
  /// 构造函数
  SandboxData({
    required this.id,
    required this.type,
    required this.status,
    required this.securityPolicy,
    required this.resourceLimiter,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    this.metadata = const {},
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActivityAt = lastActivityAt ?? DateTime.now();
  
  /// 从Map创建沙盒数据
  factory SandboxData.fromMap(Map<String, dynamic> map) {
    return SandboxData(
      id: map['id'],
      type: SandboxType.values.byName(map['type']),
      status: SandboxStatus.values.byName(map['status']),
      securityPolicy: SecurityPolicy.fromMap(map['securityPolicy']),
      resourceLimiter: ResourceLimiter.fromMap(map['resourceLimiter']),
      createdAt: DateTime.parse(map['createdAt']),
      lastActivityAt: DateTime.parse(map['lastActivityAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'status': status.name,
      'securityPolicy': securityPolicy.toMap(),
      'resourceLimiter': resourceLimiter.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'metadata': metadata,
    };
  }
  
  /// 复制并修改
  SandboxData copyWith({
    SandboxStatus? status,
    SecurityPolicy? securityPolicy,
    ResourceLimiter? resourceLimiter,
    DateTime? lastActivityAt,
    Map<String, dynamic>? metadata,
  }) {
    return SandboxData(
      id: id,
      type: type,
      status: status ?? this.status,
      securityPolicy: securityPolicy ?? this.securityPolicy,
      resourceLimiter: resourceLimiter ?? this.resourceLimiter,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 安全事件
class SecurityEvent {
  /// 事件ID
  final String id;
  
  /// 事件类型
  final SecurityEventType type;
  
  /// 严重程度
  final SecurityEventSeverity severity;
  
  /// 沙盒ID
  final String sandboxId;
  
  /// 事件描述
  final String description;
  
  /// 发生时间
  final DateTime timestamp;
  
  /// 相关数据
  final Map<String, dynamic> data;
  
  /// 构造函数
  SecurityEvent({
    required this.id,
    required this.type,
    required this.severity,
    required this.sandboxId,
    required this.description,
    DateTime? timestamp,
    this.data = const {},
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 从Map创建安全事件
  factory SecurityEvent.fromMap(Map<String, dynamic> map) {
    return SecurityEvent(
      id: map['id'],
      type: SecurityEventType.values.byName(map['type']),
      severity: SecurityEventSeverity.values.byName(map['severity']),
      sandboxId: map['sandboxId'],
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'sandboxId': sandboxId,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

/// 沙盒管理器
class SandboxManager {
  /// 活动沙盒
  final Map<String, SandboxData> _activeSandboxes = {};
  
  /// 安全事件历史
  final List<SecurityEvent> _securityEvents = [];
  
  /// 沙盒状态变化控制器
  final StreamController<SandboxData> _sandboxStateController = 
      StreamController<SandboxData>.broadcast();
  
  /// 安全事件控制器
  final StreamController<SecurityEvent> _securityEventController = 
      StreamController<SecurityEvent>.broadcast();
  
  /// 沙盒状态变化流
  Stream<SandboxData> get sandboxStateChanges => _sandboxStateController.stream;
  
  /// 安全事件流
  Stream<SecurityEvent> get securityEvents => _securityEventController.stream;
  
  /// 构造函数
  SandboxManager();
  
  /// 创建沙盒
  Future<SandboxData> createSandbox(
    SandboxType type, {
    SecurityPolicy? securityPolicy,
    ResourceLimiter? resourceLimiter,
    Map<String, dynamic> metadata = const {},
  }) async {
    final id = _generateId();
    
    final sandbox = SandboxData(
      id: id,
      type: type,
      status: SandboxStatus.initializing,
      securityPolicy: securityPolicy ?? SecurityPolicy(),
      resourceLimiter: resourceLimiter ?? ResourceLimiter(),
      metadata: metadata,
    );
    
    _activeSandboxes[id] = sandbox;
    _sandboxStateController.add(sandbox);
    
    // 启动沙盒
    await _startSandbox(sandbox);
    
    return sandbox;
  }
  
  /// 获取沙盒
  SandboxData? getSandbox(String id) {
    return _activeSandboxes[id];
  }
  
  /// 获取所有活动沙盒
  List<SandboxData> getActiveSandboxes() {
    return _activeSandboxes.values.toList();
  }
  
  /// 获取特定类型的沙盒
  List<SandboxData> getSandboxesByType(SandboxType type) {
    return _activeSandboxes.values
        .where((sandbox) => sandbox.type == type)
        .toList();
  }
  
  /// 更新沙盒状态
  Future<void> updateSandboxStatus(
    String id, 
    SandboxStatus status,
  ) async {
    final sandbox = _activeSandboxes[id];
    if (sandbox == null) {
      throw Exception('沙盒不存在: $id');
    }
    
    final updatedSandbox = sandbox.copyWith(
      status: status,
      lastActivityAt: DateTime.now(),
    );
    
    _activeSandboxes[id] = updatedSandbox;
    _sandboxStateController.add(updatedSandbox);
  }
  
  /// 更新沙盒安全策略
  Future<void> updateSecurityPolicy(
    String id, 
    SecurityPolicy policy,
  ) async {
    final sandbox = _activeSandboxes[id];
    if (sandbox == null) {
      throw Exception('沙盒不存在: $id');
    }
    
    final updatedSandbox = sandbox.copyWith(
      securityPolicy: policy,
      lastActivityAt: DateTime.now(),
    );
    
    _activeSandboxes[id] = updatedSandbox;
    _sandboxStateController.add(updatedSandbox);
  }
  
  /// 更新资源限制
  Future<void> updateResourceLimits(
    String id, 
    ResourceLimiter limiter,
  ) async {
    final sandbox = _activeSandboxes[id];
    if (sandbox == null) {
      throw Exception('沙盒不存在: $id');
    }
    
    final updatedSandbox = sandbox.copyWith(
      resourceLimiter: limiter,
      lastActivityAt: DateTime.now(),
    );
    
    _activeSandboxes[id] = updatedSandbox;
    _sandboxStateController.add(updatedSandbox);
  }
  
  /// 暂停沙盒
  Future<void> pauseSandbox(String id) async {
    await updateSandboxStatus(id, SandboxStatus.paused);
  }
  
  /// 恢复沙盒
  Future<void> resumeSandbox(String id) async {
    await updateSandboxStatus(id, SandboxStatus.running);
  }
  
  /// 停止沙盒
  Future<void> stopSandbox(String id) async {
    final sandbox = _activeSandboxes[id];
    if (sandbox == null) {
      throw Exception('沙盒不存在: $id');
    }
    
    await updateSandboxStatus(id, SandboxStatus.stopped);
    _activeSandboxes.remove(id);
  }
  
  /// 记录安全事件
  void logSecurityEvent(SecurityEvent event) {
    _securityEvents.add(event);
    _securityEventController.add(event);
    
    // 根据事件严重程度采取相应措施
    switch (event.severity) {
      case SecurityEventSeverity.critical:
        // 立即停止沙盒
        stopSandbox(event.sandboxId);
        break;
      
      case SecurityEventSeverity.high:
        // 暂停沙盒
        pauseSandbox(event.sandboxId);
        break;
      
      case SecurityEventSeverity.medium:
      case SecurityEventSeverity.low:
        // 记录事件但不采取行动
        break;
    }
  }
  
  /// 获取安全事件历史
  List<SecurityEvent> getSecurityEvents({
    String? sandboxId,
    SecurityEventType? type,
    SecurityEventSeverity? minSeverity,
  }) {
    var events = _securityEvents;
    
    if (sandboxId != null) {
      events = events.where((event) => event.sandboxId == sandboxId).toList();
    }
    
    if (type != null) {
      events = events.where((event) => event.type == type).toList();
    }
    
    if (minSeverity != null) {
      events = events.where((event) => 
          event.severity.index >= minSeverity.index).toList();
    }
    
    return events;
  }
  
  /// 清理过期沙盒
  Future<void> cleanupExpiredSandboxes({
    Duration maxInactivity = const Duration(hours: 1),
  }) async {
    final now = DateTime.now();
    final expiredIds = _activeSandboxes.values
        .where((sandbox) => 
            now.difference(sandbox.lastActivityAt) > maxInactivity)
        .map((sandbox) => sandbox.id)
        .toList();
    
    for (final id in expiredIds) {
      await stopSandbox(id);
    }
  }
  
  /// 启动沙盒
  Future<void> _startSandbox(SandboxData sandbox) async {
    try {
      // 初始化沙盒环境
      // 这里应该根据沙盒类型进行具体实现
      
      // 更新状态为运行中
      await updateSandboxStatus(sandbox.id, SandboxStatus.running);
    } catch (e) {
      // 记录错误事件
      logSecurityEvent(SecurityEvent(
        id: _generateId(),
        type: SecurityEventType.illegalOperation,
        severity: SecurityEventSeverity.high,
        sandboxId: sandbox.id,
        description: '启动沙盒失败: $e',
      ));
      
      // 更新状态为错误
      await updateSandboxStatus(sandbox.id, SandboxStatus.error);
      rethrow;
    }
  }
  
  /// 生成唯一ID
  String _generateId() {
    return 'sandbox_${DateTime.now().millisecondsSinceEpoch}_${_activeSandboxes.length}';
  }
  
  /// 关闭管理器
  Future<void> close() async {
    // 停止所有活动沙盒
    final sandboxIds = [..._activeSandboxes.keys];
    for (final id in sandboxIds) {
      await stopSandbox(id);
    }
    
    await _sandboxStateController.close();
    await _securityEventController.close();
  }
}

/// 沙盒管理器提供者
final sandboxManagerProvider = Provider<SandboxManager>((ref) {
  final manager = SandboxManager();
  
  ref.onDispose(() {
    manager.close();
  });
  
  return manager;
});

/// 活动沙盒提供者
final activeSandboxesProvider = StreamProvider<List<SandboxData>>((ref) {
  final manager = ref.watch(sandboxManagerProvider);
  
  return manager.sandboxStateChanges.map((_) => manager.getActiveSandboxes());
});

/// 安全事件提供者
final securityEventsProvider = StreamProvider<List<SecurityEvent>>((ref) {
  final manager = ref.watch(sandboxManagerProvider);
  
  return manager.securityEvents.map((_) => manager.getSecurityEvents());
}); 