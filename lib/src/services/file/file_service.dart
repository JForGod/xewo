import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

/// 文件服务
class FileService {
  /// 列出目录内容
  Future<List<FileSystemEntity>> listDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw Exception('目录不存在');
    }
    
    return directory.list().toList();
  }
  
  /// 读取文件内容
  Future<String> readFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在');
    }
    
    return file.readAsString();
  }
  
  /// 写入文件内容
  Future<void> writeFile(String filePath, String content) async {
    final file = File(filePath);
    await file.writeAsString(content);
  }
  
  /// 创建文件
  Future<void> createFile(String filePath, String content) async {
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }
  
  /// 创建目录
  Future<void> createDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    await directory.create(recursive: true);
  }
  
  /// 删除文件
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// 删除目录
  Future<void> deleteDirectory(String directoryPath, {bool recursive = true}) async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await directory.delete(recursive: recursive);
    }
  }
  
  /// 重命名文件或目录
  Future<void> rename(String oldPath, String newPath) async {
    final entity = await FileSystemEntity.type(oldPath);
    
    if (entity == FileSystemEntityType.file) {
      final file = File(oldPath);
      await file.rename(newPath);
    } else if (entity == FileSystemEntityType.directory) {
      final directory = Directory(oldPath);
      await directory.rename(newPath);
    } else {
      throw Exception('不支持的文件类型');
    }
  }
  
  /// 复制文件
  Future<void> copyFile(String sourcePath, String targetPath) async {
    final sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);
  }
  
  /// 移动文件
  Future<void> moveFile(String sourcePath, String targetPath) async {
    final sourceFile = File(sourcePath);
    await sourceFile.rename(targetPath);
  }
  
  /// 检查文件是否存在
  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return file.exists();
  }
  
  /// 检查目录是否存在
  Future<bool> directoryExists(String directoryPath) async {
    final directory = Directory(directoryPath);
    return directory.exists();
  }
  
  /// 获取文件信息
  Future<FileStat> getFileStat(String filePath) async {
    final file = File(filePath);
    return file.stat();
  }
  
  /// 获取目录信息
  Future<FileStat> getDirectoryStat(String directoryPath) async {
    final directory = Directory(directoryPath);
    return directory.stat();
  }
  
  /// 获取文件大小
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();
    return stat.size;
  }
  
  /// 获取文件扩展名
  String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }
  
  /// 获取文件名（不含扩展名）
  String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }
  
  /// 获取文件名（含扩展名）
  String getFileName(String filePath) {
    return path.basename(filePath);
  }
  
  /// 获取目录名
  String getDirectoryName(String filePath) {
    return path.dirname(filePath);
  }
  
  /// 获取目录路径
  String getDirectoryPath(String filePath) {
    return path.dirname(filePath);
  }
  
  /// 组合路径
  String combinePath(String path1, String path2) {
    return path.join(path1, path2);
  }
}

/// 文件服务提供者
final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
}); 