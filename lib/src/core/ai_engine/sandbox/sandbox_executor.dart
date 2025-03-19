import 'dart:async';
import 'dart:isolate';

import 'security_policy.dart';
import 'resource_limiter.dart';

/// 沙盒执行消息
class SandboxMessage {
  /// 消息类型
  final String type;
  
  /// 消息数据
  final Map<String, dynamic> data;
  
  /// 时间戳
  final DateTime timestamp;
  
  SandboxMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 从Map创建
  factory SandboxMessage.fromMap(Map<String, dynamic> map) {
    return SandboxMessage(
      type: map['type'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// 沙盒执行结果
class ExecutionResult {
  /// 是否成功
  final bool success;
  
  /// 结果数据
  final dynamic result;
  
  /// 错误信息
  final String? error;
  
  /// 执行时间（毫秒）
  final int executionTimeMs;
  
  /// 资源使用情况
  final ResourceUsage resourceUsage;
  
  ExecutionResult({
    required this.success,
    this.result,
    this.error,
    required this.executionTimeMs,
    required this.resourceUsage,
  });
  
  /// 从Map创建
  factory ExecutionResult.fromMap(Map<String, dynamic> map) {
    return ExecutionResult(
      success: map['success'] as bool,
      result: map['result'],
      error: map['error'] as String?,
      executionTimeMs: map['executionTimeMs'] as int,
      resourceUsage: ResourceUsage.fromMap(
        Map<String, dynamic>.from(map['resourceUsage'] as Map),
      ),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'result': result,
      'error': error,
      'executionTimeMs': executionTimeMs,
      'resourceUsage': resourceUsage.toMap(),
    };
  }
}

/// 沙盒执行器
class SandboxExecutor {
  /// 安全策略
  final SecurityPolicy securityPolicy;
  
  /// 资源限制器
  final ResourceLimiter resourceLimiter;
  
  /// 隔离实例
  Isolate? _isolate;
  
  /// 发送端口
  SendPort? _sendPort;
  
  /// 接收端口
  final _receivePort = ReceivePort();
  
  /// 消息控制器
  final _messageController = StreamController<SandboxMessage>.broadcast();
  
  /// 构造函数
  SandboxExecutor({
    required this.securityPolicy,
    ResourceLimiter? resourceLimiter,
  }) : resourceLimiter = resourceLimiter ?? ResourceLimiter();
  
  /// 消息流
  Stream<SandboxMessage> get messageStream => _messageController.stream;
  
  /// 初始化沙盒
  Future<void> initialize() async {
    if (_isolate != null) return;
    
    try {
      // 创建隔离实例
      _isolate = await Isolate.spawn(
        _isolateFunction,
        _receivePort.sendPort,
      );
      
      // 等待隔离实例返回发送端口
      _sendPort = await _receivePort.first as SendPort;
      
      // 监听消息
      _receivePort.listen(_handleMessage);
      
      // 启动资源监控
      resourceLimiter.startMonitoring();
      
      // 发送初始化消息
      _sendMessage('initialize', {
        'securityPolicy': securityPolicy.toMap(),
        'resourceLimits': resourceLimiter.limits.toMap(),
      });
      
    } catch (e) {
      throw Exception('初始化沙盒失败: $e');
    }
  }
  
  /// 在沙盒中执行代码
  Future<ExecutionResult> execute(String code, {
    Map<String, dynamic>? context,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_isolate == null || _sendPort == null) {
      throw Exception('沙盒未初始化');
    }
    
    final completer = Completer<ExecutionResult>();
    final startTime = DateTime.now();
    
    // 设置超时
    final timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(ExecutionResult(
          success: false,
          error: '执行超时',
          executionTimeMs: timeout.inMilliseconds,
          resourceUsage: ResourceUsage(),
        ));
      }
    });
    
    try {
      // 发送执行请求
      _sendMessage('execute', {
        'code': code,
        'context': context,
      });
      
      // 等待执行结果
      await for (final message in messageStream) {
        if (message.type == 'executionResult') {
          final endTime = DateTime.now();
          final executionTime = endTime.difference(startTime).inMilliseconds;
          
          final result = ExecutionResult(
            success: message.data['success'] as bool,
            result: message.data['result'],
            error: message.data['error'] as String?,
            executionTimeMs: executionTime,
            resourceUsage: await resourceLimiter.getCurrentUsage(),
          );
          
          if (!completer.isCompleted) {
            completer.complete(result);
          }
          break;
        }
      }
      
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(ExecutionResult(
          success: false,
          error: '执行出错: $e',
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
          resourceUsage: ResourceUsage(),
        ));
      }
    } finally {
      timeoutTimer.cancel();
    }
    
    return completer.future;
  }
  
  /// 发送消息到隔离实例
  void _sendMessage(String type, Map<String, dynamic> data) {
    _sendPort?.send(SandboxMessage(
      type: type,
      data: data,
    ).toMap());
  }
  
  /// 处理来自隔离实例的消息
  void _handleMessage(dynamic message) {
    if (message is! Map<String, dynamic>) return;
    
    try {
      final sandboxMessage = SandboxMessage.fromMap(message);
      _messageController.add(sandboxMessage);
    } catch (e) {
      print('处理沙盒消息出错: $e');
    }
  }
  
  /// 清理资源
  Future<void> dispose() async {
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
    await _messageController.close();
    _receivePort.close();
    resourceLimiter.dispose();
  }
}

/// 隔离实例入口函数
void _isolateFunction(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  
  SecurityPolicy? securityPolicy;
  ResourceLimits? resourceLimits;
  
  receivePort.listen((message) {
    if (message is! Map<String, dynamic>) return;
    
    try {
      final sandboxMessage = SandboxMessage.fromMap(message);
      
      switch (sandboxMessage.type) {
        case 'initialize':
          securityPolicy = SecurityPolicy.fromMap(
            sandboxMessage.data['securityPolicy'] as Map<String, dynamic>,
          );
          resourceLimits = ResourceLimits.fromMap(
            sandboxMessage.data['resourceLimits'] as Map<String, dynamic>,
          );
          break;
        
        case 'execute':
          _executeInSandbox(
            sendPort,
            sandboxMessage.data['code'] as String,
            sandboxMessage.data['context'] as Map<String, dynamic>?,
            securityPolicy,
            resourceLimits,
          );
          break;
      }
      
    } catch (e) {
      sendPort.send(SandboxMessage(
        type: 'error',
        data: {'error': e.toString()},
      ).toMap());
    }
  });
}

/// 在沙盒中执行代码
Future<void> _executeInSandbox(
  SendPort sendPort,
  String code,
  Map<String, dynamic>? context,
  SecurityPolicy? securityPolicy,
  ResourceLimits? resourceLimits,
) async {
  try {
    // TODO: 实现代码执行逻辑
    // 这里需要实现一个安全的代码执行环境
    // 可以使用 dart:mirrors 或其他方式实现
    
    // 模拟执行结果
    sendPort.send(SandboxMessage(
      type: 'executionResult',
      data: {
        'success': true,
        'result': '代码执行成功',
        'error': null,
      },
    ).toMap());
    
  } catch (e) {
    sendPort.send(SandboxMessage(
      type: 'executionResult',
      data: {
        'success': false,
        'result': null,
        'error': e.toString(),
      },
    ).toMap());
  }
} 