import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'syscall_interceptor.dart';

/// 日志级别
enum LogLevel {
  /// 调试信息
  debug,
  
  /// 普通信息
  info,
  
  /// 警告信息
  warning,
  
  /// 错误信息
  error,
  
  /// 严重错误
  critical,
}

/// 审计事件类型
enum AuditEventType {
  /// 系统调用
  syscall,
  
  /// 安全事件
  security,
  
  /// 资源使用
  resource,
  
  /// 用户操作
  userAction,
  
  /// 系统事件
  system,
}

/// 审计事件
class AuditEvent {
  /// 事件类型
  final AuditEventType type;
  
  /// 事件级别
  final LogLevel level;
  
  /// 事件描述
  final String description;
  
  /// 事件数据
  final Map<String, dynamic> data;
  
  /// 事件时间
  final DateTime timestamp;
  
  /// 事件源
  final String source;
  
  /// 事件ID
  final String id;
  
  AuditEvent({
    required this.type,
    required this.level,
    required this.description,
    required this.data,
    required this.source,
    String? id,
    DateTime? timestamp,
  }) : 
    id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
    timestamp = timestamp ?? DateTime.now();
  
  /// 从Map创建
  factory AuditEvent.fromMap(Map<String, dynamic> map) {
    return AuditEvent(
      type: AuditEventType.values.byName(map['type'] as String),
      level: LogLevel.values.byName(map['level'] as String),
      description: map['description'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      source: map['source'] as String,
      id: map['id'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'level': level.name,
      'description': description,
      'data': data,
      'source': source,
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// 日志和审计系统
class AuditLogger {
  /// 日志文件路径
  final String logFilePath;
  
  /// 审计文件路径
  final String auditFilePath;
  
  /// 最低日志级别
  final LogLevel minLogLevel;
  
  /// 是否启用控制台输出
  final bool enableConsole;
  
  /// 是否启用文件输出
  final bool enableFile;
  
  /// 是否启用审计
  final bool enableAudit;
  
  /// 日志文件
  File? _logFile;
  
  /// 审计文件
  File? _auditFile;
  
  /// 事件流控制器
  final _eventController = StreamController<AuditEvent>.broadcast();
  
  /// 构造函数
  AuditLogger({
    this.logFilePath = 'logs/sandbox.log',
    this.auditFilePath = 'logs/audit.log',
    this.minLogLevel = LogLevel.info,
    this.enableConsole = true,
    this.enableFile = true,
    this.enableAudit = true,
  });
  
  /// 事件流
  Stream<AuditEvent> get eventStream => _eventController.stream;
  
  /// 初始化
  Future<void> initialize() async {
    if (enableFile) {
      // 创建日志目录
      final logDir = Directory(logFilePath.substring(0, logFilePath.lastIndexOf('/')));
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      // 打开日志文件
      _logFile = File(logFilePath);
      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }
      
      // 打开审计文件
      if (enableAudit) {
        _auditFile = File(auditFilePath);
        if (!await _auditFile!.exists()) {
          await _auditFile!.create();
        }
      }
    }
  }
  
  /// 记录日志
  Future<void> log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? data,
    String source = 'system',
  }) async {
    if (level.index < minLogLevel.index) return;
    
    final event = AuditEvent(
      type: AuditEventType.system,
      level: level,
      description: message,
      data: data ?? {},
      source: source,
    );
    
    // 发送事件
    _eventController.add(event);
    
    // 控制台输出
    if (enableConsole) {
      _printToConsole(event);
    }
    
    // 文件输出
    if (enableFile) {
      await _writeToFile(event);
    }
  }
  
  /// 记录系统调用
  Future<void> logSyscall(SyscallInfo syscall) async {
    final event = AuditEvent(
      type: AuditEventType.syscall,
      level: syscall.error != null ? LogLevel.warning : LogLevel.debug,
      description: '系统调用: ${syscall.name}',
      data: {
        'syscall': syscall.toMap(),
      },
      source: 'syscall_interceptor',
    );
    
    // 发送事件
    _eventController.add(event);
    
    // 审计记录
    if (enableAudit) {
      await _writeToAuditFile(event);
    }
  }
  
  /// 记录安全事件
  Future<void> logSecurityEvent(
    String event,
    LogLevel level,
    Map<String, dynamic> details,
  ) async {
    final auditEvent = AuditEvent(
      type: AuditEventType.security,
      level: level,
      description: event,
      data: details,
      source: 'security_policy',
    );
    
    // 发送事件
    _eventController.add(auditEvent);
    
    // 控制台输出
    if (enableConsole) {
      _printToConsole(auditEvent);
    }
    
    // 审计记录
    if (enableAudit) {
      await _writeToAuditFile(auditEvent);
    }
  }
  
  /// 记录资源使用
  Future<void> logResourceUsage(Map<String, dynamic> usage) async {
    final event = AuditEvent(
      type: AuditEventType.resource,
      level: LogLevel.debug,
      description: '资源使用情况',
      data: usage,
      source: 'resource_limiter',
    );
    
    // 发送事件
    _eventController.add(event);
    
    // 审计记录
    if (enableAudit) {
      await _writeToAuditFile(event);
    }
  }
  
  /// 记录用户操作
  Future<void> logUserAction(
    String action,
    Map<String, dynamic> details, {
    LogLevel level = LogLevel.info,
  }) async {
    final event = AuditEvent(
      type: AuditEventType.userAction,
      level: level,
      description: action,
      data: details,
      source: 'user',
    );
    
    // 发送事件
    _eventController.add(event);
    
    // 控制台输出
    if (enableConsole) {
      _printToConsole(event);
    }
    
    // 审计记录
    if (enableAudit) {
      await _writeToAuditFile(event);
    }
  }
  
  /// 控制台输出
  void _printToConsole(AuditEvent event) {
    final time = event.timestamp.toIso8601String();
    final level = event.level.name.toUpperCase().padRight(7);
    final source = event.source.padRight(20);
    
    print('[$time] $level $source ${event.description}');
    
    if (event.data.isNotEmpty) {
      final encoder = JsonEncoder.withIndent('  ');
      print(encoder.convert(event.data));
    }
  }
  
  /// 写入日志文件
  Future<void> _writeToFile(AuditEvent event) async {
    if (_logFile == null) return;
    
    final line = json.encode({
      'timestamp': event.timestamp.toIso8601String(),
      'level': event.level.name,
      'source': event.source,
      'description': event.description,
      'data': event.data,
    });
    
    await _logFile!.writeAsString('$line\n', mode: FileMode.append);
  }
  
  /// 写入审计文件
  Future<void> _writeToAuditFile(AuditEvent event) async {
    if (_auditFile == null) return;
    
    final line = json.encode(event.toMap());
    await _auditFile!.writeAsString('$line\n', mode: FileMode.append);
  }
  
  /// 获取日志内容
  Future<List<String>> getLogs({
    DateTime? startTime,
    DateTime? endTime,
    LogLevel? minLevel,
    int? limit,
  }) async {
    if (_logFile == null || !await _logFile!.exists()) {
      return [];
    }
    
    final lines = await _logFile!.readAsLines();
    final logs = <String>[];
    
    for (final line in lines.reversed) {
      try {
        final map = json.decode(line) as Map<String, dynamic>;
        final timestamp = DateTime.parse(map['timestamp'] as String);
        final level = LogLevel.values.byName(map['level'] as String);
        
        if (startTime != null && timestamp.isBefore(startTime)) continue;
        if (endTime != null && timestamp.isAfter(endTime)) continue;
        if (minLevel != null && level.index < minLevel.index) continue;
        
        logs.add(line);
        
        if (limit != null && logs.length >= limit) break;
        
      } catch (e) {
        print('解析日志行出错: $e');
      }
    }
    
    return logs;
  }
  
  /// 获取审计记录
  Future<List<AuditEvent>> getAuditEvents({
    DateTime? startTime,
    DateTime? endTime,
    AuditEventType? type,
    LogLevel? minLevel,
    String? source,
    int? limit,
  }) async {
    if (_auditFile == null || !await _auditFile!.exists()) {
      return [];
    }
    
    final lines = await _auditFile!.readAsLines();
    final events = <AuditEvent>[];
    
    for (final line in lines.reversed) {
      try {
        final map = json.decode(line) as Map<String, dynamic>;
        final event = AuditEvent.fromMap(map);
        
        if (startTime != null && event.timestamp.isBefore(startTime)) continue;
        if (endTime != null && event.timestamp.isAfter(endTime)) continue;
        if (type != null && event.type != type) continue;
        if (minLevel != null && event.level.index < minLevel.index) continue;
        if (source != null && event.source != source) continue;
        
        events.add(event);
        
        if (limit != null && events.length >= limit) break;
        
      } catch (e) {
        print('解析审计记录出错: $e');
      }
    }
    
    return events;
  }
  
  /// 分析审计记录
  Map<String, dynamic> analyzeAuditEvents(List<AuditEvent> events) {
    if (events.isEmpty) {
      return {
        'totalEvents': 0,
        'eventsByType': {},
        'eventsByLevel': {},
        'eventsBySource': {},
        'timeDistribution': {},
      };
    }
    
    final eventsByType = <String, int>{};
    final eventsByLevel = <String, int>{};
    final eventsBySource = <String, int>{};
    final timeDistribution = <String, int>{};
    
    for (final event in events) {
      // 按类型统计
      eventsByType[event.type.name] = (eventsByType[event.type.name] ?? 0) + 1;
      
      // 按级别统计
      eventsByLevel[event.level.name] = (eventsByLevel[event.level.name] ?? 0) + 1;
      
      // 按来源统计
      eventsBySource[event.source] = (eventsBySource[event.source] ?? 0) + 1;
      
      // 按时间分布统计（按小时）
      final hour = event.timestamp.hour.toString().padLeft(2, '0');
      timeDistribution[hour] = (timeDistribution[hour] ?? 0) + 1;
    }
    
    return {
      'totalEvents': events.length,
      'eventsByType': eventsByType,
      'eventsByLevel': eventsByLevel,
      'eventsBySource': eventsBySource,
      'timeDistribution': timeDistribution,
    };
  }
  
  /// 清理资源
  Future<void> dispose() async {
    await _eventController.close();
  }
} 