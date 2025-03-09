import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../state/providers/file_tree_provider.dart';
import '../../../services/git/git_command_service.dart';

/// 版本控制状态枚举
enum VersionControlStatus {
  untracked,  // 未跟踪
  modified,   // 已修改
  added,      // 已添加
  deleted,    // 已删除
  renamed,    // 已重命名
  conflicted, // 冲突
  clean,      // 干净
  unknown     // 未知
}

/// 版本控制信息
class VersionControlInfo {
  final VersionControlStatus status;
  final String branch;
  final String lastCommit;
  final String lastCommitAuthor;
  final String lastCommitMessage;
  final DateTime? lastCommitDate;
  
  const VersionControlInfo({
    this.status = VersionControlStatus.unknown,
    this.branch = '',
    this.lastCommit = '',
    this.lastCommitAuthor = '',
    this.lastCommitMessage = '',
    this.lastCommitDate,
  });
}

/// 版本控制服务
class VersionControlService {
  final GitCommandService _gitCommandService;
  
  // 缓存
  final Map<String, VersionControlStatus> _statusCache = {};
  final Map<String, String> _branchCache = {};
  final Map<String, Map<String, dynamic>> _commitCache = {};
  final Map<String, String?> _rootCache = {};
  
  VersionControlService(this._gitCommandService);
  
  /// 获取文件版本控制状态
  Future<VersionControlStatus> getFileStatus(String filePath) async {
    // 检查缓存
    if (_statusCache.containsKey(filePath)) {
      return _statusCache[filePath]!;
    }
    
    try {
      // 获取文件所在的Git仓库根目录
      final repoRoot = await _findGitRoot(filePath);
      if (repoRoot == null) {
        return VersionControlStatus.unknown;
      }
      
      // 获取文件状态
      final statusOutput = await _gitCommandService.getFileStatus(filePath, repoRoot);
      
      if (statusOutput.isEmpty) {
        _statusCache[filePath] = VersionControlStatus.clean;
        return VersionControlStatus.clean;
      }
      
      // 解析git status输出
      final statusCode = statusOutput.substring(0, 2).trim();
      VersionControlStatus status;
      
      switch (statusCode) {
        case '??':
          status = VersionControlStatus.untracked;
          break;
        case 'M':
        case ' M':
          status = VersionControlStatus.modified;
          break;
        case 'A':
        case ' A':
          status = VersionControlStatus.added;
          break;
        case 'D':
        case ' D':
          status = VersionControlStatus.deleted;
          break;
        case 'R':
          status = VersionControlStatus.renamed;
          break;
        case 'UU':
          status = VersionControlStatus.conflicted;
          break;
        default:
          status = VersionControlStatus.unknown;
      }
      
      // 更新缓存
      _statusCache[filePath] = status;
      return status;
    } catch (e) {
      return VersionControlStatus.unknown;
    }
  }
  
  /// 获取当前分支名
  Future<String> getCurrentBranch(String filePath) async {
    try {
      // 获取文件所在的Git仓库根目录
      final repoRoot = await _findGitRoot(filePath);
      if (repoRoot == null) {
        return '';
      }
      
      // 检查缓存
      if (_branchCache.containsKey(repoRoot)) {
        return _branchCache[repoRoot]!;
      }
      
      final branch = await _gitCommandService.getCurrentBranch(repoRoot);
      
      // 更新缓存
      _branchCache[repoRoot] = branch;
      return branch;
    } catch (e) {
      return '';
    }
  }
  
  /// 获取最后一次提交信息
  Future<Map<String, dynamic>> getLastCommitInfo(String filePath) async {
    try {
      // 检查缓存
      if (_commitCache.containsKey(filePath)) {
        return _commitCache[filePath]!;
      }
      
      // 获取文件所在的Git仓库根目录
      final repoRoot = await _findGitRoot(filePath);
      if (repoRoot == null) {
        return {'hash': '', 'author': '', 'date': null, 'message': ''};
      }
      
      final commitInfo = await _gitCommandService.getLastCommitInfo(filePath, repoRoot);
      
      // 更新缓存
      _commitCache[filePath] = commitInfo;
      return commitInfo;
    } catch (e) {
      return {'hash': '', 'author': '', 'date': null, 'message': ''};
    }
  }
  
  /// 查找Git仓库根目录
  Future<String?> _findGitRoot(String filePath) async {
    // 检查缓存
    if (_rootCache.containsKey(filePath)) {
      return _rootCache[filePath];
    }
    
    final rootPath = await _gitCommandService.findGitRoot(filePath);
    
    // 更新缓存
    _rootCache[filePath] = rootPath;
    return rootPath;
  }
  
  /// 获取完整的版本控制信息
  Future<VersionControlInfo> getVersionControlInfo(String filePath) async {
    final status = await getFileStatus(filePath);
    final branch = await getCurrentBranch(filePath);
    final commitInfo = await getLastCommitInfo(filePath);
    
    return VersionControlInfo(
      status: status,
      branch: branch,
      lastCommit: commitInfo['hash'] ?? '',
      lastCommitAuthor: commitInfo['author'] ?? '',
      lastCommitMessage: commitInfo['message'] ?? '',
      lastCommitDate: commitInfo['date'],
    );
  }
  
  /// 清除缓存
  void clearCache() {
    _statusCache.clear();
    _branchCache.clear();
    _commitCache.clear();
    _rootCache.clear();
  }
  
  /// 添加文件到暂存区
  Future<bool> addToStaging(String filePath) async {
    try {
      final repoRoot = await _findGitRoot(filePath);
      if (repoRoot == null) {
        return false;
      }
      
      final success = await _gitCommandService.addFile(filePath, repoRoot);
      
      if (success) {
        // 更新缓存
        _statusCache.remove(filePath);
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }
  
  /// 撤销文件更改
  Future<bool> revertChanges(String filePath) async {
    try {
      final repoRoot = await _findGitRoot(filePath);
      if (repoRoot == null) {
        return false;
      }
      
      final success = await _gitCommandService.revertFile(filePath, repoRoot);
      
      if (success) {
        // 更新缓存
        _statusCache.remove(filePath);
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }
  
  /// 获取提交历史
  Future<List<Map<String, dynamic>>> getCommitHistory(String filePath, {int limit = 10}) async {
    try {
      final repoRoot = await _findGitRoot(filePath);
      if (repoRoot == null) {
        return [];
      }
      
      return await _gitCommandService.getCommitHistory(filePath, repoRoot, limit: limit);
    } catch (e) {
      return [];
    }
  }
}

/// 版本控制服务提供者
final versionControlProvider = Provider<VersionControlService>((ref) {
  final gitCommandService = ref.watch(gitCommandProvider);
  return VersionControlService(gitCommandService);
});

/// 版本控制指示器组件
class VersionControlIndicator extends ConsumerWidget {
  final FileNode node;
  final double size;
  
  const VersionControlIndicator({
    Key? key,
    required this.node,
    this.size = 12,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<VersionControlStatus>(
      future: ref.read(versionControlProvider).getFileStatus(node.path),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == VersionControlStatus.unknown) {
          return const SizedBox.shrink();
        }
        
        return Tooltip(
          message: _getStatusTooltip(snapshot.data!),
          child: Icon(
            _getStatusIcon(snapshot.data!),
            size: size,
            color: _getStatusColor(context, snapshot.data!),
          ),
        );
      },
    );
  }
  
  /// 获取状态图标
  IconData _getStatusIcon(VersionControlStatus status) {
    switch (status) {
      case VersionControlStatus.untracked:
        return Icons.help_outline;
      case VersionControlStatus.modified:
        return Icons.edit;
      case VersionControlStatus.added:
        return Icons.add_circle_outline;
      case VersionControlStatus.deleted:
        return Icons.delete_outline;
      case VersionControlStatus.renamed:
        return Icons.drive_file_rename_outline;
      case VersionControlStatus.conflicted:
        return Icons.warning_amber;
      case VersionControlStatus.clean:
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
  }
  
  /// 获取状态颜色
  Color _getStatusColor(BuildContext context, VersionControlStatus status) {
    switch (status) {
      case VersionControlStatus.untracked:
        return Colors.grey;
      case VersionControlStatus.modified:
        return Colors.blue;
      case VersionControlStatus.added:
        return Colors.green;
      case VersionControlStatus.deleted:
        return Colors.red;
      case VersionControlStatus.renamed:
        return Colors.purple;
      case VersionControlStatus.conflicted:
        return Colors.orange;
      case VersionControlStatus.clean:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  /// 获取状态提示文本
  String _getStatusTooltip(VersionControlStatus status) {
    switch (status) {
      case VersionControlStatus.untracked:
        return '未跟踪';
      case VersionControlStatus.modified:
        return '已修改';
      case VersionControlStatus.added:
        return '已添加';
      case VersionControlStatus.deleted:
        return '已删除';
      case VersionControlStatus.renamed:
        return '已重命名';
      case VersionControlStatus.conflicted:
        return '冲突';
      case VersionControlStatus.clean:
        return '无更改';
      default:
        return '未知状态';
    }
  }
}

/// 版本控制详情面板
class VersionControlDetailsPanel extends ConsumerWidget {
  final FileNode node;
  
  const VersionControlDetailsPanel({
    Key? key,
    required this.node,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return FutureBuilder<VersionControlInfo>(
      future: ref.read(versionControlProvider).getVersionControlInfo(node.path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final info = snapshot.data!;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '版本控制信息',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // 文件状态
              Row(
                children: [
                  Icon(
                    _getStatusIcon(info.status),
                    size: 16,
                    color: _getStatusColor(context, info.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '状态: ${_getStatusText(info.status)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 分支信息
              if (info.branch.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.call_split, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '分支: ${info.branch}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // 最后提交信息
              if (info.lastCommit.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.commit, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '最后提交: ${info.lastCommit.substring(0, 7)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // 提交作者
              if (info.lastCommitAuthor.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '作者: ${info.lastCommitAuthor}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // 提交消息
              if (info.lastCommitMessage.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.message, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '消息: ${info.lastCommitMessage}',
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // 最后提交日期
              if (info.lastCommitDate != null) ...[
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '提交日期: ${_formatDate(info.lastCommitDate!)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              const Divider(),
              const SizedBox(height: 16),
              
              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.history,
                    label: '查看历史',
                    onPressed: () {
                      _showCommitHistory(context, ref);
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.undo,
                    label: '撤销更改',
                    onPressed: info.status == VersionControlStatus.modified ||
                              info.status == VersionControlStatus.deleted
                        ? () {
                            _revertChanges(context, ref);
                          }
                        : null,
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.add_circle_outline,
                    label: '添加到暂存区',
                    onPressed: info.status == VersionControlStatus.untracked ||
                              info.status == VersionControlStatus.modified
                        ? () {
                            _addToStaging(context, ref);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// 显示提交历史对话框
  Future<void> _showCommitHistory(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final commits = await ref.read(versionControlProvider).getCommitHistory(node.path);
    
    if (commits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有找到提交历史')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${node.name} 的提交历史'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: commits.length,
            itemBuilder: (context, index) {
              final commit = commits[index];
              final hash = commit['hash'] as String;
              final author = commit['author'] as String;
              final message = commit['message'] as String;
              final date = commit['date'] as DateTime;
              
              return ListTile(
                leading: const Icon(Icons.commit),
                title: Text(message),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hash.substring(0, 7)} · ${author}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      _formatDate(date),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                isThreeLine: true,
                dense: true,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
  
  /// 撤销更改
  Future<void> _revertChanges(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('撤销更改'),
        content: Text('确定要撤销对 ${node.name} 的更改吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('撤销'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await ref.read(versionControlProvider).revertChanges(node.path);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已成功撤销更改')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('撤销更改失败')),
        );
      }
    }
  }
  
  /// 添加到暂存区
  Future<void> _addToStaging(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(versionControlProvider).addToStaging(node.path);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已成功添加到暂存区')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('添加到暂存区失败')),
      );
    }
  }
  
  /// 构建操作按钮
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
  
  /// 获取状态图标
  IconData _getStatusIcon(VersionControlStatus status) {
    switch (status) {
      case VersionControlStatus.untracked:
        return Icons.help_outline;
      case VersionControlStatus.modified:
        return Icons.edit;
      case VersionControlStatus.added:
        return Icons.add_circle_outline;
      case VersionControlStatus.deleted:
        return Icons.delete_outline;
      case VersionControlStatus.renamed:
        return Icons.drive_file_rename_outline;
      case VersionControlStatus.conflicted:
        return Icons.warning_amber;
      case VersionControlStatus.clean:
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
  }
  
  /// 获取状态颜色
  Color _getStatusColor(BuildContext context, VersionControlStatus status) {
    switch (status) {
      case VersionControlStatus.untracked:
        return Colors.grey;
      case VersionControlStatus.modified:
        return Colors.blue;
      case VersionControlStatus.added:
        return Colors.green;
      case VersionControlStatus.deleted:
        return Colors.red;
      case VersionControlStatus.renamed:
        return Colors.purple;
      case VersionControlStatus.conflicted:
        return Colors.orange;
      case VersionControlStatus.clean:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  /// 获取状态文本
  String _getStatusText(VersionControlStatus status) {
    switch (status) {
      case VersionControlStatus.untracked:
        return '未跟踪';
      case VersionControlStatus.modified:
        return '已修改';
      case VersionControlStatus.added:
        return '已添加';
      case VersionControlStatus.deleted:
        return '已删除';
      case VersionControlStatus.renamed:
        return '已重命名';
      case VersionControlStatus.conflicted:
        return '冲突';
      case VersionControlStatus.clean:
        return '无更改';
      default:
        return '未知状态';
    }
  }
  
  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 