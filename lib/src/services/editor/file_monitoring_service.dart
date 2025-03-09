import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

/// 文件监控服务提供者
final fileMonitoringServiceProvider = Provider<FileMonitoringService>((ref) {
  throw UnimplementedError('fileMonitoringServiceProvider 未初始化');
});

/// 文件变化类型
enum FileChangeType {
  /// 创建文件
  created,
  
  /// 修改文件
  modified,
  
  /// 删除文件
  deleted,
  
  /// 重命名文件
  renamed,
}

/// 文件变化事件
class FileChangeEvent {
  /// 文件路径
  final String path;
  
  /// 变化类型
  final FileChangeType type;
  
  /// 新路径（对于重命名事件）
  final String? newPath;
  
  /// 事件时间
  final DateTime timestamp;
  
  FileChangeEvent({
    required this.path,
    required this.type,
    this.newPath,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  @override
  String toString() => 'FileChangeEvent(path: $path, type: $type, newPath: $newPath, timestamp: $timestamp)';
}

/// 文件监控服务，用于监视文件系统变化
class FileMonitoringService {
  /// 监控中的目录
  final Map<String, StreamSubscription<FileSystemEvent>> _watchers = {};
  
  /// 文件变化流控制器
  final StreamController<FileChangeEvent> _changeController = StreamController<FileChangeEvent>.broadcast();
  
  /// 自动保存控制器
  Timer? _autoSaveTimer;
  
  /// 是否启用自动保存
  bool _autoSaveEnabled = false;
  
  /// 自动保存间隔（秒）
  int _autoSaveInterval = 30;
  
  /// 自动保存回调函数
  VoidCallback? _autoSaveCallback;
  
  /// 发布的文件变化流
  Stream<FileChangeEvent> get changes => _changeController.stream;
  
  /// 析构函数
  void dispose() {
    _stopAllWatchers();
    _changeController.close();
    _autoSaveTimer?.cancel();
  }
  
  /// 监控目录变化
  Future<bool> watchDirectory(String directoryPath) async {
    if (_watchers.containsKey(directoryPath)) {
      return true; // 已经在监控
    }
    
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        debugPrint('目录不存在: $directoryPath');
        return false;
      }
      
      final subscription = directory.watch(recursive: true).listen((event) {
        _handleFileSystemEvent(event);
      });
      
      _watchers[directoryPath] = subscription;
      debugPrint('开始监控目录: $directoryPath');
      return true;
    } catch (e) {
      debugPrint('监控目录失败: $e');
      return false;
    }
  }
  
  /// 停止监控目录
  Future<bool> unwatchDirectory(String directoryPath) async {
    final subscription = _watchers.remove(directoryPath);
    if (subscription != null) {
      await subscription.cancel();
      debugPrint('停止监控目录: $directoryPath');
      return true;
    }
    return false;
  }
  
  /// 停止所有监控
  Future<void> _stopAllWatchers() async {
    for (final subscription in _watchers.values) {
      await subscription.cancel();
    }
    _watchers.clear();
    debugPrint('停止所有目录监控');
  }
  
  /// 处理文件系统事件
  void _handleFileSystemEvent(FileSystemEvent event) {
    late FileChangeType changeType;
    String? newPath;
    
    switch (event.type) {
      case FileSystemEvent.create:
        changeType = FileChangeType.created;
        break;
      case FileSystemEvent.modify:
        changeType = FileChangeType.modified;
        break;
      case FileSystemEvent.delete:
        changeType = FileChangeType.deleted;
        break;
      case FileSystemEvent.move:
        changeType = FileChangeType.renamed;
        if (event is FileSystemMoveEvent) {
          newPath = event.destination;
        }
        break;
      default:
        return; // 忽略其他事件
    }
    
    // 检查是否是目录
    final isDirectory = FileSystemEntity.isDirectorySync(event.path);
    if (isDirectory) {
      return; // 忽略目录事件
    }
    
    _changeController.add(FileChangeEvent(
      path: event.path,
      type: changeType,
      newPath: newPath,
    ));
  }
  
  /// 检查文件是否被外部修改
  Future<bool> isFileModifiedExternally(String filePath, DateTime lastSyncTime) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      
      final fileStats = await file.stat();
      return fileStats.modified.isAfter(lastSyncTime);
    } catch (e) {
      debugPrint('检查文件修改失败: $e');
      return false;
    }
  }
  
  /// 启用自动保存
  void enableAutoSave({
    required VoidCallback callback,
    int intervalSeconds = 30,
  }) {
    _autoSaveEnabled = true;
    _autoSaveInterval = intervalSeconds;
    _autoSaveCallback = callback;
    
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      Duration(seconds: _autoSaveInterval),
      (_) => _autoSaveCallback?.call(),
    );
    
    debugPrint('启用自动保存，间隔: ${_autoSaveInterval}秒');
  }
  
  /// 禁用自动保存
  void disableAutoSave() {
    _autoSaveEnabled = false;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _autoSaveCallback = null;
    
    debugPrint('禁用自动保存');
  }
  
  /// 手动触发保存
  void triggerSave() {
    _autoSaveCallback?.call();
  }
  
  /// 获取目录下的文件列表
  Future<List<FileSystemEntity>> getDirectoryContents(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return [];
      }
      
      final entities = await directory.list().toList();
      return entities;
    } catch (e) {
      debugPrint('获取目录内容失败: $e');
      return [];
    }
  }
  
  /// 监控特定类型的文件
  Future<bool> watchFilesByExtension(String directoryPath, List<String> extensions) async {
    final success = await watchDirectory(directoryPath);
    if (!success) return false;
    
    // 过滤文件类型
    _changeController.stream
      .where((event) {
        final fileExt = path.extension(event.path).toLowerCase();
        return extensions.contains(fileExt);
      })
      .listen((event) {
        // 特定类型文件的变化处理
        debugPrint('监测到类型 ${path.extension(event.path)} 文件变化: ${event.path}');
      });
      
    return true;
  }
  
  /// 自动同步文件变化
  Future<void> syncFileWithDisk(String filePath, Future<String> Function() getContent,
      Future<void> Function(String) setContent) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        // 文件不存在，保存当前内容
        await file.writeAsString(await getContent());
        return;
      }
      
      // 读取磁盘上的内容
      final diskContent = await file.readAsString();
      final memoryContent = await getContent();
      
      if (diskContent != memoryContent) {
        // 内容不同，需要合并或选择
        // 这里简单地用磁盘内容覆盖内存内容，实际应用中可能需要更复杂的合并逻辑
        await setContent(diskContent);
        debugPrint('已同步文件内容: $filePath');
      }
    } catch (e) {
      debugPrint('同步文件失败: $e');
    }
  }
  
  /// 版本控制集成 - 检查文件状态
  Future<String> getFileVersionStatus(String filePath) async {
    try {
      final result = await Process.run('git', ['status', '--porcelain', filePath]);
      
      if (result.exitCode != 0) {
        return 'unknown';
      }
      
      final output = result.stdout.toString().trim();
      if (output.isEmpty) {
        return 'unchanged';
      }
      
      final status = output.substring(0, 2).trim();
      switch (status) {
        case 'M':
          return 'modified';
        case 'A':
          return 'added';
        case 'D':
          return 'deleted';
        case '??':
          return 'untracked';
        default:
          return status;
      }
    } catch (e) {
      debugPrint('获取版本状态失败: $e');
      return 'unknown';
    }
  }
  
  /// 版本控制集成 - 提交文件
  Future<bool> commitFile(String filePath, String message) async {
    try {
      // 添加文件
      var result = await Process.run('git', ['add', filePath]);
      if (result.exitCode != 0) {
        debugPrint('git add 失败: ${result.stderr}');
        return false;
      }
      
      // 提交文件
      result = await Process.run('git', ['commit', '-m', message, filePath]);
      if (result.exitCode != 0) {
        debugPrint('git commit 失败: ${result.stderr}');
        return false;
      }
      
      debugPrint('提交文件成功: $filePath');
      return true;
    } catch (e) {
      debugPrint('提交文件失败: $e');
      return false;
    }
  }
} 