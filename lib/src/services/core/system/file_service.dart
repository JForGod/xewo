import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class FileService {
  // 单例模式
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  // 文件操作状态
  final ValueNotifier<bool> isBusy = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentError = ValueNotifier<String?>(null);

  // 创建文件
  Future<File> createFile(String filePath) async {
    try {
      isBusy.value = true;
      final file = File(filePath);
      if (await file.exists()) {
        throw FileSystemException('文件已存在', filePath);
      }
      return await file.create(recursive: true);
    } catch (e) {
      currentError.value = e.toString();
      rethrow;
    } finally {
      isBusy.value = false;
    }
  }

  // 读取文件
  Future<String> readFile(String filePath) async {
    try {
      isBusy.value = true;
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('文件不存在', filePath);
      }
      return await file.readAsString();
    } catch (e) {
      currentError.value = e.toString();
      rethrow;
    } finally {
      isBusy.value = false;
    }
  }

  // 写入文件
  Future<File> writeFile(String filePath, String content) async {
    try {
      isBusy.value = true;
      final file = File(filePath);
      return await file.writeAsString(content);
    } catch (e) {
      currentError.value = e.toString();
      rethrow;
    } finally {
      isBusy.value = false;
    }
  }

  // 删除文件
  Future<void> deleteFile(String filePath) async {
    try {
      isBusy.value = true;
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      currentError.value = e.toString();
      rethrow;
    } finally {
      isBusy.value = false;
    }
  }

  // 重命名文件
  Future<File> renameFile(String oldPath, String newPath) async {
    try {
      isBusy.value = true;
      final file = File(oldPath);
      return await file.rename(newPath);
    } catch (e) {
      currentError.value = e.toString();
      rethrow;
    } finally {
      isBusy.value = false;
    }
  }

  // 复制文件
  Future<File> copyFile(String sourcePath, String targetPath) async {
    try {
      isBusy.value = true;
      final file = File(sourcePath);
      return await file.copy(targetPath);
    } catch (e) {
      currentError.value = e.toString();
      rethrow;
    } finally {
      isBusy.value = false;
    }
  }
} 