import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../state/models/file_node.dart';
import 'package:flutter/foundation.dart';

/// 文件树服务提供者
final fileTreeServiceProvider = Provider<FileTreeService>((ref) {
  return FileTreeService();
});

class FileTreeService {
  // 最大重试次数
  static const int maxRetries = 3;
  // 重试延迟（毫秒）
  static const int retryDelay = 500;
  
  // 加载目录
  Future<FileNode> loadDirectory(String directoryPath) async {
    int retryCount = 0;
    
    while (true) {
      try {
        if (kDebugMode) {
          print('正在加载目录: $directoryPath (尝试 ${retryCount + 1}/$maxRetries)');
        }

        final directory = Directory(directoryPath);
        if (!await directory.exists()) {
          if (kDebugMode) {
            print('目录不存在: $directoryPath');
          }
          return FileNode(
            name: path.basename(directoryPath),
            path: directoryPath,
            type: FileNodeType.directory,
            children: [],
            error: '目录不存在',
          );
        }

        // 检查目录权限
        try {
          await directory.list().first;
        } catch (e) {
          if (kDebugMode) {
            print('无法访问目录: $directoryPath, 错误: $e');
          }
          return FileNode(
            name: path.basename(directoryPath),
            path: directoryPath,
            type: FileNodeType.directory,
            children: [],
            error: '无法访问目录: $e',
          );
        }

        // 加载根目录内容
        final List<FileNode> children = [];
        try {
          await for (final entity in directory.list(recursive: false, followLinks: false)) {
            try {
              final stat = await entity.stat();
              if (stat.type == FileSystemEntityType.directory) {
                // 目录节点
                children.add(
                  FileNode(
                    name: path.basename(entity.path),
                    path: entity.path,
                    type: FileNodeType.directory,
                    children: [],
                    lastModified: stat.modified,
                  ),
                );
              } else if (stat.type == FileSystemEntityType.file) {
                // 文件节点
                final fileExtension = path.extension(entity.path).toLowerCase();
                // 过滤二进制文件
                if (!_isBinaryExtension(fileExtension)) {
                  children.add(
                    FileNode(
                      name: path.basename(entity.path),
                      path: entity.path,
                      type: FileNodeType.file,
                      extension: fileExtension,
                      size: stat.size,
                      lastModified: stat.modified,
                    ),
                  );
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('处理文件系统实体时出错: ${entity.path}, 错误: $e');
              }
              // 继续处理其他文件，不中断整个目录
              children.add(
                FileNode(
                  name: path.basename(entity.path),
                  path: entity.path,
                  type: _isDirectory(entity) ? FileNodeType.directory : FileNodeType.file,
                  error: '加载错误: $e',
                  children: _isDirectory(entity) ? [] : const [],
                ),
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('加载目录内容时出错: $directoryPath, 错误: $e');
          }
          
          // 在目录内容加载错误时仍然返回目录节点，但标记错误
          return FileNode(
            name: path.basename(directoryPath),
            path: directoryPath,
            type: FileNodeType.directory,
            children: [],
            error: '加载目录内容失败: $e',
          );
        }

        // 排序：目录在前，文件在后，按名称字母顺序排序
        children.sort((a, b) {
          if (a.type == b.type) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          return a.type == FileNodeType.directory ? -1 : 1;
        });

        return FileNode(
          name: path.basename(directoryPath),
          path: directoryPath,
          type: FileNodeType.directory,
          children: children,
        );
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          if (kDebugMode) {
            print('加载目录失败，已达到最大重试次数: $directoryPath, 错误: $e');
          }
          return FileNode(
            name: path.basename(directoryPath),
            path: directoryPath,
            type: FileNodeType.directory,
            children: [],
            error: '加载失败: $e',
          );
        }
        
        if (kDebugMode) {
          print('加载目录失败，正在重试: $directoryPath, 错误: $e');
        }
        
        // 等待一段时间后重试
        await Future.delayed(Duration(milliseconds: retryDelay));
      }
    }
  }

  // 判断是否为二进制文件扩展名
  bool _isBinaryExtension(String extension) {
    final binaryExtensions = [
      '.exe', '.dll', '.so', '.dylib', '.obj', '.o', '.a', '.lib',
      '.bin', '.dat', '.db', '.sqlite', '.jpg', '.jpeg', '.png', '.gif',
      '.bmp', '.ico', '.tif', '.tiff', '.psd', '.mp3', '.mp4', '.avi',
      '.mov', '.mpg', '.mpeg', '.wav', '.flac', '.ogg', '.mkv', '.zip',
      '.rar', '.7z', '.gz', '.tar', '.jar', '.class', '.pyc', '.pyd',
    ];
    return binaryExtensions.contains(extension);
  }

  // 判断实体是否为目录
  bool _isDirectory(FileSystemEntity entity) {
    try {
      return entity is Directory;
    } catch (_) {
      return false;
    }
  }

  // 重命名文件或目录
  Future<void> rename(String oldPath, String newName) async {
    try {
      final entity = FileSystemEntity.isDirectorySync(oldPath)
          ? Directory(oldPath)
          : File(oldPath);
      final newPath = path.join(path.dirname(oldPath), newName);
      await entity.rename(newPath);
    } catch (e) {
      throw Exception('重命名失败: $e');
    }
  }

  // 移动文件或目录
  Future<void> move(String sourcePath, String targetPath) async {
    try {
      final entity = FileSystemEntity.isDirectorySync(sourcePath)
          ? Directory(sourcePath)
          : File(sourcePath);
      final newPath = path.join(targetPath, path.basename(sourcePath));
      await entity.rename(newPath);
    } catch (e) {
      throw Exception('移动失败: $e');
    }
  }

  // 复制文件或目录
  Future<void> copy(String sourcePath, String targetPath) async {
    try {
      final isDirectory = FileSystemEntity.isDirectorySync(sourcePath);
      final newPath = path.join(targetPath, path.basename(sourcePath));
      
      if (isDirectory) {
        // 复制目录
        final sourceDir = Directory(sourcePath);
        final targetDir = Directory(newPath);
        await targetDir.create(recursive: true);
        
        await for (final entity in sourceDir.list(recursive: true)) {
          final relativePath = path.relative(entity.path, from: sourcePath);
          final newEntityPath = path.join(newPath, relativePath);
          
          if (entity is File) {
            final newFile = File(newEntityPath);
            await newFile.create(recursive: true);
            await entity.copy(newEntityPath);
          } else if (entity is Directory) {
            final newDir = Directory(newEntityPath);
            await newDir.create(recursive: true);
          }
        }
      } else {
        // 复制文件
        final file = File(sourcePath);
        await file.copy(newPath);
      }
    } catch (e) {
      throw Exception('复制失败: $e');
    }
  }

  // 删除文件或目录
  Future<void> delete(String path) async {
    try {
      final entity = FileSystemEntity.isDirectorySync(path)
          ? Directory(path)
          : File(path);
      await entity.delete(recursive: true);
    } catch (e) {
      throw Exception('删除失败: $e');
    }
  }

  // 递归构建文件树
  Future<FileNode> _buildFileTree(String directoryPath) async {
    if (kDebugMode) {
      print('构建文件树: $directoryPath');
    }

    final Directory directory = Directory(directoryPath);
    final String name = path.basename(directoryPath);
    final List<FileNode> children = [];

    try {
      if (!await directory.exists()) {
        if (kDebugMode) {
          print('目录不存在，返回空节点: $directoryPath');
        }
        return FileNode(
          name: name,
          path: directoryPath,
          type: FileNodeType.directory,
          children: [],
        );
      }

      List<FileSystemEntity> entities = [];
      try {
        // 使用同步方法列出目录内容，避免并发问题
        entities = directory.listSync();
      } catch (e) {
        if (kDebugMode) {
          print('列出目录内容失败: $directoryPath, 错误: $e');
        }
        return FileNode(
          name: name,
          path: directoryPath,
          type: FileNodeType.directory,
          children: [],
        );
      }

      // 排序：目录在前，文件在后，同类型按名称排序
      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return path.basename(a.path).toLowerCase().compareTo(path.basename(b.path).toLowerCase());
      });

      // 过滤掉隐藏文件和特定目录
      entities = entities.where((entity) {
        final basename = path.basename(entity.path);
        return !basename.startsWith('.') && // 隐藏文件
               !basename.startsWith('__') && // Python缓存等
               basename != 'node_modules' && // Node.js模块
               basename != 'build' && // 构建目录
               basename != 'dist' && // 分发目录
               basename != 'target'; // Rust/Java构建目录
      }).toList();

      for (var entity in entities) {
        try {
          if (entity is Directory) {
            // 异步构建子目录
            children.add(FileNode(
              name: path.basename(entity.path),
              path: entity.path,
              type: FileNodeType.directory,
              children: [], // 初始为空列表
              isLoading: true, // 标记为加载中
            ));
          } else if (entity is File) {
            children.add(FileNode(
              name: path.basename(entity.path),
              path: entity.path,
              type: FileNodeType.file,
              children: [],
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            print('处理实体失败: ${entity.path}, 错误: $e');
          }
          // 继续处理下一个实体
          continue;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('构建文件树失败: $directoryPath, 错误: $e');
      }
      // 返回一个空目录节点而不是抛出异常
      return FileNode(
        name: name,
        path: directoryPath,
        type: FileNodeType.directory,
        children: [],
      );
    }

    return FileNode(
      name: name,
      path: directoryPath,
      type: FileNodeType.directory,
      children: children,
    );
  }

  // 异步加载子目录
  Future<List<FileNode>> loadChildren(String directoryPath) async {
    try {
      final node = await _buildFileTree(directoryPath);
      return node.children;
    } catch (e) {
      if (kDebugMode) {
        print('加载子目录失败: $directoryPath, 错误: $e');
      }
      return [];
    }
  }
} 