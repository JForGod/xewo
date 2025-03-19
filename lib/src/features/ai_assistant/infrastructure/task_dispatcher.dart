import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/logging/logging_service.dart';
import '../../core/services/error/error_handling_service.dart';

/// 任务优先级
enum TaskPriority {
  low,      // 低优先级
  normal,   // 普通优先级
  high,     // 高优先级
  critical, // 关键优先级
}

/// 任务状态
enum TaskStatus {
  pending,   // 待处理
  running,   // 运行中
  completed, // 已完成
  failed,    // 失败
  cancelled, // 已取消
}

/// 任务定义
class Task<T> {
  final String id;
  final String name;
  final FutureOr<T> Function() execute;
  final TaskPriority priority;
  final Duration timeout;
  final bool retryOnFailure;
  final int maxRetries;
  final Map<String, dynamic> metadata;
  
  TaskStatus status = TaskStatus.pending;
  DateTime createdAt = DateTime.now();
  DateTime? startedAt;
  DateTime? completedAt;
  dynamic result;
  dynamic error;
  int retryCount = 0;
  
  Task({
    required this.id,
    required this.name,
    required this.execute,
    this.priority = TaskPriority.normal,
    this.timeout = const Duration(seconds: 30),
    this.retryOnFailure = false,
    this.maxRetries = 3,
    this.metadata = const {},
  });
}

/// 任务调度器
class TaskDispatcher {
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  
  /// 任务队列
  final Map<TaskPriority, List<Task>> _taskQueues = {
    TaskPriority.low: [],
    TaskPriority.normal: [],
    TaskPriority.high: [],
    TaskPriority.critical: [],
  };
  
  /// 正在执行的任务
  final List<Task> _runningTasks = [];
  
  /// 任务状态控制器
  final StreamController<Task> _taskStateController = StreamController<Task>.broadcast();
  
  /// 是否正在运行
  bool _isRunning = true;
  
  /// 最大并行任务数
  final int _maxConcurrentTasks;
  
  /// 构造函数
  TaskDispatcher({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    int maxConcurrentTasks = 5,
  })  : _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _maxConcurrentTasks = maxConcurrentTasks {
    _startDispatcher();
  }
  
  // 2025-03-16 + 启动调度器功能
  void _startDispatcher() {
    // 定期检查队列并执行任务
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      
      // 检查队列并执行任务
      for (var priority = TaskPriority.low; priority <= TaskPriority.critical; priority++) {
        var tasks = _taskQueues[priority]!;
        while (tasks.isNotEmpty && _runningTasks.length < _maxConcurrentTasks) {
          var task = tasks.removeAt(0);
          _runningTasks.add(task);
          _executeTask(task);
        }
      }
    });
  }
  
  // 2025-03-16 + 执行任务功能
  void _executeTask(Task task) async {
    try {
      _loggingService.info('开始执行任务', tags: {
        'task_id': task.id,
        'task_name': task.name,
        'priority': task.priority.toString(),
      });
      
      // 更新任务状态
      task.status = TaskStatus.running;
      task.startedAt = DateTime.now();
      _notifyTaskStateChanged(task);
      
      // 设置超时
      final completer = Completer();
      Timer? timeoutTimer;
      
      if (task.timeout != Duration.zero) {
        timeoutTimer = Timer(task.timeout, () {
          if (!completer.isCompleted) {
            completer.completeError(
              TimeoutException('任务执行超时', task.timeout),
            );
          }
        });
      }
      
      // 执行任务
      final futureResult = task.execute();
      
      // 处理返回值
      if (futureResult is Future) {
        futureResult.then((result) {
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        }).catchError((error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        });
      } else {
        if (!completer.isCompleted) {
          completer.complete(futureResult);
        }
      }
      
      // 等待任务完成或超时
      try {
        final result = await completer.future;
        timeoutTimer?.cancel();
        
        // 更新任务状态为已完成
        task.status = TaskStatus.completed;
        task.completedAt = DateTime.now();
        task.result = result;
        
        _loggingService.info('任务执行成功', tags: {
          'task_id': task.id,
          'task_name': task.name,
          'execution_time': '${task.completedAt!.difference(task.startedAt!).inMilliseconds}ms',
        });
      } catch (e, s) {
        timeoutTimer?.cancel();
        
        // 记录错误
        task.error = e;
        
        // 处理重试逻辑
        if (task.retryOnFailure && task.retryCount < task.maxRetries) {
          task.retryCount++;
          task.status = TaskStatus.pending;
          
          _loggingService.warning('任务执行失败，准备重试', tags: {
            'task_id': task.id,
            'task_name': task.name,
            'retry_count': '${task.retryCount}/${task.maxRetries}',
            'error': e.toString(),
          });
          
          // 将任务重新添加到队列
          _taskQueues[task.priority]!.add(task);
          _notifyTaskStateChanged(task);
        } else {
          // 更新任务状态为失败
          task.status = TaskStatus.failed;
          task.completedAt = DateTime.now();
          
          _loggingService.error('任务执行失败', tags: {
            'task_id': task.id,
            'task_name': task.name,
            'execution_time': '${task.completedAt!.difference(task.startedAt!).inMilliseconds}ms',
            'error': e.toString(),
          });
          
          // 处理错误
          await _errorHandlingService.handleError(
            e,
            s,
            type: ErrorType.system,
            severity: ErrorSeverity.medium,
            message: '任务执行失败: ${task.name}',
          );
        }
      }
    } finally {
      // 如果任务不是等待重试，从运行任务列表中移除
      if (task.status != TaskStatus.pending) {
        _runningTasks.remove(task);
      }
      
      // 通知任务状态变化
      _notifyTaskStateChanged(task);
    }
  }
  
  // 2025-03-16 + 添加任务功能
  Future<T> addTask<T>(
    String name,
    FutureOr<T> Function() execute, {
    TaskPriority priority = TaskPriority.normal,
    Duration timeout = const Duration(seconds: 30),
    bool retryOnFailure = false,
    int maxRetries = 3,
    Map<String, dynamic> metadata = const {},
  }) {
    final completer = Completer<T>();
    
    final task = Task<T>(
      id: '${DateTime.now().millisecondsSinceEpoch}-${_getRandomString(6)}',
      name: name,
      execute: () async {
        try {
          final result = await execute();
          completer.complete(result);
          return result;
        } catch (e) {
          completer.completeError(e);
          rethrow;
        }
      },
      priority: priority,
      timeout: timeout,
      retryOnFailure: retryOnFailure,
      maxRetries: maxRetries,
      metadata: metadata,
    );
    
    _loggingService.info('添加任务到队列', tags: {
      'task_id': task.id,
      'task_name': task.name,
      'priority': priority.toString(),
    });
    
    // 添加到相应优先级的队列
    _taskQueues[priority]!.add(task);
    
    // 通知任务状态变化
    _notifyTaskStateChanged(task);
    
    return completer.future;
  }
  
  // 2025-03-16 + 取消任务功能
  Future<bool> cancelTask(String taskId) async {
    // 在所有队列中查找任务
    for (final queue in _taskQueues.values) {
      final index = queue.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        final task = queue.removeAt(index);
        task.status = TaskStatus.cancelled;
        task.completedAt = DateTime.now();
        
        _loggingService.info('任务已取消', tags: {
          'task_id': task.id,
          'task_name': task.name,
        });
        
        // 通知任务状态变化
        _notifyTaskStateChanged(task);
        
        return true;
      }
    }
    
    // 在运行中的任务中查找
    final runningTask = _runningTasks.firstWhere(
      (task) => task.id == taskId,
      orElse: () => null as Task,
    );
    
    if (runningTask != null) {
      // 标记为取消，但实际执行结果取决于任务本身
      runningTask.status = TaskStatus.cancelled;
      runningTask.completedAt = DateTime.now();
      
      _loggingService.info('运行中的任务已标记为取消', tags: {
        'task_id': runningTask.id,
        'task_name': runningTask.name,
      });
      
      // 从运行任务列表中移除
      _runningTasks.remove(runningTask);
      
      // 通知任务状态变化
      _notifyTaskStateChanged(runningTask);
      
      return true;
    }
    
    return false;
  }
  
  // 2025-03-16 + 取消所有任务功能
  Future<int> cancelAllTasks() async {
    int cancelCount = 0;
    
    // 清空所有队列
    for (final queue in _taskQueues.values) {
      for (final task in queue) {
        task.status = TaskStatus.cancelled;
        task.completedAt = DateTime.now();
        
        // 通知任务状态变化
        _notifyTaskStateChanged(task);
        
        cancelCount++;
      }
      queue.clear();
    }
    
    // 标记所有运行中的任务为取消
    for (final task in _runningTasks) {
      task.status = TaskStatus.cancelled;
      task.completedAt = DateTime.now();
      
      // 通知任务状态变化
      _notifyTaskStateChanged(task);
      
      cancelCount++;
    }
    _runningTasks.clear();
    
    _loggingService.info('所有任务已取消', tags: {
      'cancel_count': cancelCount.toString(),
    });
    
    return cancelCount;
  }
  
  // 2025-03-16 + 获取任务状态流功能
  Stream<Task> getTaskStateStream() {
    return _taskStateController.stream;
  }
  
  // 2025-03-16 + 获取任务功能
  Task? getTask(String taskId) {
    // 在所有队列中查找任务
    for (final queue in _taskQueues.values) {
      final task = queue.firstWhere(
        (task) => task.id == taskId,
        orElse: () => null as Task,
      );
      if (task != null) {
        return task;
      }
    }
    
    // 在运行中的任务中查找
    return _runningTasks.firstWhere(
      (task) => task.id == taskId,
      orElse: () => null,
    );
  }
  
  // 2025-03-16 + 获取所有任务功能
  List<Task> getAllTasks() {
    final allTasks = <Task>[];
    
    // 添加所有队列中的任务
    for (final queue in _taskQueues.values) {
      allTasks.addAll(queue);
    }
    
    // 添加所有运行中的任务
    allTasks.addAll(_runningTasks);
    
    return allTasks;
  }
  
  // 2025-03-16 + 暂停调度器功能
  void pause() {
    _isRunning = false;
    _loggingService.info('任务调度器已暂停');
  }
  
  // 2025-03-16 + 恢复调度器功能
  void resume() {
    if (!_isRunning) {
      _isRunning = true;
      _startDispatcher();
      _loggingService.info('任务调度器已恢复');
    }
  }
  
  // 2025-03-16 + 通知任务状态变化功能
  void _notifyTaskStateChanged(Task task) {
    if (!_taskStateController.isClosed) {
      _taskStateController.add(task);
    }
  }
  
  // 2025-03-16 + 生成随机字符串功能
  String _getRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final result = StringBuffer();
    
    for (var i = 0; i < length; i++) {
      result.write(chars[random % chars.length]);
    }
    
    return result.toString();
  }
  
  // 2025-03-16 + 释放资源功能
  Future<void> dispose() async {
    _isRunning = false;
    await cancelAllTasks();
    await _taskStateController.close();
  }
}

/// 任务调度器提供者
final taskDispatcherProvider = Provider<TaskDispatcher>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final dispatcher = TaskDispatcher(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    dispatcher.dispose();
  });
  
  return dispatcher;
});
