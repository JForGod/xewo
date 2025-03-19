import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

final gitStatusManagerProvider = Provider((ref) => GitStatusManager());

enum GitFileStatus {
  unmodified,
  modified,
  added,
  deleted,
  renamed,
  copied,
  untracked,
  ignored,
  conflict,
}

class GitStatusInfo {
  final GitFileStatus status;
  final String? originalPath; // 用于重命名文件
  
  const GitStatusInfo({
    required this.status,
    this.originalPath,
  });
}

class GitStatusManager {
  final Map<String, GitStatusInfo> _fileStatuses = {};
  String? _rootPath;
  
  // 初始化Git状态管理器
  Future<void> initialize(String projectPath) async {
    _rootPath = await _findGitRoot(projectPath);
    if (_rootPath != null) {
      await refreshStatus();
    }
  }
  
  // 查找Git仓库根目录
  Future<String?> _findGitRoot(String startPath) async {
    var currentPath = startPath;
    while (true) {
      if (await Directory(path.join(currentPath, '.git')).exists()) {
        return currentPath;
      }
      final parent = path.dirname(currentPath);
      if (parent == currentPath) {
        return null;
      }
      currentPath = parent;
    }
  }
  
  // 刷新所有文件的Git状态
  Future<void> refreshStatus() async {
    if (_rootPath == null) return;
    
    _fileStatuses.clear();
    
    try {
      // 获取未跟踪的文件
      final untrackedResult = await Process.run(
        'git',
        ['ls-files', '--others', '--exclude-standard'],
        workingDirectory: _rootPath,
      );
      if (untrackedResult.exitCode == 0) {
        final untracked = (untrackedResult.stdout as String)
            .split('\n')
            .where((line) => line.isNotEmpty);
        for (final file in untracked) {
          _fileStatuses[path.join(_rootPath!, file)] = const GitStatusInfo(
            status: GitFileStatus.untracked,
          );
        }
      }
      
      // 获取已修改的文件
      final statusResult = await Process.run(
        'git',
        ['status', '--porcelain'],
        workingDirectory: _rootPath,
      );
      if (statusResult.exitCode == 0) {
        final lines = (statusResult.stdout as String)
            .split('\n')
            .where((line) => line.isNotEmpty);
        
        for (final line in lines) {
          final status = line.substring(0, 2);
          final filePath = line.substring(3);
          final absolutePath = path.join(_rootPath!, filePath);
          
          GitFileStatus gitStatus;
          String? originalPath;
          
          switch (status) {
            case 'M ':
            case ' M':
              gitStatus = GitFileStatus.modified;
              break;
            case 'A ':
              gitStatus = GitFileStatus.added;
              break;
            case 'D ':
            case ' D':
              gitStatus = GitFileStatus.deleted;
              break;
            case 'R ':
              gitStatus = GitFileStatus.renamed;
              final parts = filePath.split(' -> ');
              if (parts.length == 2) {
                originalPath = path.join(_rootPath!, parts[0]);
              }
              break;
            case 'C ':
              gitStatus = GitFileStatus.copied;
              break;
            case 'UU':
              gitStatus = GitFileStatus.conflict;
              break;
            case '??':
              gitStatus = GitFileStatus.untracked;
              break;
            default:
              continue;
          }
          
          _fileStatuses[absolutePath] = GitStatusInfo(
            status: gitStatus,
            originalPath: originalPath,
          );
        }
      }
    } catch (e) {
      // Git命令执行失败，可能是Git未安装或不是Git仓库
      print('Git status refresh failed: $e');
    }
  }
  
  // 获取文件的Git状态
  GitFileStatus getFileStatus(String filePath) {
    return _fileStatuses[filePath]?.status ?? GitFileStatus.unmodified;
  }
  
  // 检查文件是否有Git状态
  bool hasGitStatus(String filePath) {
    return _fileStatuses.containsKey(filePath);
  }
  
  // 获取文件的原始路径（用于重命名文件）
  String? getOriginalPath(String filePath) {
    return _fileStatuses[filePath]?.originalPath;
  }
  
  // 检查是否是Git仓库
  bool get isGitRepository => _rootPath != null;
  
  // 获取Git仓库根目录
  String? get rootPath => _rootPath;
} 