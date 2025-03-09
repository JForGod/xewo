import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 文件信息
class FileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime lastModified;
  final bool isDirectory;
  
  const FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.lastModified,
    required this.isDirectory,
  });
}

/// 文件系统服务类，提供文件操作功能
class FileSystemService {
  final String rootPath;
  
  FileSystemService({required this.rootPath});
  
  /// 列出目录内容
  Future<List<FileSystemEntity>> listDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        throw Exception('目录不存在: $directoryPath');
      }
      return await directory.list().toList();
    } catch (e) {
      throw Exception('列出目录内容失败: $e');
    }
  }
  
  /// 读取文件内容
  Future<String> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }
      return await file.readAsString();
    } catch (e) {
      throw Exception('读取文件失败: $e');
    }
  }
  
  /// 写入文件内容
  Future<void> writeFile(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
    } catch (e) {
      throw Exception('写入文件失败: $e');
    }
  }
  
  /// 创建目录
  Future<void> createDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        throw Exception('目录已存在: $directoryPath');
      }
      await directory.create(recursive: true);
    } catch (e) {
      throw Exception('创建目录失败: $e');
    }
  }
  
  /// 创建文件
  Future<void> createFile(String filePath, [String content = '']) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        throw Exception('文件已存在: $filePath');
      }
      await file.create(recursive: true);
      if (content.isNotEmpty) {
        await file.writeAsString(content);
      }
    } catch (e) {
      throw Exception('创建文件失败: $e');
    }
  }
  
  /// 删除文件
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }
      await file.delete();
    } catch (e) {
      throw Exception('删除文件失败: $e');
    }
  }
  
  /// 删除目录
  Future<void> deleteDirectory(String directoryPath, {bool recursive = true}) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        throw Exception('目录不存在: $directoryPath');
      }
      await directory.delete(recursive: recursive);
    } catch (e) {
      throw Exception('删除目录失败: $e');
    }
  }
  
  /// 移动文件
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('源文件不存在: $sourcePath');
      }
      
      // 确保目标目录存在
      final destinationDir = path.dirname(destinationPath);
      final destinationDirectory = Directory(destinationDir);
      if (!await destinationDirectory.exists()) {
        await destinationDirectory.create(recursive: true);
      }
      
      await sourceFile.rename(destinationPath);
    } catch (e) {
      throw Exception('移动文件失败: $e');
    }
  }
  
  /// 移动目录
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {
    try {
      final sourceDirectory = Directory(sourcePath);
      if (!await sourceDirectory.exists()) {
        throw Exception('源目录不存在: $sourcePath');
      }
      
      // 确保目标父目录存在
      final destinationParent = path.dirname(destinationPath);
      final destinationParentDir = Directory(destinationParent);
      if (!await destinationParentDir.exists()) {
        await destinationParentDir.create(recursive: true);
      }
      
      await sourceDirectory.rename(destinationPath);
    } catch (e) {
      throw Exception('移动目录失败: $e');
    }
  }
  
  /// 移动文件或目录
  Future<void> moveFileOrDirectory(String sourcePath, String destinationPath) async {
    final sourceEntity = await FileSystemEntity.type(sourcePath);
    
    if (sourceEntity == FileSystemEntityType.file) {
      await moveFile(sourcePath, destinationPath);
    } else if (sourceEntity == FileSystemEntityType.directory) {
      await moveDirectory(sourcePath, destinationPath);
    } else {
      throw Exception('不支持的文件类型: $sourcePath');
    }
  }
  
  /// 复制文件
  Future<void> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('源文件不存在: $sourcePath');
      }
      
      // 确保目标目录存在
      final destinationDir = path.dirname(destinationPath);
      final destinationDirectory = Directory(destinationDir);
      if (!await destinationDirectory.exists()) {
        await destinationDirectory.create(recursive: true);
      }
      
      await sourceFile.copy(destinationPath);
    } catch (e) {
      throw Exception('复制文件失败: $e');
    }
  }
  
  /// 复制目录
  Future<void> copyDirectory(String sourcePath, String destinationPath) async {
    try {
      final sourceDirectory = Directory(sourcePath);
      if (!await sourceDirectory.exists()) {
        throw Exception('源目录不存在: $sourcePath');
      }
      
      // 创建目标目录
      final destinationDirectory = Directory(destinationPath);
      if (!await destinationDirectory.exists()) {
        await destinationDirectory.create(recursive: true);
      }
      
      // 复制目录内容
      await for (final entity in sourceDirectory.list(recursive: false)) {
        final entityName = path.basename(entity.path);
        final newPath = path.join(destinationPath, entityName);
        
        if (entity is File) {
          await copyFile(entity.path, newPath);
        } else if (entity is Directory) {
          await copyDirectory(entity.path, newPath);
        }
      }
    } catch (e) {
      throw Exception('复制目录失败: $e');
    }
  }
  
  /// 检查文件是否存在
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
  
  /// 检查目录是否存在
  Future<bool> directoryExists(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      return await directory.exists();
    } catch (e) {
      return false;
    }
  }
  
  /// 获取文件大小
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }
      return await file.length();
    } catch (e) {
      throw Exception('获取文件大小失败: $e');
    }
  }
  
  /// 获取文件修改时间
  Future<DateTime> getFileModifiedTime(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }
      return await file.lastModified();
    } catch (e) {
      throw Exception('获取文件修改时间失败: $e');
    }
  }
  
  /// 获取文件信息
  Future<FileInfo> getFileInfo(String path) async {
    try {
      final file = File(path);
      final stat = await file.stat();
      return FileInfo(
        path: path,
        name: path.split('/').last,
        size: stat.size,
        lastModified: stat.modified,
        isDirectory: file is Directory,
      );
    } catch (e) {
      throw Exception('获取文件信息失败: $e');
    }
  }
  
  /// 检查文件或目录是否存在
  Future<bool> exists(String path) async {
    return await FileSystemEntity.isDirectory(path) || 
           await FileSystemEntity.isFile(path);
  }
}

/// 文件系统服务提供者
final fileSystemProvider = Provider<FileSystemService>((ref) {
  return FileSystemService(rootPath: 'H:/AxE/xewo');
}); 