import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

/// 错误处理服务提供者
final errorHandlingServiceProvider = Provider<ErrorHandlingService>((ref) {
  throw UnimplementedError('errorHandlingServiceProvider 未初始化');
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