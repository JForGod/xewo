import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/logging/logging_service.dart';
import '../../../../core/services/error/error_handling_service.dart';
import '../../../../core/services/security/security_service.dart';

/// 本地存储
class LocalStorage {
  final SharedPreferences _prefs;
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  final SecurityService _securityService;
  
  /// 构造函数
  LocalStorage({
    required SharedPreferences prefs,
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    required SecurityService securityService,
  })  : _prefs = prefs,
        _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _securityService = securityService;
  
  // 2025-03-16 + 读取数据功能
  Future<T?> read<T>(String key, {bool decrypt = false}) async {
    try {
      if (!_prefs.containsKey(key)) {
        return null;
      }
      
      dynamic value;
      
      if (T == String) {
        value = _prefs.getString(key);
      } else if (T == int) {
        value = _prefs.getInt(key);
      } else if (T == double) {
        value = _prefs.getDouble(key);
      } else if (T == bool) {
        value = _prefs.getBool(key);
      } else if (T == List<String>) {
        value = _prefs.getStringList(key);
      } else {
        // 复杂对象，先作为String读取
        final jsonStr = _prefs.getString(key);
        if (jsonStr != null) {
          // 如果需要解密
          final decryptedStr = decrypt
              ? await _securityService.decrypt(jsonStr)
              : jsonStr;
          
          try {
            value = json.decode(decryptedStr);
          } catch (e) {
            _loggingService.error('解析JSON失败', tags: {
              'error': e.toString(),
              'key': key,
            });
            return null;
          }
        }
      }
      
      return value as T?;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.low,
        message: '读取本地存储失败: $key',
      );
      return null;
    }
  }
  
  // 2025-03-16 + 写入数据功能
  Future<bool> write<T>(String key, T value, {bool encrypt = false}) async {
    try {
      if (value == null) {
        return false;
      }
      
      if (T == String) {
        return _prefs.setString(key, value as String);
      } else if (T == int) {
        return _prefs.setInt(key, value as int);
      } else if (T == double) {
        return _prefs.setDouble(key, value as double);
      } else if (T == bool) {
        return _prefs.setBool(key, value as bool);
      } else if (T == List<String>) {
        return _prefs.setStringList(key, value as List<String>);
      } else {
        // 复杂对象，先作为String写入
        final jsonStr = json.encode(value);
        
        // 如果需要加密
        final encryptedStr = encrypt
            ? await _securityService.encrypt(jsonStr)
            : jsonStr;
        
        return _prefs.setString(key, encryptedStr);
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.low,
        message: '写入本地存储失败: $key',
      );
      return false;
    }
  }
  
  // 2025-03-16 + 删除数据功能
  Future<bool> delete(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.low,
        message: '删除本地存储失败: $key',
      );
      return false;
    }
  }
  
  // 2025-03-16 + 清空所有数据功能
  Future<bool> clear() async {
    try {
      return await _prefs.clear();
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        message: '清空本地存储失败',
      );
      return false;
    }
  }
  
  // 2025-03-16 + 获取所有键功能
  Future<Set<String>> getKeys([String? prefix]) async {
    try {
      final keys = _prefs.getKeys();
      
      if (prefix != null && prefix.isNotEmpty) {
        return keys.where((key) => key.startsWith(prefix)).toSet();
      }
      
      return keys;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.low,
        message: '获取本地存储键失败',
      );
      return {};
    }
  }
  
  // 2025-03-16 + 检查键是否存在功能
  Future<bool> exists(String key) async {
    try {
      return _prefs.containsKey(key);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.low,
        message: '检查键存在失败: $key',
      );
      return false;
    }
  }
  
  // 2025-03-16 + 获取存储中项目数量功能
  Future<int> getCount() async {
    try {
      return _prefs.getKeys().length;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.low,
        message: '获取存储项目数量失败',
      );
      return 0;
    }
  }
  
  // 2025-03-16 + 批量写入数据功能
  Future<bool> writeBatch(Map<String, dynamic> data, {bool encrypt = false}) async {
    try {
      bool success = true;
      
      for (final entry in data.entries) {
        final result = await write(entry.key, entry.value, encrypt: encrypt);
        success = success && result;
      }
      
      return success;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        message: '批量写入本地存储失败',
      );
      return false;
    }
  }
  
  // 2025-03-16 + 批量删除数据功能
  Future<bool> deleteBatch(List<String> keys) async {
    try {
      bool success = true;
      
      for (final key in keys) {
        final result = await delete(key);
        success = success && result;
      }
      
      return success;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        message: '批量删除本地存储失败',
      );
      return false;
    }
  }
  
  // 2025-03-16 + 删除匹配前缀的所有键功能
  Future<bool> deleteWithPrefix(String prefix) async {
    try {
      final keys = await getKeys(prefix);
      return await deleteBatch(keys.toList());
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        message: '删除前缀匹配的键失败: $prefix',
      );
      return false;
    }
  }
  
  // 2025-03-16 + 获取所有数据功能
  Future<Map<String, dynamic>> getAll([String? prefix]) async {
    try {
      final keys = await getKeys(prefix);
      final Map<String, dynamic> result = {};
      
      for (final key in keys) {
        final value = await read(key);
        if (value != null) {
          result[key] = value;
        }
      }
      
      return result;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        message: '获取所有存储数据失败',
      );
      return {};
    }
  }
}

/// 本地存储提供者
final localStorageProvider = Provider<LocalStorage>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  final securityService = ref.watch(securityServiceProvider);
  
  return LocalStorage(
    prefs: prefs,
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
    securityService: securityService,
  );
});
