import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../error/error_handling_service.dart';
import '../logging/logging_service.dart';

/// 缓存类型
enum CacheType {
  /// 内存缓存
  memory,
  
  /// 持久化缓存
  persistent,
  
  /// 会话缓存
  session,
}

/// 缓存策略
enum CacheStrategy {
  /// 先进先出
  fifo,
  
  /// 最近最少使用
  lru,
  
  /// 最不经常使用
  lfu,
}

/// 缓存条目
class CacheEntry<T> {
  /// 键
  final String key;
  
  /// 值
  final T value;
  
  /// 类型
  final CacheType type;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;
  
  /// 过期时间
  final DateTime? expiresAt;
  
  /// 访问次数
  final int accessCount;
  
  /// 大小（字节）
  final int size;
  
  /// 标签
  final List<String> tags;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 构造函数
  CacheEntry({
    required this.key,
    required this.value,
    required this.type,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.expiresAt,
    this.accessCount = 0,
    required this.size,
    this.tags = const [],
    this.details = const {},
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  /// 从Map创建缓存条目
  factory CacheEntry.fromMap(Map<String, dynamic> map) {
    return CacheEntry(
      key: map['key'] as String,
      value: map['value'] as T,
      type: CacheType.values.byName(map['type'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
      accessCount: map['accessCount'] as int? ?? 0,
      size: map['size'] as int,
      tags: List<String>.from(map['tags'] ?? []),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'accessCount': accessCount,
      'size': size,
      'tags': tags,
      'details': details,
    };
  }
  
  /// 检查是否过期
  bool isExpired() {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }
  
  /// 创建更新后的条目
  CacheEntry<T> withUpdates({
    T? value,
    DateTime? updatedAt,
    DateTime? expiresAt,
    int? accessCount,
    int? size,
    List<String>? tags,
    Map<String, dynamic>? details,
  }) {
    return CacheEntry<T>(
      key: key,
      value: value ?? this.value,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      expiresAt: expiresAt ?? this.expiresAt,
      accessCount: accessCount ?? this.accessCount,
      size: size ?? this.size,
      tags: tags ?? this.tags,
      details: details ?? this.details,
    );
  }
}

/// 缓存配置
class CacheConfig {
  /// 是否启用缓存
  final bool enabled;
  
  /// 最大内存缓存大小（字节）
  final int maxMemorySize;
  
  /// 最大持久化缓存大小（字节）
  final int maxPersistentSize;
  
  /// 最大会话缓存大小（字节）
  final int maxSessionSize;
  
  /// 默认过期时间（毫秒）
  final int defaultTtl;
  
  /// 清理间隔（毫秒）
  final int cleanupInterval;
  
  /// 缓存策略
  final CacheStrategy strategy;
  
  /// 是否启用压缩
  final bool enableCompression;
  
  /// 是否启用加密
  final bool enableEncryption;
  
  /// 构造函数
  CacheConfig({
    this.enabled = true,
    this.maxMemorySize = 100 * 1024 * 1024, // 100MB
    this.maxPersistentSize = 1024 * 1024 * 1024, // 1GB
    this.maxSessionSize = 50 * 1024 * 1024, // 50MB
    this.defaultTtl = 24 * 60 * 60 * 1000, // 24小时
    this.cleanupInterval = 60 * 1000, // 1分钟
    this.strategy = CacheStrategy.lru,
    this.enableCompression = true,
    this.enableEncryption = false,
  });
  
  /// 从Map创建配置
  factory CacheConfig.fromMap(Map<String, dynamic> map) {
    return CacheConfig(
      enabled: map['enabled'] ?? true,
      maxMemorySize: map['maxMemorySize'] ?? 100 * 1024 * 1024,
      maxPersistentSize: map['maxPersistentSize'] ?? 1024 * 1024 * 1024,
      maxSessionSize: map['maxSessionSize'] ?? 50 * 1024 * 1024,
      defaultTtl: map['defaultTtl'] ?? 24 * 60 * 60 * 1000,
      cleanupInterval: map['cleanupInterval'] ?? 60 * 1000,
      strategy: CacheStrategy.values.byName(map['strategy'] ?? 'lru'),
      enableCompression: map['enableCompression'] ?? true,
      enableEncryption: map['enableEncryption'] ?? false,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'maxMemorySize': maxMemorySize,
      'maxPersistentSize': maxPersistentSize,
      'maxSessionSize': maxSessionSize,
      'defaultTtl': defaultTtl,
      'cleanupInterval': cleanupInterval,
      'strategy': strategy.name,
      'enableCompression': enableCompression,
      'enableEncryption': enableEncryption,
    };
  }
}

/// 缓存管理服务
class CacheManagementService {
  /// 配置
  CacheConfig _config;
  
  /// 日志服务
  final LoggingService _loggingService;
  
  /// 错误处理服务
  final ErrorHandlingService _errorHandlingService;
  
  /// 内存缓存
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};
  
  /// 持久化缓存
  final Map<String, CacheEntry<dynamic>> _persistentCache = {};
  
  /// 会话缓存
  final Map<String, CacheEntry<dynamic>> _sessionCache = {};
  
  /// 缓存变更流控制器
  final StreamController<CacheEntry<dynamic>> _cacheController =
      StreamController<CacheEntry<dynamic>>.broadcast();
  
  /// 缓存变更流
  Stream<CacheEntry<dynamic>> get cacheStream => _cacheController.stream;
  
  /// 定时器
  Timer? _timer;
  
  /// 构造函数
  CacheManagementService({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    CacheConfig? config,
  })  : _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _config = config ?? CacheConfig() {
    _initializeService();
  }
  
  /// 初始化服务
  void _initializeService() {
    if (_config.enabled) {
      // 启动定时清理
      _timer = Timer.periodic(
        Duration(milliseconds: _config.cleanupInterval),
        (_) => _cleanup(),
      );
    }
  }
  
  /// 清理缓存
  Future<void> _cleanup() async {
    try {
      final now = DateTime.now();
      
      // 清理过期条目
      _memoryCache.removeWhere((_, entry) => entry.isExpired());
      _persistentCache.removeWhere((_, entry) => entry.isExpired());
      _sessionCache.removeWhere((_, entry) => entry.isExpired());
      
      // 根据策略清理
      _cleanupByStrategy();
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '清理缓存失败',
      );
    }
  }
  
  /// 根据策略清理缓存
  void _cleanupByStrategy() {
    switch (_config.strategy) {
      case CacheStrategy.fifo:
        _cleanupFifo();
        break;
      case CacheStrategy.lru:
        _cleanupLru();
        break;
      case CacheStrategy.lfu:
        _cleanupLfu();
        break;
    }
  }
  
  /// 先进先出清理
  void _cleanupFifo() {
    // 按创建时间排序
    final sortByCreatedAt = (CacheEntry<dynamic> a, CacheEntry<dynamic> b) =>
        a.createdAt.compareTo(b.createdAt);
    
    _cleanupCache(_memoryCache, _config.maxMemorySize, sortByCreatedAt);
    _cleanupCache(_persistentCache, _config.maxPersistentSize, sortByCreatedAt);
    _cleanupCache(_sessionCache, _config.maxSessionSize, sortByCreatedAt);
  }
  
  /// 最近最少使用清理
  void _cleanupLru() {
    // 按更新时间排序
    final sortByUpdatedAt = (CacheEntry<dynamic> a, CacheEntry<dynamic> b) =>
        a.updatedAt.compareTo(b.updatedAt);
    
    _cleanupCache(_memoryCache, _config.maxMemorySize, sortByUpdatedAt);
    _cleanupCache(_persistentCache, _config.maxPersistentSize, sortByUpdatedAt);
    _cleanupCache(_sessionCache, _config.maxSessionSize, sortByUpdatedAt);
  }
  
  /// 最不经常使用清理
  void _cleanupLfu() {
    // 按访问次数排序
    final sortByAccessCount = (CacheEntry<dynamic> a, CacheEntry<dynamic> b) =>
        a.accessCount.compareTo(b.accessCount);
    
    _cleanupCache(_memoryCache, _config.maxMemorySize, sortByAccessCount);
    _cleanupCache(_persistentCache, _config.maxPersistentSize, sortByAccessCount);
    _cleanupCache(_sessionCache, _config.maxSessionSize, sortByAccessCount);
  }
  
  /// 清理缓存
  void _cleanupCache(
    Map<String, CacheEntry<dynamic>> cache,
    int maxSize,
    int Function(CacheEntry<dynamic>, CacheEntry<dynamic>) compare,
  ) {
    // 计算当前大小
    final currentSize = cache.values.fold<int>(
      0,
      (sum, entry) => sum + entry.size,
    );
    
    if (currentSize > maxSize) {
      // 按策略排序
      final entries = cache.values.toList()..sort(compare);
      
      // 移除条目直到大小合适
      var size = currentSize;
      for (final entry in entries) {
        if (size <= maxSize) {
          break;
        }
        cache.remove(entry.key);
        size -= entry.size;
      }
    }
  }
  
  /// 获取缓存
  Map<String, CacheEntry<dynamic>> _getCacheByType(CacheType type) {
    switch (type) {
      case CacheType.memory:
        return _memoryCache;
      case CacheType.persistent:
        return _persistentCache;
      case CacheType.session:
        return _sessionCache;
    }
  }
  
  /// 设置缓存
  Future<void> set<T>(
    String key,
    T value,
    CacheType type, {
    Duration? ttl,
    List<String>? tags,
    Map<String, dynamic>? details,
  }) async {
    if (!_config.enabled) {
      return;
    }
    
    try {
      final cache = _getCacheByType(type);
      
      // 计算大小
      final size = _calculateSize(value);
      
      // 创建条目
      final entry = CacheEntry<T>(
        key: key,
        value: value,
        type: type,
        expiresAt: ttl != null
            ? DateTime.now().add(ttl)
            : DateTime.now().add(Duration(milliseconds: _config.defaultTtl)),
        size: size,
        tags: tags ?? [],
        details: details ?? {},
      );
      
      // 保存条目
      cache[key] = entry;
      
      // 发送到流
      _cacheController.add(entry);
      
      _loggingService.info(
        '设置缓存',
        tags: {
          'key': key,
          'type': type.name,
          'size': size.toString(),
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '设置缓存失败',
      );
      rethrow;
    }
  }
  
  /// 获取缓存
  T? get<T>(String key, CacheType type) {
    if (!_config.enabled) {
      return null;
    }
    
    final cache = _getCacheByType(type);
    final entry = cache[key];
    
    if (entry == null || entry.isExpired()) {
      cache.remove(key);
      return null;
    }
    
    // 更新访问信息
    cache[key] = entry.withUpdates(
      updatedAt: DateTime.now(),
      accessCount: entry.accessCount + 1,
    );
    
    return entry.value as T;
  }
  
  /// 删除缓存
  Future<void> remove(String key, CacheType type) async {
    if (!_config.enabled) {
      return;
    }
    
    try {
      final cache = _getCacheByType(type);
      cache.remove(key);
      
      _loggingService.info(
        '删除缓存',
        tags: {
          'key': key,
          'type': type.name,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '删除缓存失败',
      );
      rethrow;
    }
  }
  
  /// 清空缓存
  Future<void> clear(CacheType type) async {
    if (!_config.enabled) {
      return;
    }
    
    try {
      final cache = _getCacheByType(type);
      cache.clear();
      
      _loggingService.info(
        '清空缓存',
        tags: {
          'type': type.name,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '清空缓存失败',
      );
      rethrow;
    }
  }
  
  /// 获取所有缓存
  List<CacheEntry<dynamic>> getAll(CacheType type) {
    if (!_config.enabled) {
      return [];
    }
    
    final cache = _getCacheByType(type);
    return List.unmodifiable(cache.values);
  }
  
  /// 获取带标签的缓存
  List<CacheEntry<dynamic>> getByTags(CacheType type, List<String> tags) {
    if (!_config.enabled) {
      return [];
    }
    
    final cache = _getCacheByType(type);
    return cache.values
        .where((entry) => tags.every((tag) => entry.tags.contains(tag)))
        .toList();
  }
  
  /// 计算大小
  int _calculateSize(dynamic value) {
    if (value == null) {
      return 0;
    }
    
    if (value is String) {
      return utf8.encode(value).length;
    }
    
    if (value is List || value is Map) {
      return utf8.encode(json.encode(value)).length;
    }
    
    if (value is num) {
      return 8;
    }
    
    if (value is bool) {
      return 1;
    }
    
    return 0;
  }
  
  /// 更新配置
  void updateConfig(CacheConfig config) {
    _config = config;
    _initializeService();
  }
  
  /// 获取当前配置
  CacheConfig getConfig() {
    return _config;
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    _timer?.cancel();
    await _cacheController.close();
  }
}

/// 缓存管理服务提供者
final cacheManagementServiceProvider = Provider<CacheManagementService>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final service = CacheManagementService(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 缓存变更流提供者
final cacheStreamProvider = StreamProvider<CacheEntry<dynamic>>((ref) {
  final service = ref.watch(cacheManagementServiceProvider);
  return service.cacheStream;
});