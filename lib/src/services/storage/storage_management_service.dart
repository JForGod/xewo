import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../logging/logging_service.dart';
import '../error/error_handling_service.dart';

/// 存储类型
enum StorageType {
  /// 内部存储
  internal,
  
  /// 外部存储
  external,
  
  /// 网络存储
  network,
  
  /// 云存储
  cloud,
}

/// 存储状态
enum StorageState {
  /// 正常
  normal,
  
  /// 警告
  warning,
  
  /// 错误
  error,
  
  /// 不可用
  unavailable,
}

/// 存储信息
class StorageInfo {
  /// 存储类型
  final StorageType type;
  
  /// 存储状态
  final StorageState state;
  
  /// 总容量（字节）
  final int totalSpace;
  
  /// 已用空间（字节）
  final int usedSpace;
  
  /// 可用空间（字节）
  final int freeSpace;
  
  /// 使用率（百分比）
  final double usageRate;
  
  /// 挂载点
  final String mountPoint;
  
  /// 文件系统类型
  final String fileSystem;
  
  /// 读写权限
  final bool isWritable;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 构造函数
  StorageInfo({
    required this.type,
    required this.state,
    required this.totalSpace,
    required this.usedSpace,
    required this.freeSpace,
    required this.usageRate,
    required this.mountPoint,
    required this.fileSystem,
    required this.isWritable,
    this.details = const {},
  });
  
  /// 从Map创建存储信息
  factory StorageInfo.fromMap(Map<String, dynamic> map) {
    return StorageInfo(
      type: StorageType.values.byName(map['type'] as String),
      state: StorageState.values.byName(map['state'] as String),
      totalSpace: map['totalSpace'] as int,
      usedSpace: map['usedSpace'] as int,
      freeSpace: map['freeSpace'] as int,
      usageRate: map['usageRate'] as double,
      mountPoint: map['mountPoint'] as String,
      fileSystem: map['fileSystem'] as String,
      isWritable: map['isWritable'] as bool,
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'state': state.name,
      'totalSpace': totalSpace,
      'usedSpace': usedSpace,
      'freeSpace': freeSpace,
      'usageRate': usageRate,
      'mountPoint': mountPoint,
      'fileSystem': fileSystem,
      'isWritable': isWritable,
      'details': details,
    };
  }
}

/// 存储配置
class StorageConfig {
  /// 是否启用存储监控
  final bool enableStorageMonitoring;
  
  /// 监控间隔（毫秒）
  final int monitoringInterval;
  
  /// 是否启用自动清理
  final bool enableAutoCleanup;
  
  /// 空间使用率阈值（百分比）
  final double usageThreshold;
  
  /// 最小可用空间（字节）
  final int minFreeSpace;
  
  /// 清理目标目录列表
  final List<String> cleanupDirectories;
  
  /// 清理文件扩展名列表
  final List<String> cleanupExtensions;
  
  /// 最大文件保留时间（毫秒）
  final int maxFileAge;
  
  /// 构造函数
  StorageConfig({
    this.enableStorageMonitoring = true,
    this.monitoringInterval = 60000, // 1分钟
    this.enableAutoCleanup = true,
    this.usageThreshold = 90.0,
    this.minFreeSpace = 1024 * 1024 * 1024, // 1GB
    this.cleanupDirectories = const [],
    this.cleanupExtensions = const ['.tmp', '.log', '.cache'],
    this.maxFileAge = 30 * 24 * 60 * 60 * 1000, // 30天
  });
  
  /// 从Map创建配置
  factory StorageConfig.fromMap(Map<String, dynamic> map) {
    return StorageConfig(
      enableStorageMonitoring: map['enableStorageMonitoring'] ?? true,
      monitoringInterval: map['monitoringInterval'] ?? 60000,
      enableAutoCleanup: map['enableAutoCleanup'] ?? true,
      usageThreshold: map['usageThreshold'] ?? 90.0,
      minFreeSpace: map['minFreeSpace'] ?? 1024 * 1024 * 1024,
      cleanupDirectories: List<String>.from(map['cleanupDirectories'] ?? []),
      cleanupExtensions: List<String>.from(map['cleanupExtensions'] ?? [
        '.tmp',
        '.log',
        '.cache',
      ]),
      maxFileAge: map['maxFileAge'] ?? 30 * 24 * 60 * 60 * 1000,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'enableStorageMonitoring': enableStorageMonitoring,
      'monitoringInterval': monitoringInterval,
      'enableAutoCleanup': enableAutoCleanup,
      'usageThreshold': usageThreshold,
      'minFreeSpace': minFreeSpace,
      'cleanupDirectories': cleanupDirectories,
      'cleanupExtensions': cleanupExtensions,
      'maxFileAge': maxFileAge,
    };
  }
}

/// 存储管理服务
class StorageManagementService {
  /// 配置
  StorageConfig _config;
  
  /// 日志服务
  final LoggingService _loggingService;
  
  /// 错误处理服务
  final ErrorHandlingService _errorHandlingService;
  
  /// 存储信息流控制器
  final StreamController<StorageInfo> _storageController =
      StreamController<StorageInfo>.broadcast();
  
  /// 存储信息流
  Stream<StorageInfo> get storageStream => _storageController.stream;
  
  /// 定时器
  Timer? _timer;
  
  /// 存储信息缓存
  final Map<StorageType, StorageInfo> _storageInfoCache = {};
  
  /// 构造函数
  StorageManagementService({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    StorageConfig? config,
  })  : _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _config = config ?? StorageConfig() {
    _initializeMonitoring();
  }
  
  /// 初始化监控
  void _initializeMonitoring() {
    // 停止现有定时器
    _timer?.cancel();
    
    // 创建新定时器
    if (_config.enableStorageMonitoring) {
      _timer = Timer.periodic(
        Duration(milliseconds: _config.monitoringInterval),
        (_) => _monitorStorage(),
      );
    }
  }
  
  /// 监控存储
  Future<void> _monitorStorage() async {
    try {
      // 获取存储信息
      final internalInfo = await _getStorageInfo(StorageType.internal);
      final externalInfo = await _getStorageInfo(StorageType.external);
      
      // 更新缓存
      _storageInfoCache[StorageType.internal] = internalInfo;
      _storageInfoCache[StorageType.external] = externalInfo;
      
      // 发送到流
      _storageController.add(internalInfo);
      _storageController.add(externalInfo);
      
      // 检查存储状态
      _checkStorageState(internalInfo);
      _checkStorageState(externalInfo);
      
      // 检查是否需要自动清理
      if (_config.enableAutoCleanup) {
        await _checkAutoCleanup();
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '存储监控失败',
      );
    }
  }
  
  /// 获取存储信息
  Future<StorageInfo> _getStorageInfo(StorageType type) async {
    try {
      // TODO: 实现存储信息获取
      return StorageInfo(
        type: type,
        state: StorageState.normal,
        totalSpace: 0,
        usedSpace: 0,
        freeSpace: 0,
        usageRate: 0.0,
        mountPoint: '',
        fileSystem: '',
        isWritable: true,
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '获取存储信息失败',
      );
      rethrow;
    }
  }
  
  /// 检查存储状态
  void _checkStorageState(StorageInfo info) {
    if (info.freeSpace < _config.minFreeSpace) {
      _loggingService.warning(
        '存储空间不足',
        tags: {
          'type': info.type.name,
          'free_space': info.freeSpace.toString(),
          'min_free_space': _config.minFreeSpace.toString(),
        },
      );
    }
    
    if (info.usageRate >= _config.usageThreshold) {
      _loggingService.warning(
        '存储使用率过高',
        tags: {
          'type': info.type.name,
          'usage_rate': info.usageRate.toString(),
          'threshold': _config.usageThreshold.toString(),
        },
      );
    }
  }
  
  /// 检查是否需要自动清理
  Future<void> _checkAutoCleanup() async {
    final info = _storageInfoCache[StorageType.internal];
    if (info == null) {
      return;
    }
    
    if (info.usageRate >= _config.usageThreshold ||
        info.freeSpace < _config.minFreeSpace) {
      await cleanupStorage();
    }
  }
  
  /// 清理存储
  Future<void> cleanupStorage() async {
    try {
      int totalCleaned = 0;
      
      for (final dir in _config.cleanupDirectories) {
        final directory = Directory(dir);
        if (!directory.existsSync()) {
          continue;
        }
        
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File) {
            final extension = path.extension(entity.path).toLowerCase();
            
            if (_config.cleanupExtensions.contains(extension)) {
              final stat = await entity.stat();
              final age = DateTime.now().difference(stat.modified).inMilliseconds;
              
              if (age > _config.maxFileAge) {
                final size = stat.size;
                await entity.delete();
                totalCleaned += size;
                
                _loggingService.info(
                  '清理文件',
                  tags: {
                    'path': entity.path,
                    'size': size.toString(),
                    'age': age.toString(),
                  },
                );
              }
            }
          }
        }
      }
      
      _loggingService.info(
        '存储清理完成',
        tags: {
          'total_cleaned': totalCleaned.toString(),
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '存储清理失败',
      );
      rethrow;
    }
  }
  
  /// 获取文件信息
  Future<FileSystemEntity?> getFileInfo(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return file;
      }
      
      final directory = Directory(path);
      if (await directory.exists()) {
        return directory;
      }
      
      return null;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '获取文件信息失败',
      );
      return null;
    }
  }
  
  /// 创建目录
  Future<Directory> createDirectory(String path) async {
    try {
      final directory = Directory(path);
      return await directory.create(recursive: true);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '创建目录失败',
      );
      rethrow;
    }
  }
  
  /// 删除文件或目录
  Future<void> delete(String path, {bool recursive = false}) async {
    try {
      final entity = await getFileInfo(path);
      if (entity == null) {
        return;
      }
      
      if (entity is File) {
        await entity.delete();
      } else if (entity is Directory) {
        await entity.delete(recursive: recursive);
      }
      
      _loggingService.info(
        '删除文件',
        tags: {
          'path': path,
          'type': entity is File ? 'file' : 'directory',
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '删除失败',
      );
      rethrow;
    }
  }
  
  /// 移动文件或目录
  Future<void> move(String sourcePath, String targetPath) async {
    try {
      final source = await getFileInfo(sourcePath);
      if (source == null) {
        throw Exception('源文件不存在');
      }
      
      await source.rename(targetPath);
      
      _loggingService.info(
        '移动文件',
        tags: {
          'source': sourcePath,
          'target': targetPath,
          'type': source is File ? 'file' : 'directory',
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '移动失败',
      );
      rethrow;
    }
  }
  
  /// 复制文件
  Future<void> copyFile(String sourcePath, String targetPath) async {
    try {
      final source = File(sourcePath);
      final target = File(targetPath);
      
      await source.copy(targetPath);
      
      _loggingService.info(
        '复制文件',
        tags: {
          'source': sourcePath,
          'target': targetPath,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '复制失败',
      );
      rethrow;
    }
  }
  
  /// 获取目录内容
  Future<List<FileSystemEntity>> listDirectory(
    String path, {
    bool recursive = false,
  }) async {
    try {
      final directory = Directory(path);
      final entities = <FileSystemEntity>[];
      
      await for (final entity in directory.list(recursive: recursive)) {
        entities.add(entity);
      }
      
      return entities;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '获取目录内容失败',
      );
      rethrow;
    }
  }
  
  /// 搜索文件
  Future<List<FileSystemEntity>> searchFiles(
    String directory,
    String pattern, {
    bool recursive = true,
  }) async {
    try {
      final entities = <FileSystemEntity>[];
      final regexp = RegExp(pattern);
      
      await for (final entity in Directory(directory).list(recursive: recursive)) {
        if (regexp.hasMatch(path.basename(entity.path))) {
          entities.add(entity);
        }
      }
      
      return entities;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '搜索文件失败',
      );
      rethrow;
    }
  }
  
  /// 获取当前存储信息
  StorageInfo? getStorageInfo(StorageType type) {
    return _storageInfoCache[type];
  }
  
  /// 获取所有存储信息
  List<StorageInfo> getAllStorageInfo() {
    return List.unmodifiable(_storageInfoCache.values);
  }
  
  /// 更新配置
  void updateConfig(StorageConfig config) {
    _config = config;
    _initializeMonitoring();
  }
  
  /// 获取当前配置
  StorageConfig getConfig() {
    return _config;
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    _timer?.cancel();
    await _storageController.close();
  }
}

/// 存储管理服务提供者
final storageManagementServiceProvider = Provider<StorageManagementService>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final service = StorageManagementService(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 存储信息流提供者
final storageInfoStreamProvider = StreamProvider<StorageInfo>((ref) {
  final service = ref.watch(storageManagementServiceProvider);
  return service.storageStream;
}); 