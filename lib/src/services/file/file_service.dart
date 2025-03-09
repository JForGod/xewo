import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 文件服务类，提供文件操作功能
class FileService {
  /// 读取文件内容
  Future<String> readFile(String filePath) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        throw UnimplementedError('Web平台暂不支持文件操作');
      } else {
        // 桌面平台实现
        final file = File(filePath);
        return await file.readAsString();
      }
    } catch (e) {
      throw Exception('读取文件失败: $e');
    }
  }

  /// 写入文件内容
  Future<void> writeFile(String filePath, String content) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        throw UnimplementedError('Web平台暂不支持文件操作');
      } else {
        // 桌面平台实现
        final file = File(filePath);
        
        // 确保目录存在
        final directory = path.dirname(filePath);
        await Directory(directory).create(recursive: true);
        
        await file.writeAsString(content);
      }
    } catch (e) {
      throw Exception('写入文件失败: $e');
    }
  }

  /// 删除文件
  Future<void> deleteFile(String filePath) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        throw UnimplementedError('Web平台暂不支持文件操作');
      } else {
        // 桌面平台实现
        final file = File(filePath);
        await file.delete();
      }
    } catch (e) {
      throw Exception('删除文件失败: $e');
    }
  }

  /// 创建目录
  Future<void> createDirectory(String directoryPath) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        throw UnimplementedError('Web平台暂不支持文件操作');
      } else {
        // 桌面平台实现
        final directory = Directory(directoryPath);
        await directory.create(recursive: true);
      }
    } catch (e) {
      throw Exception('创建目录失败: $e');
    }
  }

  /// 列出目录内容
  Future<List<FileSystemEntity>> listDirectory(String directoryPath) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        throw UnimplementedError('Web平台暂不支持文件操作');
      } else {
        // 桌面平台实现
        final directory = Directory(directoryPath);
        return await directory.list().toList();
      }
    } catch (e) {
      throw Exception('列出目录内容失败: $e');
    }
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String filePath) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        throw UnimplementedError('Web平台暂不支持文件操作');
      } else {
        // 桌面平台实现
        final file = File(filePath);
        return await file.exists();
      }
    } catch (e) {
      throw Exception('检查文件是否存在失败: $e');
    }
  }

  /// 获取文件信息
  Future<FileStat> getFileStat(String filePath) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        throw UnimplementedError('Web平台暂不支持文件操作');
      } else {
        // 桌面平台实现
        final file = File(filePath);
        return await file.stat();
      }
    } catch (e) {
      throw Exception('获取文件信息失败: $e');
    }
  }

  /// 复制文件
  Future<void> copyFile(String sourcePath, String destinationPath) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        throw UnimplementedError('Web平台暂不支持文件操作');
      } else {
        // 桌面平台实现
        final sourceFile = File(sourcePath);
        await sourceFile.copy(destinationPath);
      }
    } catch (e) {
      throw Exception('复制文件失败: $e');
    }
  }

  /// 移动文件
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        throw UnimplementedError('Web平台暂不支持文件操作');
      } else {
        // 桌面平台实现
        final sourceFile = File(sourcePath);
        await sourceFile.rename(destinationPath);
      }
    } catch (e) {
      throw Exception('移动文件失败: $e');
    }
  }

  /// 获取文件大小
  Future<int> getFileSize(String filePath) async {
    try {
      if (kIsWeb) {
        // Web平台实现
        throw UnimplementedError('Web平台暂不支持文件操作');
      } else {
        // 桌面平台实现
        final file = File(filePath);
        return await file.length();
      }
    } catch (e) {
      throw Exception('获取文件大小失败: $e');
    }
  }

  /// 获取文件名
  String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// 获取目录路径
  String getDirectoryPath(String filePath) {
    return path.dirname(filePath);
  }

  /// 获取文件扩展名
  String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase().replaceFirst('.', '');
  }

  /// 获取不带扩展名的文件名
  String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// 组合路径
  String joinPaths(String path1, String path2) {
    return path.join(path1, path2);
  }
}

/// 文件服务提供者
final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
}); 