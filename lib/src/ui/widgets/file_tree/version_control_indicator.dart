import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';

/// 版本控制状态
enum VersionControlStatus {
  untracked,  // 未跟踪
  added,      // 已添加
  modified,   // 已修改
  deleted,    // 已删除
  renamed,    // 已重命名
  conflicted, // 冲突
  unchanged,  // 未更改
}

/// 版本控制信息
class VersionControlInfo {
  final String path;
  final VersionControlStatus status;
  final String? branch;
  final DateTime? lastCommit;
  final String? lastCommitMessage;
  final String? lastCommitAuthor;

  const VersionControlInfo({
    required this.path,
    required this.status,
    this.branch,
    this.lastCommit,
    this.lastCommitMessage,
    this.lastCommitAuthor,
  });
}

/// 版本控制服务状态
class VersionControlState {
  final Map<String, VersionControlInfo> fileStatuses;
  final String? currentBranch;
  final bool isLoading;
  final String? error;
  final bool isEnabled;

  const VersionControlState({
    this.fileStatuses = const {},
    this.currentBranch,
    this.isLoading = false,
    this.error,
    this.isEnabled = false,
  });

  VersionControlState copyWith({
    Map<String, VersionControlInfo>? fileStatuses,
    String? currentBranch,
    bool? isLoading,
    String? error,
    bool? isEnabled,
  }) {
    return VersionControlState(
      fileStatuses: fileStatuses ?? this.fileStatuses,
      currentBranch: currentBranch ?? this.currentBranch,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// 版本控制服务提供者
class VersionControlNotifier extends StateNotifier<VersionControlState> {
  VersionControlNotifier() : super(const VersionControlState()) {
    _initialize();
  }

  /// 初始化版本控制服务
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // 检查是否启用了版本控制
      final isEnabled = await _checkVersionControlEnabled();
      
      if (isEnabled) {
        // 获取当前分支
        final currentBranch = await _getCurrentBranch();
        
        // 获取文件状态
        final fileStatuses = await _getFileStatuses();
        
        state = state.copyWith(
          isEnabled: true,
          currentBranch: currentBranch,
          fileStatuses: fileStatuses,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isEnabled: false,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '初始化版本控制失败: $e',
      );
    }
  }

  /// 检查是否启用了版本控制
  Future<bool> _checkVersionControlEnabled() async {
    // 这里应该检查项目是否启用了版本控制
    // 暂时返回true
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  /// 获取当前分支
  Future<String> _getCurrentBranch() async {
    // 这里应该获取当前分支
    // 暂时返回模拟数据
    await Future.delayed(const Duration(milliseconds: 300));
    return 'main';
  }

  /// 获取文件状态
  Future<Map<String, VersionControlInfo>> _getFileStatuses() async {
    // 这里应该获取文件状态
    // 暂时返回模拟数据
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\file_tree.dart': VersionControlInfo(
        path: 'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\file_tree.dart',
        status: VersionControlStatus.modified,
        branch: 'main',
        lastCommit: DateTime.now().subtract(const Duration(days: 1)),
        lastCommitMessage: '实现文件树基本功能',
        lastCommitAuthor: '开发者',
      ),
      'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\file_tree_node.dart': VersionControlInfo(
        path: 'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\file_tree_node.dart',
        status: VersionControlStatus.added,
        branch: 'main',
      ),
      'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\file_tree_context_menu.dart': VersionControlInfo(
        path: 'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\file_tree_context_menu.dart',
        status: VersionControlStatus.untracked,
      ),
      'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\old_file.dart': VersionControlInfo(
        path: 'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\old_file.dart',
        status: VersionControlStatus.deleted,
      ),
      'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\renamed_file.dart': VersionControlInfo(
        path: 'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\renamed_file.dart',
        status: VersionControlStatus.renamed,
      ),
      'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\conflict_file.dart': VersionControlInfo(
        path: 'H:\\AxE\\xewo\\lib\\src\\ui\\widgets\\file_tree\\conflict_file.dart',
        status: VersionControlStatus.conflicted,
      ),
    };
  }

  /// 刷新文件状态
  Future<void> refreshFileStatuses() async {
    state = state.copyWith(isLoading: true);

    try {
      // 获取文件状态
      final fileStatuses = await _getFileStatuses();
      
      state = state.copyWith(
        fileStatuses: fileStatuses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '刷新文件状态失败: $e',
      );
    }
  }

  /// 获取文件状态
  VersionControlStatus? getFileStatus(String path) {
    return state.fileStatuses[path]?.status;
  }

  /// 获取文件版本控制信息
  VersionControlInfo? getFileInfo(String path) {
    return state.fileStatuses[path];
  }
}

/// 版本控制服务提供者
final versionControlProvider = StateNotifierProvider<VersionControlNotifier, VersionControlState>((ref) {
  return VersionControlNotifier();
});

/// 版本控制指示器组件
class VersionControlIndicator extends ConsumerWidget {
  final String filePath;
  final double size;

  const VersionControlIndicator({
    Key? key,
    required this.filePath,
    this.size = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(versionControlProvider);
    
    // 如果版本控制未启用或正在加载，则不显示指示器
    if (!state.isEnabled || state.isLoading) {
      return const SizedBox.shrink();
    }
    
    // 获取文件状态
    final status = state.fileStatuses[filePath]?.status;
    if (status == null || status == VersionControlStatus.unchanged) {
      return const SizedBox.shrink();
    }
    
    return Tooltip(
      message: _getStatusTooltip(status),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getStatusColor(status),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(VersionControlStatus status) {
    switch (status) {
      case VersionControlStatus.untracked:
        return Colors.grey;
      case VersionControlStatus.added:
        return Colors.green;
      case VersionControlStatus.modified:
        return Colors.blue;
      case VersionControlStatus.deleted:
        return Colors.red;
      case VersionControlStatus.renamed:
        return Colors.purple;
      case VersionControlStatus.conflicted:
        return Colors.orange;
      case VersionControlStatus.unchanged:
        return Colors.transparent;
    }
  }

  /// 获取状态提示
  String _getStatusTooltip(VersionControlStatus status) {
    switch (status) {
      case VersionControlStatus.untracked:
        return '未跟踪';
      case VersionControlStatus.added:
        return '已添加';
      case VersionControlStatus.modified:
        return '已修改';
      case VersionControlStatus.deleted:
        return '已删除';
      case VersionControlStatus.renamed:
        return '已重命名';
      case VersionControlStatus.conflicted:
        return '冲突';
      case VersionControlStatus.unchanged:
        return '未更改';
    }
  }
}

/// 版本控制详情面板
class VersionControlDetailsPanel extends ConsumerWidget {
  final String filePath;

  const VersionControlDetailsPanel({
    Key? key,
    required this.filePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(versionControlProvider);
    final fileInfo = state.fileStatuses[filePath];
    
    if (fileInfo == null) {
      return const Center(child: Text('无版本控制信息'));
    }
    
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Icon(Icons.history, size: 20),
              const SizedBox(width: AppTheme.spacingSm),
              const Text(
                '版本控制信息',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: () => ref.read(versionControlProvider.notifier).refreshFileStatuses(),
                tooltip: '刷新',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          const Divider(),
          
          // 文件信息
          _buildInfoItem('文件路径', fileInfo.path),
          _buildInfoItem('状态', _getStatusText(fileInfo.status)),
          if (fileInfo.branch != null)
            _buildInfoItem('分支', fileInfo.branch!),
          if (fileInfo.lastCommit != null)
            _buildInfoItem('最后提交', _formatDateTime(fileInfo.lastCommit!)),
          if (fileInfo.lastCommitAuthor != null)
            _buildInfoItem('提交者', fileInfo.lastCommitAuthor!),
          if (fileInfo.lastCommitMessage != null)
            _buildInfoItem('提交信息', fileInfo.lastCommitMessage!),
          
          const Divider(),
          
          // 操作按钮
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: [
              _buildActionButton(
                context,
                '查看差异',
                Icons.compare_arrows,
                () => _showDiff(context, fileInfo),
                fileInfo.status == VersionControlStatus.modified ||
                fileInfo.status == VersionControlStatus.renamed,
              ),
              _buildActionButton(
                context,
                '提交更改',
                Icons.check,
                () => _showCommitDialog(context, fileInfo),
                fileInfo.status != VersionControlStatus.unchanged,
              ),
              _buildActionButton(
                context,
                '放弃更改',
                Icons.undo,
                () => _showDiscardDialog(context, fileInfo),
                fileInfo.status == VersionControlStatus.modified ||
                fileInfo.status == VersionControlStatus.deleted ||
                fileInfo.status == VersionControlStatus.renamed,
              ),
              _buildActionButton(
                context,
                '解决冲突',
                Icons.merge_type,
                () => _showMergeDialog(context, fileInfo),
                fileInfo.status == VersionControlStatus.conflicted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
    bool enabled,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs,
        ),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  /// 获取状态文本
  String _getStatusText(VersionControlStatus status) {
    switch (status) {
      case VersionControlStatus.untracked:
        return '未跟踪';
      case VersionControlStatus.added:
        return '已添加';
      case VersionControlStatus.modified:
        return '已修改';
      case VersionControlStatus.deleted:
        return '已删除';
      case VersionControlStatus.renamed:
        return '已重命名';
      case VersionControlStatus.conflicted:
        return '冲突';
      case VersionControlStatus.unchanged:
        return '未更改';
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 显示差异对话框
  void _showDiff(BuildContext context, VersionControlInfo fileInfo) {
    // 这里应该显示文件差异
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('查看差异功能开发中')),
    );
  }

  /// 显示提交对话框
  void _showCommitDialog(BuildContext context, VersionControlInfo fileInfo) {
    // 这里应该显示提交对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('提交更改功能开发中')),
    );
  }

  /// 显示放弃更改对话框
  void _showDiscardDialog(BuildContext context, VersionControlInfo fileInfo) {
    // 这里应该显示放弃更改对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('放弃更改功能开发中')),
    );
  }

  /// 显示合并对话框
  void _showMergeDialog(BuildContext context, VersionControlInfo fileInfo) {
    // 这里应该显示合并对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('解决冲突功能开发中')),
    );
  }
} 