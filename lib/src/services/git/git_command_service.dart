import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Git命令执行结果
class GitCommandResult {
  final bool success;
  final String output;
  final String error;
  final int exitCode;

  const GitCommandResult({
    required this.success,
    required this.output,
    required this.error,
    required this.exitCode,
  });
}

/// Git命令服务
class GitCommandService {
  /// 检查Git是否可用
  Future<bool> isGitAvailable() async {
    try {
      final result = await Process.run('git', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// 执行Git命令
  Future<GitCommandResult> executeGitCommand(
    List<String> args, {
    String? workingDirectory,
  }) async {
    try {
      final result = await Process.run(
        'git',
        args,
        workingDirectory: workingDirectory,
      );

      return GitCommandResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.stderr.toString(),
        exitCode: result.exitCode,
      );
    } catch (e) {
      return GitCommandResult(
        success: false,
        output: '',
        error: e.toString(),
        exitCode: -1,
      );
    }
  }

  /// 查找Git仓库根目录
  Future<String?> findGitRoot(String startPath) async {
    String? currentPath = startPath;
    
    while (currentPath != null) {
      final gitDir = Directory(path.join(currentPath, '.git'));
      if (await gitDir.exists()) {
        return currentPath;
      }
      
      final parent = path.dirname(currentPath);
      if (parent == currentPath) {
        return null;
      }
      
      currentPath = parent;
    }
    
    return null;
  }

  /// 获取当前分支
  Future<String> getCurrentBranch(String repoPath) async {
    final result = await executeGitCommand(
      ['branch', '--show-current'],
      workingDirectory: repoPath,
    );
    
    if (result.success) {
      return result.output.trim();
    }
    
    return '';
  }

  /// 获取文件状态
  Future<String> getFileStatus(String filePath, String repoRoot) async {
    final relativePath = path.relative(filePath, from: repoRoot);
    
    final result = await executeGitCommand(
      ['status', '--porcelain', relativePath],
      workingDirectory: repoRoot,
    );
    
    if (result.success) {
      return result.output.trim();
    }
    
    return '';
  }

  /// 获取最后一次提交信息
  Future<Map<String, dynamic>> getLastCommitInfo(
    String filePath,
    String repoRoot,
  ) async {
    final relativePath = path.relative(filePath, from: repoRoot);
    
    final result = await executeGitCommand(
      ['log', '-1', '--format=%H|%an|%at|%s', '--', relativePath],
      workingDirectory: repoRoot,
    );
    
    if (result.success && result.output.trim().isNotEmpty) {
      final parts = result.output.trim().split('|');
      if (parts.length >= 4) {
        final hash = parts[0];
        final author = parts[1];
        final timestamp = int.tryParse(parts[2]) ?? 0;
        final message = parts[3];
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        
        return {
          'hash': hash,
          'author': author,
          'date': date,
          'message': message,
        };
      }
    }
    
    return {
      'hash': '',
      'author': '',
      'date': null,
      'message': '',
    };
  }

  /// 获取文件差异
  Future<String> getFileDiff(String filePath, String repoRoot) async {
    final relativePath = path.relative(filePath, from: repoRoot);
    
    final result = await executeGitCommand(
      ['diff', '--', relativePath],
      workingDirectory: repoRoot,
    );
    
    if (result.success) {
      return result.output;
    }
    
    return '';
  }

  /// 添加文件到暂存区
  Future<bool> addFile(String filePath, String repoRoot) async {
    final relativePath = path.relative(filePath, from: repoRoot);
    
    final result = await executeGitCommand(
      ['add', relativePath],
      workingDirectory: repoRoot,
    );
    
    return result.success;
  }

  /// 撤销文件更改
  Future<bool> revertFile(String filePath, String repoRoot) async {
    final relativePath = path.relative(filePath, from: repoRoot);
    
    final result = await executeGitCommand(
      ['checkout', '--', relativePath],
      workingDirectory: repoRoot,
    );
    
    return result.success;
  }

  /// 提交更改
  Future<bool> commit(String message, String repoRoot) async {
    final result = await executeGitCommand(
      ['commit', '-m', message],
      workingDirectory: repoRoot,
    );
    
    return result.success;
  }

  /// 获取提交历史
  Future<List<Map<String, dynamic>>> getCommitHistory(
    String filePath,
    String repoRoot, {
    int limit = 10,
  }) async {
    final relativePath = path.relative(filePath, from: repoRoot);
    
    final result = await executeGitCommand(
      [
        'log',
        '-n',
        limit.toString(),
        '--format=%H|%an|%at|%s',
        '--',
        relativePath,
      ],
      workingDirectory: repoRoot,
    );
    
    if (result.success && result.output.trim().isNotEmpty) {
      final commits = <Map<String, dynamic>>[];
      final lines = result.output.trim().split('\n');
      
      for (final line in lines) {
        final parts = line.trim().split('|');
        if (parts.length >= 4) {
          final hash = parts[0];
          final author = parts[1];
          final timestamp = int.tryParse(parts[2]) ?? 0;
          final message = parts[3];
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          
          commits.add({
            'hash': hash,
            'author': author,
            'date': date,
            'message': message,
          });
        }
      }
      
      return commits;
    }
    
    return [];
  }
}

/// Git命令服务提供者
final gitCommandProvider = Provider<GitCommandService>((ref) {
  return GitCommandService();
}); 