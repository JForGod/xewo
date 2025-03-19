import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../error/error_handling_service.dart';

/// 日志级别
enum LogLevel {
  /// 调试
  debug,
  
  /// 信息
  info,
  
  /// 警告
  warning,
  
  /// 错误
  error,
  
  /// 严重错误
  critical,
}

/// 日志条目
class LogEntry {
  /// 日志ID
  final String id;
  
  /// 时间戳
  final DateTime timestamp;
  
  /// 日志级别
  final LogLevel level;
  
  /// 消息
  final String message;
  
  /// 标签
  final Map<String, String> tags;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 堆栈跟踪
  final String? stackTrace;
  
  /// 构造函数
  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.tags = const {},
    this.details = const {},
    this.stackTrace,
  });
  
  /// 从Map创建日志条目
  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      level: LogLevel.values.byName(map['level'] as String),
      message: map['message'] as String,
      tags: Map<String, String>.from(map['tags'] ?? {}),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      stackTrace: map['stackTrace'] as String?,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'tags': tags,
      'details': details,
      'stackTrace': stackTrace,
    };
  }
}

/// 日志配置
class LogConfig {
  /// 最低日志级别
  final LogLevel minLevel;
  
  /// 是否启用控制台输出
  final bool enableConsole;
  
  /// 是否启用文件输出
  final bool enableFile;
  
  /// 日志文件目录
  final String logDirectory;
  
  /// 日志文件名模式
  final String logFilePattern;
  
  /// 单个日志文件最大大小（字节）
  final int maxFileSize;
  
  /// 最大日志文件数量
  final int maxFiles;
  
  /// 日志保留天数
  final int retentionDays;
  
  /// 是否启用异步写入
  final bool enableAsyncWrite;
  
  /// 是否启用压缩
  final bool enableCompression;
  
  /// 构造函数
  LogConfig({
    this.minLevel = LogLevel.info,
    this.enableConsole = true,
    this.enableFile = true,
    this.logDirectory = 'logs',
    this.logFilePattern = 'app_{date}.log',
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxFiles = 10,
    this.retentionDays = 30,
    this.enableAsyncWrite = true,
    this.enableCompression = true,
  });
  
  /// 从Map创建配置
  factory LogConfig.fromMap(Map<String, dynamic> map) {
    return LogConfig(
      minLevel: LogLevel.values.byName(map['minLevel'] ?? 'info'),
      enableConsole: map['enableConsole'] ?? true,
      enableFile: map['enableFile'] ?? true,
      logDirectory: map['logDirectory'] ?? 'logs',
      logFilePattern: map['logFilePattern'] ?? 'app_{date}.log',
      maxFileSize: map['maxFileSize'] ?? 10 * 1024 * 1024,
      maxFiles: map['maxFiles'] ?? 10,
      retentionDays: map['retentionDays'] ?? 30,
      enableAsyncWrite: map['enableAsyncWrite'] ?? true,
      enableCompression: map['enableCompression'] ?? true,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'minLevel': minLevel.name,
      'enableConsole': enableConsole,
      'enableFile': enableFile,
      'logDirectory': logDirectory,
      'logFilePattern': logFilePattern,
      'maxFileSize': maxFileSize,
      'maxFiles': maxFiles,
      'retentionDays': retentionDays,
      'enableAsyncWrite': enableAsyncWrite,
      'enableCompression': enableCompression,
    };
  }
}

/// 日志管理服务
class LoggingService {
  /// 配置
  LogConfig _config;
  
  /// 错误处理服务
  final ErrorHandlingService _errorHandlingService;
  
  /// 当前日志文件
  File? _currentLogFile;
  
  /// 日志文件输出流
  IOSink? _logSink;
  
  /// 日志变更流控制器
  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();
  
  /// 日志变更流
  Stream<LogEntry> get logStream => _logController.stream;
  
  /// 构造函数
  LoggingService({
    required ErrorHandlingService errorHandlingService,
    LogConfig? config,
  })  : _errorHandlingService = errorHandlingService,
        _config = config ?? LogConfig() {
    _initializeService();
  }
  
  /// 初始化服务
  Future<void> _initializeService() async {
    try {
      if (_config.enableFile) {
        await _createLogDirectory();
        await _openLogFile();
        await _cleanupOldLogs();
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '初始化日志服务失败',
      );
    }
  }
  
  /// 创建日志目录
  Future<void> _createLogDirectory() async {
    final directory = Directory(_config.logDirectory);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }
  
  /// 打开日志文件
  Future<void> _openLogFile() async {
    final date = DateTime.now().toIso8601String().split('T')[0];
    final fileName = _config.logFilePattern.replaceAll('{date}', date);
    final filePath = path.join(_config.logDirectory, fileName);
    
    _currentLogFile = File(filePath);
    if (!await _currentLogFile!.exists()) {
      await _currentLogFile!.create(recursive: true);
    }
    
    _logSink = _currentLogFile!.openWrite(
      mode: FileMode.append,
      encoding: utf8,
    );
  }
  
  /// 清理旧日志
  Future<void> _cleanupOldLogs() async {
    try {
      final directory = Directory(_config.logDirectory);
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: _config.retentionDays));
      
      await for (final file in directory.list()) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '清理旧日志失败',
      );
    }
  }
  
  /// 写入日志
  Future<void> _writeLog(LogEntry entry) async {
    try {
      // 检查日志级别
      if (entry.level.index < _config.minLevel.index) {
        return;
      }
      
      // 控制台输出
      if (_config.enableConsole) {
        print(
          '[${entry.timestamp}] ${entry.level.name.toUpperCase()}: ${entry.message}',
        );
        if (entry.stackTrace != null) {
          print(entry.stackTrace);
        }
      }
      
      // 文件输出
      if (_config.enableFile) {
        final line = json.encode(entry.toMap());
        if (_config.enableAsyncWrite) {
          _logSink?.writeln(line);
        } else {
          await _logSink?.writeln(line);
          await _logSink?.flush();
        }
        
        // 检查文件大小
        final size = await _currentLogFile?.length() ?? 0;
        if (size >= _config.maxFileSize) {
          await _rotateLogFile();
        }
      }
      
      // 发送到流
      _logController.add(entry);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '写入日志失败',
      );
    }
  }
  
  /// 轮换日志文件
  Future<void> _rotateLogFile() async {
    try {
      await _logSink?.flush();
      await _logSink?.close();
      
      final date = DateTime.now().toIso8601String().split('T')[0];
      final time = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
      final fileName = _config.logFilePattern
          .replaceAll('{date}', '${date}_$time');
      final filePath = path.join(_config.logDirectory, fileName);
      
      await _currentLogFile?.rename(filePath);
      
      if (_config.enableCompression) {
        // 压缩旧日志文件
        final compressedPath = '$filePath.gz';
        final input = await _currentLogFile!.readAsBytes();
        final output = gzip.encode(input);
        await File(compressedPath).writeAsBytes(output);
        await _currentLogFile?.delete();
      }
      
      await _openLogFile();
      await _cleanupOldFiles();
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '轮换日志文件失败',
      );
    }
  }
  
  /// 清理旧文件
  Future<void> _cleanupOldFiles() async {
    try {
      final directory = Directory(_config.logDirectory);
      final files = await directory
          .list()
          .where((f) => f is File)
          .cast<File>()
          .toList();
      
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      if (files.length > _config.maxFiles) {
        for (var i = _config.maxFiles; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '清理旧文件失败',
      );
    }
  }
  
  /// 生成日志ID
  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return '$now$random';
  }
  
  /// 调试日志
  Future<void> debug(
    String message, {
    Map<String, String> tags = const {},
    Map<String, dynamic> details = const {},
    String? stackTrace,
  }) async {
    await _writeLog(
      LogEntry(
        id: _generateId(),
        timestamp: DateTime.now(),
        level: LogLevel.debug,
        message: message,
        tags: tags,
        details: details,
        stackTrace: stackTrace,
      ),
    );
  }
  
  /// 信息日志
  Future<void> info(
    String message, {
    Map<String, String> tags = const {},
    Map<String, dynamic> details = const {},
    String? stackTrace,
  }) async {
    await _writeLog(
      LogEntry(
        id: _generateId(),
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: message,
        tags: tags,
        details: details,
        stackTrace: stackTrace,
      ),
    );
  }
  
  /// 警告日志
  Future<void> warning(
    String message, {
    Map<String, String> tags = const {},
    Map<String, dynamic> details = const {},
    String? stackTrace,
  }) async {
    await _writeLog(
      LogEntry(
        id: _generateId(),
        timestamp: DateTime.now(),
        level: LogLevel.warning,
        message: message,
        tags: tags,
        details: details,
        stackTrace: stackTrace,
      ),
    );
  }
  
  /// 错误日志
  Future<void> error(
    String message, {
    Map<String, String> tags = const {},
    Map<String, dynamic> details = const {},
    String? stackTrace,
  }) async {
    await _writeLog(
      LogEntry(
        id: _generateId(),
        timestamp: DateTime.now(),
        level: LogLevel.error,
        message: message,
        tags: tags,
        details: details,
        stackTrace: stackTrace,
      ),
    );
  }
  
  /// 严重错误日志
  Future<void> critical(
    String message, {
    Map<String, String> tags = const {},
    Map<String, dynamic> details = const {},
    String? stackTrace,
  }) async {
    await _writeLog(
      LogEntry(
        id: _generateId(),
        timestamp: DateTime.now(),
        level: LogLevel.critical,
        message: message,
        tags: tags,
        details: details,
        stackTrace: stackTrace,
      ),
    );
  }
  
  /// 更新配置
  Future<void> updateConfig(LogConfig config) async {
    _config = config;
    await _initializeService();
  }
  
  /// 获取当前配置
  LogConfig getConfig() {
    return _config;
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    await _logSink?.flush();
    await _logSink?.close();
    await _logController.close();
  }
}

/// 日志管理服务提供者
final loggingServiceProvider = Provider<LoggingService>((ref) {
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final service = LoggingService(
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 日志变更流提供者
final logStreamProvider = StreamProvider<LogEntry>((ref) {
  final service = ref.watch(loggingServiceProvider);
  return service.logStream;
}); 