import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/loading_indicator.dart';

class SourceControlView extends ConsumerStatefulWidget {
  const SourceControlView({super.key});

  @override
  ConsumerState<SourceControlView> createState() => _SourceControlViewState();
}

class _SourceControlViewState extends ConsumerState<SourceControlView> {
  bool _isLoading = false;
  List<SourceControlChange> _changes = [];
  String? _currentBranch;
  final TextEditingController _commitMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChanges();
  }

  @override
  void dispose() {
    _commitMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadChanges() async {
    setState(() {
      _isLoading = true;
    });

    // 模拟加载源代码管理数据
    await Future.delayed(const Duration(milliseconds: 500));

    // 这里应该实际调用Git或其他版本控制系统API
    setState(() {
      _isLoading = false;
      _currentBranch = 'main';
      _changes = [
        SourceControlChange(
          path: 'lib/src/ui/widgets/file_tree/file_tree_toolbar.dart',
          type: ChangeType.modified,
          status: 'M',
        ),
        SourceControlChange(
          path: 'lib/src/ui/widgets/file_tree/file_tree_toolbar_controller.dart',
          type: ChangeType.modified,
          status: 'M',
        ),
        SourceControlChange(
          path: 'lib/src/ui/widgets/file_tree/views/source_control_view.dart',
          type: ChangeType.added,
          status: 'A',
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 分支信息和操作按钮
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.call_split, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                _currentBranch ?? '加载中...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 16),
                tooltip: '刷新',
                onPressed: _loadChanges,
              ),
              IconButton(
                icon: const Icon(Icons.sync, size: 16),
                tooltip: '同步',
                onPressed: () {
                  // 实现同步功能
                },
              ),
            ],
          ),
        ),

        // 变更列表
        Expanded(
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : _changes.isEmpty
                  ? Center(
                      child: Text(
                        '没有变更',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _changes.length,
                      itemBuilder: (context, index) {
                        final change = _changes[index];
                        return ListTile(
                          dense: true,
                          leading: _getChangeIcon(change.type, theme),
                          title: Text(
                            _getFileName(change.path),
                            style: theme.textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            change.path,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          trailing: Text(
                            change.status,
                            style: TextStyle(
                              color: _getStatusColor(change.type, theme),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            // 查看变更详情
                          },
                        );
                      },
                    ),
        ),

        // 提交信息输入框
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _commitMessageController,
                decoration: InputDecoration(
                  hintText: '提交信息',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _changes.isEmpty ? null : () {
                  // 实现提交功能
                },
                child: const Text('提交'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getChangeIcon(ChangeType type, ThemeData theme) {
    IconData iconData;
    Color color;

    switch (type) {
      case ChangeType.added:
        iconData = Icons.add_circle_outline;
        color = Colors.green;
        break;
      case ChangeType.modified:
        iconData = Icons.edit;
        color = Colors.blue;
        break;
      case ChangeType.deleted:
        iconData = Icons.delete_outline;
        color = Colors.red;
        break;
      case ChangeType.renamed:
        iconData = Icons.drive_file_rename_outline;
        color = Colors.orange;
        break;
    }

    return Icon(iconData, size: 16, color: color);
  }

  Color _getStatusColor(ChangeType type, ThemeData theme) {
    switch (type) {
      case ChangeType.added:
        return Colors.green;
      case ChangeType.modified:
        return Colors.blue;
      case ChangeType.deleted:
        return Colors.red;
      case ChangeType.renamed:
        return Colors.orange;
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }
}

enum ChangeType {
  added,
  modified,
  deleted,
  renamed,
}

class SourceControlChange {
  final String path;
  final ChangeType type;
  final String status;

  SourceControlChange({
    required this.path,
    required this.type,
    required this.status,
  });
} 