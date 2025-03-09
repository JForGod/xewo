import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// 日志级别枚举
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// 日志服务，提供应用程序日志记录功能
class LoggerService {
  /// 当前日志级别
  LogLevel _currentLevel = LogLevel.info;
  
  /// 日志格式化器
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
  
  /// 日志缓存，用于在UI中显示最近的日志
  final List<String> _logCache = [];
  
  /// 日志缓存最大条数
  final int _maxCacheSize = 1000;
  
  /// 构造函数
  LoggerService();
  
  /// 设置日志级别
  void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }
  
  /// 获取当前日志级别
  LogLevel getLogLevel() {
    return _currentLevel;
  }
  
  /// 记录调试级别日志
  void debug(String message) {
    if (_currentLevel.index <= LogLevel.debug.index) {
      _log(LogLevel.debug, message);
    }
  }
  
  /// 记录信息级别日志
  void info(String message) {
    if (_currentLevel.index <= LogLevel.info.index) {
      _log(LogLevel.info, message);
    }
  }
  
  /// 记录警告级别日志
  void warning(String message) {
    if (_currentLevel.index <= LogLevel.warning.index) {
      _log(LogLevel.warning, message);
    }
  }
  
  /// 记录错误级别日志
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_currentLevel.index <= LogLevel.error.index) {
      final errorMsg = error != null ? '$message: $error' : message;
      _log(LogLevel.error, errorMsg);
      if (stackTrace != null) {
        _log(LogLevel.error, 'Stack trace: $stackTrace');
      }
    }
  }
  
  /// 记录致命级别日志
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_currentLevel.index <= LogLevel.fatal.index) {
      final errorMsg = error != null ? '$message: $error' : message;
      _log(LogLevel.fatal, errorMsg);
      if (stackTrace != null) {
        _log(LogLevel.fatal, 'Stack trace: $stackTrace');
      }
    }
  }
  
  /// 内部日志记录方法
  void _log(LogLevel level, String message) {
    final timestamp = _dateFormat.format(DateTime.now());
    final logMessage = '[$timestamp] ${_getLevelTag(level)}: $message';
    
    // 添加到缓存
    _addToCache(logMessage);
    
    // 输出到控制台
    if (kDebugMode) {
      developer.log(message, name: _getLevelTag(level));
    }
  }
  
  /// 获取日志级别标签
  String _getLevelTag(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
      default:
        return 'UNKNOWN';
    }
  }
  
  /// 添加日志到缓存
  void _addToCache(String logMessage) {
    _logCache.add(logMessage);
    if (_logCache.length > _maxCacheSize) {
      _logCache.removeAt(0);
    }
  }
  
  /// 获取日志缓存
  List<String> getLogCache() {
    return List.unmodifiable(_logCache);
  }
  
  /// 清除日志缓存
  void clearLogCache() {
    _logCache.clear();
  }
}

/// 日志服务提供者
final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
}); 