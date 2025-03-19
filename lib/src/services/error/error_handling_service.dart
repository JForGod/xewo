import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../logging/logging_service.dart';

/// 错误类型
enum ErrorType {
  /// 系统错误
  system,
  
  /// 网络错误
  network,
  
  /// 数据库错误
  database,
  
  /// 文件错误
  file,
  
  /// 权限错误
  permission,
  
  /// 验证错误
  validation,
  
  /// 业务错误
  business,
  
  /// 未知错误
  unknown,
}

/// 错误严重程度
enum ErrorSeverity {
  /// 低
  low,
  
  /// 中
  medium,
  
  /// 高
  high,
  
  /// 严重
  critical,
}

/// 错误信息
class ErrorInfo {
  /// 错误ID
  final String id;
  
  /// 时间戳
  final DateTime timestamp;
  
  /// 错误类型
  final ErrorType type;
  
  /// 严重程度
  final ErrorSeverity severity;
  
  /// 消息
  final String message;
  
  /// 错误对象
  final Object error;
  
  /// 堆栈跟踪
  final StackTrace stackTrace;
  
  /// 标签
  final Map<String, String> tags;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 是否已处理
  final bool handled;
  
  /// 处理时间
  final DateTime? handledAt;
  
  /// 处理结果
  final String? handlingResult;
  
  /// 构造函数
  ErrorInfo({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.severity,
    required this.message,
    required this.error,
    required this.stackTrace,
    this.tags = const {},
    this.details = const {},
    this.handled = false,
    this.handledAt,
    this.handlingResult,
  });
  
  /// 从Map创建错误信息
  factory ErrorInfo.fromMap(Map<String, dynamic> map) {
    return ErrorInfo(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: ErrorType.values.byName(map['type'] as String),
      severity: ErrorSeverity.values.byName(map['severity'] as String),
      message: map['message'] as String,
      error: map['error'] as Object,
      stackTrace: StackTrace.fromString(map['stackTrace'] as String),
      tags: Map<String, String>.from(map['tags'] ?? {}),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      handled: map['handled'] as bool? ?? false,
      handledAt: map['handledAt'] != null
          ? DateTime.parse(map['handledAt'] as String)
          : null,
      handlingResult: map['handlingResult'] as String?,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
      'tags': tags,
      'details': details,
      'handled': handled,
      'handledAt': handledAt?.toIso8601String(),
      'handlingResult': handlingResult,
    };
  }
}

/// 错误处理配置
class ErrorHandlingConfig {
  /// 是否启用错误处理
  final bool enabled;
  
  /// 是否记录错误
  final bool logErrors;
  
  /// 是否发送错误报告
  final bool sendErrorReports;
  
  /// 是否显示错误通知
  final bool showErrorNotifications;
  
  /// 是否自动重试
  final bool autoRetry;
  
  /// 最大重试次数
  final int maxRetries;
  
  /// 重试延迟（毫秒）
  final int retryDelay;
  
  /// 错误保留天数
  final int retentionDays;
  
  /// 构造函数
  ErrorHandlingConfig({
    this.enabled = true,
    this.logErrors = true,
    this.sendErrorReports = true,
    this.showErrorNotifications = true,
    this.autoRetry = true,
    this.maxRetries = 3,
    this.retryDelay = 1000,
    this.retentionDays = 30,
  });
  
  /// 从Map创建配置
  factory ErrorHandlingConfig.fromMap(Map<String, dynamic> map) {
    return ErrorHandlingConfig(
      enabled: map['enabled'] ?? true,
      logErrors: map['logErrors'] ?? true,
      sendErrorReports: map['sendErrorReports'] ?? true,
      showErrorNotifications: map['showErrorNotifications'] ?? true,
      autoRetry: map['autoRetry'] ?? true,
      maxRetries: map['maxRetries'] ?? 3,
      retryDelay: map['retryDelay'] ?? 1000,
      retentionDays: map['retentionDays'] ?? 30,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'logErrors': logErrors,
      'sendErrorReports': sendErrorReports,
      'showErrorNotifications': showErrorNotifications,
      'autoRetry': autoRetry,
      'maxRetries': maxRetries,
      'retryDelay': retryDelay,
      'retentionDays': retentionDays,
    };
  }
}

/// 错误处理服务
class ErrorHandlingService {
  /// 配置
  ErrorHandlingConfig _config;
  
  /// 错误信息映射
  final Map<String, ErrorInfo> _errors = {};
  
  /// 错误变更流控制器
  final StreamController<ErrorInfo> _errorController =
      StreamController<ErrorInfo>.broadcast();
  
  /// 错误变更流
  Stream<ErrorInfo> get errorStream => _errorController.stream;
  
  /// 构造函数
  ErrorHandlingService({
    ErrorHandlingConfig? config,
  }) : _config = config ?? ErrorHandlingConfig() {
    _initializeService();
  }
  
  /// 初始化服务
  void _initializeService() {
    // 清理旧错误
    _cleanupOldErrors();
  }
  
  /// 清理旧错误
  void _cleanupOldErrors() {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: _config.retentionDays));
    
    _errors.removeWhere((_, error) => error.timestamp.isBefore(cutoffDate));
  }
  
  /// 生成错误ID
  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return '$now$random';
  }
  
  /// 处理错误
  Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    ErrorType type = ErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    String? message,
    Map<String, String> tags = const {},
    Map<String, dynamic> details = const {},
  }) async {
    if (!_config.enabled) {
      return;
    }
    
    try {
      // 创建错误信息
      final errorInfo = ErrorInfo(
        id: _generateId(),
        timestamp: DateTime.now(),
        type: type,
        severity: severity,
        message: message ?? error.toString(),
        error: error,
        stackTrace: stackTrace,
        tags: tags,
        details: details,
      );
      
      // 保存错误信息
      _errors[errorInfo.id] = errorInfo;
      
      // 发送到流
      _errorController.add(errorInfo);
      
      // 记录错误
      if (_config.logErrors) {
        _logError(errorInfo);
      }
      
      // 发送错误报告
      if (_config.sendErrorReports) {
        await _sendErrorReport(errorInfo);
      }
      
      // 显示错误通知
      if (_config.showErrorNotifications) {
        _showErrorNotification(errorInfo);
      }
      
      // 自动重试
      if (_config.autoRetry) {
        await _retryOperation(errorInfo);
      }
    } catch (e, s) {
      print('错误处理失败: $e\n$s');
    }
  }
  
  /// 记录错误
  void _logError(ErrorInfo errorInfo) {
    // TODO: 实现错误日志记录
  }
  
  /// 发送错误报告
  Future<void> _sendErrorReport(ErrorInfo errorInfo) async {
    // TODO: 实现错误报告发送
  }
  
  /// 显示错误通知
  void _showErrorNotification(ErrorInfo errorInfo) {
    // TODO: 实现错误通知显示
  }
  
  /// 重试操作
  Future<void> _retryOperation(ErrorInfo errorInfo) async {
    // TODO: 实现操作重试
  }
  
  /// 标记错误为已处理
  Future<void> markErrorAsHandled(
    String errorId, {
    String? handlingResult,
  }) async {
    final errorInfo = _errors[errorId];
    if (errorInfo == null) {
      return;
    }
    
    // 更新错误信息
    final updatedErrorInfo = ErrorInfo(
      id: errorInfo.id,
      timestamp: errorInfo.timestamp,
      type: errorInfo.type,
      severity: errorInfo.severity,
      message: errorInfo.message,
      error: errorInfo.error,
      stackTrace: errorInfo.stackTrace,
      tags: errorInfo.tags,
      details: errorInfo.details,
      handled: true,
      handledAt: DateTime.now(),
      handlingResult: handlingResult,
    );
    
    // 保存错误信息
    _errors[errorId] = updatedErrorInfo;
    
    // 发送到流
    _errorController.add(updatedErrorInfo);
  }
  
  /// 获取错误信息
  ErrorInfo? getError(String errorId) {
    return _errors[errorId];
  }
  
  /// 获取所有错误
  List<ErrorInfo> getAllErrors() {
    return List.unmodifiable(_errors.values);
  }
  
  /// 获取未处理的错误
  List<ErrorInfo> getUnhandledErrors() {
    return _errors.values.where((error) => !error.handled).toList();
  }
  
  /// 获取特定类型的错误
  List<ErrorInfo> getErrorsByType(ErrorType type) {
    return _errors.values.where((error) => error.type == type).toList();
  }
  
  /// 获取特定严重程度的错误
  List<ErrorInfo> getErrorsBySeverity(ErrorSeverity severity) {
    return _errors.values.where((error) => error.severity == severity).toList();
  }
  
  /// 清理错误
  void clearErrors() {
    _errors.clear();
  }
  
  /// 更新配置
  void updateConfig(ErrorHandlingConfig config) {
    _config = config;
    _initializeService();
  }
  
  /// 获取当前配置
  ErrorHandlingConfig getConfig() {
    return _config;
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    await _errorController.close();
  }
}

/// 错误处理服务提供者
final errorHandlingServiceProvider = Provider<ErrorHandlingService>((ref) {
  final service = ErrorHandlingService();
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 错误变更流提供者
final errorStreamProvider = StreamProvider<ErrorInfo>((ref) {
  final service = ref.watch(errorHandlingServiceProvider);
  return service.errorStream;
});

/// 错误严重程度级别
enum ErrorSeverity {
  /// 严重错误，应用可能无法继续运行
  critical,
  
  /// 错误，影响功能但应用可以继续运行
  error,
  
  /// 警告，可能有问题但不影响主要功能
  warning,
  
  /// 信息，仅供参考不影响功能
  info,
}

/// 错误状态
enum ErrorStatus {
  /// 新错误
  new_,
  
  /// 已处理
  handled,
  
  /// 已恢复
  recovered,
  
  /// 已忽略
  ignored,
}

/// 错误报告类
class ErrorReport {
  /// 错误ID
  final String id;
  
  /// 错误信息
  final String message;
  
  /// 错误详情
  final String details;
  
  /// 错误发生时间
  final DateTime timestamp;
  
  /// 错误严重程度
  final ErrorSeverity severity;
  
  /// 错误状态
  ErrorStatus status;
  
  /// 错误栈跟踪
  final StackTrace? stackTrace;
  
  /// 错误源（代码位置、组件等）
  final String? source;
  
  /// 用户反馈
  String? userFeedback;
  
  ErrorReport({
    required this.id,
    required this.message,
    required this.details,
    required this.severity,
    this.status = ErrorStatus.new_,
    this.stackTrace,
    this.source,
    this.userFeedback,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 更新错误状态
  void updateStatus(ErrorStatus newStatus) {
    status = newStatus;
  }
  
  /// 添加用户反馈
  void addUserFeedback(String feedback) {
    userFeedback = feedback;
  }
  
  /// 将错误报告转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.toString(),
      'status': status.toString(),
      'stackTrace': stackTrace?.toString(),
      'source': source,
      'userFeedback': userFeedback,
    };
  }
  
  /// 从JSON创建错误报告
  factory ErrorReport.fromJson(Map<String, dynamic> json) {
    return ErrorReport(
      id: json['id'] as String,
      message: json['message'] as String,
      details: json['details'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      severity: ErrorSeverity.values.firstWhere(
        (e) => e.toString() == json['severity'],
        orElse: () => ErrorSeverity.error,
      ),
      status: ErrorStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ErrorStatus.new_,
      ),
      stackTrace: json['stackTrace'] != null 
          ? StackTrace.fromString(json['stackTrace'] as String)
          : null,
      source: json['source'] as String?,
      userFeedback: json['userFeedback'] as String?,
    );
  }
}

/// 错误处理服务，用于管理错误处理、错误恢复和用户反馈
class ErrorHandlingService {
  /// 错误报告列表
  final List<ErrorReport> _errorReports = [];
  
  /// 错误报告流控制器
  final StreamController<ErrorReport> _errorController = StreamController<ErrorReport>.broadcast();
  
  /// 全局错误处理器
  void Function(FlutterErrorDetails)? _previousErrorHandler;
  
  /// 错误报告目录
  String _errorReportDirectory = '.';
  
  /// 错误报告流
  Stream<ErrorReport> get errorStream => _errorController.stream;
  
  /// 初始化错误处理服务
  void initialize({String? errorReportDirectory}) {
    if (errorReportDirectory != null) {
      _errorReportDirectory = errorReportDirectory;
    }
    
    // 设置全局错误处理
    _previousErrorHandler = FlutterError.onError;
    FlutterError.onError = _handleFlutterError;
    
    // 创建错误报告目录
    _createErrorReportDirectory();
    
    debugPrint('错误处理服务初始化完成');
  }
  
  /// 析构函数
  void dispose() {
    FlutterError.onError = _previousErrorHandler;
    _errorController.close();
    
    debugPrint('错误处理服务已释放');
  }
  
  /// 处理 Flutter 框架错误
  void _handleFlutterError(FlutterErrorDetails details) {
    _reportError(
      message: details.exception.toString(),
      details: details.summary.toString(),
      severity: ErrorSeverity.error,
      stackTrace: details.stack,
      source: 'Flutter Framework',
    );
    
    // 将错误传递给之前的处理器
    _previousErrorHandler?.call(details);
  }
  
  /// 创建错误报告目录
  Future<void> _createErrorReportDirectory() async {
    try {
      final directory = Directory(_errorReportDirectory);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (e) {
      debugPrint('创建错误报告目录失败: $e');
    }
  }
  
  /// 报告错误
  ErrorReport reportError({
    required String message,
    required String details,
    ErrorSeverity severity = ErrorSeverity.error,
    StackTrace? stackTrace,
    String? source,
    String? userFeedback,
  }) {
    return _reportError(
      message: message,
      details: details,
      severity: severity,
      stackTrace: stackTrace,
      source: source,
      userFeedback: userFeedback,
    );
  }
  
  /// 内部报告错误实现
  ErrorReport _reportError({
    required String message,
    required String details,
    required ErrorSeverity severity,
    StackTrace? stackTrace,
    String? source,
    String? userFeedback,
  }) {
    // 生成唯一ID
    final id = 'error_${DateTime.now().millisecondsSinceEpoch}';
    
    final report = ErrorReport(
      id: id,
      message: message,
      details: details,
      severity: severity,
      stackTrace: stackTrace,
      source: source,
      userFeedback: userFeedback,
    );
    
    _errorReports.add(report);
    _errorController.add(report);
    
    // 将错误写入日志
    _writeErrorToLog(report);
    
    // 对于严重错误，保存错误报告文件
    if (severity == ErrorSeverity.critical) {
      _saveErrorReport(report);
    }
    
    return report;
  }
  
  /// 将错误写入日志
  void _writeErrorToLog(ErrorReport report) {
    debugPrint('ERROR [${report.severity}] ${report.message}');
    debugPrint('Details: ${report.details}');
    if (report.stackTrace != null) {
      debugPrint('StackTrace: ${report.stackTrace}');
    }
  }
  
  /// 保存错误报告到文件
  Future<void> _saveErrorReport(ErrorReport report) async {
    try {
      final reportFile = File(path.join(
        _errorReportDirectory,
        'error_${report.id}_${report.timestamp.millisecondsSinceEpoch}.json',
      ));
      
      await reportFile.writeAsString(report.toJson().toString());
      debugPrint('错误报告已保存: ${reportFile.path}');
    } catch (e) {
      debugPrint('保存错误报告失败: $e');
    }
  }
  
  /// 获取所有错误报告
  List<ErrorReport> getAllErrorReports() {
    return List.unmodifiable(_errorReports);
  }
  
  /// 获取未处理的错误报告
  List<ErrorReport> getUnhandledErrorReports() {
    return _errorReports
        .where((report) => report.status == ErrorStatus.new_)
        .toList();
  }
  
  /// 获取特定严重程度的错误报告
  List<ErrorReport> getErrorReportsBySeverity(ErrorSeverity severity) {
    return _errorReports
        .where((report) => report.severity == severity)
        .toList();
  }
  
  /// 更新错误报告状态
  void updateErrorStatus(String errorId, ErrorStatus newStatus) {
    final report = _errorReports.firstWhere(
      (report) => report.id == errorId,
      orElse: () => throw Exception('找不到ID为 $errorId 的错误报告'),
    );
    
    report.updateStatus(newStatus);
    
    // 如果错误已恢复，发送通知
    if (newStatus == ErrorStatus.recovered) {
      _errorController.add(report);
    }
  }
  
  /// 添加用户反馈
  void addUserFeedback(String errorId, String feedback) {
    final report = _errorReports.firstWhere(
      (report) => report.id == errorId,
      orElse: () => throw Exception('找不到ID为 $errorId 的错误报告'),
    );
    
    report.addUserFeedback(feedback);
  }
  
  /// 尝试恢复错误
  Future<bool> attemptRecovery(String errorId) async {
    final report = _errorReports.firstWhere(
      (report) => report.id == errorId,
      orElse: () => throw Exception('找不到ID为 $errorId 的错误报告'),
    );
    
    // 根据错误类型执行恢复操作
    bool recoverySuccess = false;
    
    try {
      switch (report.source) {
        case 'FileSystem':
          recoverySuccess = await _recoverFileSystemError(report);
          break;
        case 'Network':
          recoverySuccess = await _recoverNetworkError(report);
          break;
        case 'Database':
          recoverySuccess = await _recoverDatabaseError(report);
          break;
        default:
          // 默认恢复操作
          recoverySuccess = false;
      }
      
      // 更新错误状态
      if (recoverySuccess) {
        report.updateStatus(ErrorStatus.recovered);
        _errorController.add(report);
      }
      
      return recoverySuccess;
    } catch (e) {
      debugPrint('尝试恢复错误失败: $e');
      return false;
    }
  }
  
  /// 恢复文件系统错误
  Future<bool> _recoverFileSystemError(ErrorReport report) async {
    // 实现文件系统错误恢复逻辑
    debugPrint('尝试恢复文件系统错误: ${report.id}');
    return true;
  }
  
  /// 恢复网络错误
  Future<bool> _recoverNetworkError(ErrorReport report) async {
    // 实现网络错误恢复逻辑
    debugPrint('尝试恢复网络错误: ${report.id}');
    return true;
  }
  
  /// 恢复数据库错误
  Future<bool> _recoverDatabaseError(ErrorReport report) async {
    // 实现数据库错误恢复逻辑
    debugPrint('尝试恢复数据库错误: ${report.id}');
    return true;
  }
  
  /// 清除所有错误报告
  void clearAllErrorReports() {
    _errorReports.clear();
  }
  
  /// 清除已处理的错误报告
  void clearHandledErrorReports() {
    _errorReports.removeWhere((report) => 
      report.status == ErrorStatus.handled || 
      report.status == ErrorStatus.recovered ||
      report.status == ErrorStatus.ignored
    );
  }
  
  /// 创建错误界面构建器
  Widget Function(BuildContext, FlutterErrorDetails) createErrorWidgetBuilder() {
    return (BuildContext context, FlutterErrorDetails errorDetails) {
      // 报告错误
      final report = _reportError(
        message: errorDetails.exception.toString(),
        details: errorDetails.summary.toString(),
        severity: ErrorSeverity.error,
        stackTrace: errorDetails.stack,
        source: 'Widget Build',
      );
      
      // 返回自定义错误界面
      return Material(
        color: Colors.red[100],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('出现错误', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(report.message, style: TextStyle(fontSize: 14)),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => attemptRecovery(report.id),
                    child: Text('尝试恢复'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    };
  }
} 