import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/logging/logging_service.dart';
import '../../../../core/services/error/error_handling_service.dart';
import '../../../../core/services/security/security_service.dart';

/// 安全存储
class SecureStorage {
  final FlutterSecureStorage _secureStorage;
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  final SecurityService _securityService;
  
  /// 构造函数
  SecureStorage({
    required FlutterSecureStorage secureStorage,
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    required SecurityService securityService,
  })  : _secureStorage = secureStorage,
        _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _securityService = securityService;
  
  // 2025-03-16 + 读取安全数据功能
  Future<T?> read<T>(String key, {bool additionalEncryption = false}) async {
    try {
      final value = await _secureStorage.read(key: key);
      
      if (value == null) {
        return null;
      }
      
      // 如果需要额外解密
      final decryptedValue = additionalEncryption 
          ? await _securityService.decrypt(value)
          : value;
      
      if (T == String) {
        return decryptedValue as T;
      } else if (T == int) {
        return int.parse(decryptedValue) as T;
      } else if (T == double) {
        return double.parse(decryptedValue) as T;
      } else if (T == bool) {
        return (decryptedValue.toLowerCase() == 'true') as T;
      } else {
        // 复杂对象，尝试解析JSON
        try {
          return json.decode(decryptedValue) as T;
        } catch (e) {
          _loggingService.error('解析安全存储JSON失败', tags: {
            'error': e.toString(),
            'key': key,
          });
          return null;
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        message: '读取安全存储失败: $key',
      );
      return null;
    }
  }
  
  // 2025-03-16 + 写入安全数据功能
  Future<void> write<T>(
    String key, 
    T value, {
    bool additionalEncryption = false,
  }) async {
    try {
      if (value == null) {
        return;
      }
      
      String stringValue;
      
      if (value is String) {
        stringValue = value;
      } else if (value is num || value is bool) {
        stringValue = value.toString();
      } else {
        // 复杂对象，转换为JSON
        stringValue = json.encode(value);
      }
      
      // 如果需要额外加密
      final encryptedValue = additionalEncryption
          ? await _securityService.encrypt(stringValue)
          : stringValue;
      
      await _secureStorage.write(key: key, value: encryptedValue);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        message: '写入安全存储失败: $key',
      );
    }
  }
  
  // 2025-03-16 + 删除安全数据功能
  Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.low,
        message: '删除安全存储失败: $key',
      );
    }
  }
  
  // 2025-03-16 + 清空所有安全数据功能
  Future<void> clear() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.high,
        message: '清空安全存储失败',
      );
    }
  }
  
  // 2025-03-16 + 获取所有安全数据功能
  Future<Map<String, String>> getAll() async {
    try {
      return await _secureStorage.readAll();
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        message: '获取所有安全存储数据失败',
      );
      return {};
    }
  }
  
  // 2025-03-16 + 检查安全键是否存在功能
  Future<bool> exists(String key) async {
    try {
      return (await _secureStorage.read(key: key)) != null;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.low,
        message: '检查安全存储键存在失败: $key',
      );
      return false;
    }
  }
  
  // 2025-03-16 + 批量写入安全数据功能
  Future<void> writeBatch(
    Map<String, dynamic> data, {
    bool additionalEncryption = false,
  }) async {
    try {
      for (final entry in data.entries) {
        await write(
          entry.key, 
          entry.value, 
          additionalEncryption: additionalEncryption,
        );
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        message: '批量写入安全存储失败',
      );
    }
  }
  
  // 2025-03-16 + 批量删除安全数据功能
  Future<void> deleteBatch(List<String> keys) async {
    try {
      for (final key in keys) {
        await delete(key);
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        message: '批量删除安全存储失败',
      );
    }
  }
}

/// 安全存储提供者
final secureStorageProvider = Provider<SecureStorage>((ref) {
  final secureStorage = FlutterSecureStorage();
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  final securityService = ref.watch(securityServiceProvider);
  
  return SecureStorage(
    secureStorage: secureStorage,
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
    securityService: securityService,
  );
});
