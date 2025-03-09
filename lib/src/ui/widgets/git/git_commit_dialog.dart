import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/git/git_command_service.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Git提交对话框
class GitCommitDialog extends ConsumerStatefulWidget {
  final String repoPath;
  final List<String> stagedFiles;
  
  const GitCommitDialog({
    Key? key,
    required this.repoPath,
    required this.stagedFiles,
  }) : super(key: key);
  
  /// 显示Git提交对话框
  static Future<bool?> show(
    BuildContext context,
    String repoPath,
    List<String> stagedFiles,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => GitCommitDialog(
        repoPath: repoPath,
        stagedFiles: stagedFiles,
      ),
    );
  }
  
  @override
  ConsumerState<GitCommitDialog> createState() => _GitCommitDialogState();
}

class _GitCommitDialogState extends ConsumerState<GitCommitDialog> {
  final TextEditingController _commitMessageController = TextEditingController();
  bool _isCommitting = false;
  String? _error;
  
  @override
  void dispose() {
    _commitMessageController.dispose();
    super.dispose();
  }
  
  /// 提交更改
  Future<void> _commitChanges() async {
    final message = _commitMessageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _error = '提交信息不能为空';
      });
      return;
    }
    
    setState(() {
      _isCommitting = true;
      _error = null;
    });
    
    try {
      final gitCommandService = ref.read(gitCommandProvider);
      final result = await gitCommandService.executeGitCommand(
        ['commit', '-m', message],
        workingDirectory: widget.repoPath,
      );
      
      if (result.success) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _isCommitting = false;
          _error = '提交失败: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _isCommitting = false;
        _error = '提交失败: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('提交更改'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 提交信息输入框
            TextField(
              controller: _commitMessageController,
              decoration: InputDecoration(
                labelText: '提交信息',
                hintText: '输入提交信息...',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            
            // 暂存文件列表
            Text(
              '暂存的文件 (${widget.stagedFiles.length})',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            // 文件列表
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.stagedFiles.length,
                itemBuilder: (context, index) {
                  final filePath = widget.stagedFiles[index];
                  final fileName = path.basename(filePath);
                  final relativePath = path.relative(filePath, from: widget.repoPath);
                  
                  return ListTile(
                    leading: Icon(
                      _getIconForFile(fileName),
                      color: _getColorForFile(context, fileName),
                    ),
                    title: Text(fileName),
                    subtitle: Text(relativePath),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCommitting ? null : () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isCommitting ? null : _commitChanges,
          child: _isCommitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('提交'),
        ),
      ],
    );
  }
  
  /// 获取文件图标
  IconData _getIconForFile(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.dart':
        return Icons.code;
      case '.html':
        return Icons.html;
      case '.css':
        return Icons.css;
      case '.js':
      case '.ts':
        return Icons.javascript;
      case '.json':
        return Icons.data_object;
      case '.md':
        return Icons.description;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.svg':
        return Icons.image;
      case '.pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  /// 获取文件颜色
  Color _getColorForFile(BuildContext context, String fileName) {
    final theme = Theme.of(context);
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.dart':
        return Colors.blue;
      case '.html':
        return Colors.orange;
      case '.css':
        return Colors.purple;
      case '.js':
        return Colors.yellow.shade800;
      case '.ts':
        return Colors.blue.shade800;
      case '.json':
        return Colors.green;
      case '.md':
        return Colors.blueGrey;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.svg':
        return Colors.pink;
      case '.pdf':
        return Colors.red;
      default:
        return theme.colorScheme.onSurface.withOpacity(0.7);
    }
  }
}

/// Git暂存文件对话框
class GitStagingDialog extends ConsumerStatefulWidget {
  final String repoPath;
  
  const GitStagingDialog({
    Key? key,
    required this.repoPath,
  }) : super(key: key);
  
  /// 显示Git暂存文件对话框
  static Future<List<String>?> show(
    BuildContext context,
    String repoPath,
  ) {
    return showDialog<List<String>>(
      context: context,
      builder: (context) => GitStagingDialog(
        repoPath: repoPath,
      ),
    );
  }
  
  @override
  ConsumerState<GitStagingDialog> createState() => _GitStagingDialogState();
}

class _GitStagingDialogState extends ConsumerState<GitStagingDialog> {
  List<String> _changedFiles = [];
  List<String> _selectedFiles = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadChangedFiles();
  }
  
  /// 加载已更改的文件
  Future<void> _loadChangedFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final gitCommandService = ref.read(gitCommandProvider);
      final result = await gitCommandService.executeGitCommand(
        ['status', '--porcelain'],
        workingDirectory: widget.repoPath,
      );
      
      if (result.success) {
        final files = <String>[];
        final lines = result.output.trim().split('\n');
        
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          
          final statusCode = line.substring(0, 2);
          final filePath = line.substring(3).trim();
          
          // 跳过已暂存的文件
          if (statusCode == '??') {
            // 未跟踪文件
            files.add(path.join(widget.repoPath, filePath));
          } else if (statusCode.contains('M') || statusCode.contains('D') || statusCode.contains('R')) {
            // 已修改、已删除或已重命名的文件
            files.add(path.join(widget.repoPath, filePath));
          }
        }
        
        setState(() {
          _changedFiles = files;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = '获取更改文件失败: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '获取更改文件失败: $e';
      });
    }
  }
  
  /// 暂存选中的文件
  Future<void> _stageSelectedFiles() async {
    if (_selectedFiles.isEmpty) {
      Navigator.pop(context, []);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final gitCommandService = ref.read(gitCommandProvider);
      bool allSuccess = true;
      
      for (final filePath in _selectedFiles) {
        final relativePath = path.relative(filePath, from: widget.repoPath);
        final result = await gitCommandService.executeGitCommand(
          ['add', relativePath],
          workingDirectory: widget.repoPath,
        );
        
        if (!result.success) {
          allSuccess = false;
          setState(() {
            _error = '暂存文件失败: ${result.error}';
          });
          break;
        }
      }
      
      if (allSuccess) {
        if (mounted) {
          Navigator.pop(context, _selectedFiles);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '暂存文件失败: $e';
      });
    }
  }
  
  /// 切换文件选择状态
  void _toggleFileSelection(String filePath) {
    setState(() {
      if (_selectedFiles.contains(filePath)) {
        _selectedFiles.remove(filePath);
      } else {
        _selectedFiles.add(filePath);
      }
    });
  }
  
  /// 全选/取消全选
  void _toggleSelectAll() {
    setState(() {
      if (_selectedFiles.length == _changedFiles.length) {
        _selectedFiles.clear();
      } else {
        _selectedFiles = List.from(_changedFiles);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('暂存文件'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _changedFiles.isEmpty
                    ? const Center(child: Text('没有更改的文件'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 全选/取消全选
                          Row(
                            children: [
                              Checkbox(
                                value: _selectedFiles.length == _changedFiles.length,
                                onChanged: (_) => _toggleSelectAll(),
                              ),
                              const Text('全选'),
                              const Spacer(),
                              Text(
                                '已选择 ${_selectedFiles.length} / ${_changedFiles.length} 个文件',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const Divider(),
                          
                          // 文件列表
                          Expanded(
                            child: ListView.builder(
                              itemCount: _changedFiles.length,
                              itemBuilder: (context, index) {
                                final filePath = _changedFiles[index];
                                final fileName = path.basename(filePath);
                                final relativePath = path.relative(filePath, from: widget.repoPath);
                                final isSelected = _selectedFiles.contains(filePath);
                                
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (_) => _toggleFileSelection(filePath),
                                  title: Text(fileName),
                                  subtitle: Text(relativePath),
                                  secondary: Icon(
                                    _getIconForFile(fileName),
                                    color: _getColorForFile(context, fileName),
                                  ),
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedFiles.isEmpty
              ? null
              : _stageSelectedFiles,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('暂存'),
        ),
      ],
    );
  }
  
  /// 获取文件图标
  IconData _getIconForFile(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.dart':
        return Icons.code;
      case '.html':
        return Icons.html;
      case '.css':
        return Icons.css;
      case '.js':
      case '.ts':
        return Icons.javascript;
      case '.json':
        return Icons.data_object;
      case '.md':
        return Icons.description;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.svg':
        return Icons.image;
      case '.pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  /// 获取文件颜色
  Color _getColorForFile(BuildContext context, String fileName) {
    final theme = Theme.of(context);
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.dart':
        return Colors.blue;
      case '.html':
        return Colors.orange;
      case '.css':
        return Colors.purple;
      case '.js':
        return Colors.yellow.shade800;
      case '.ts':
        return Colors.blue.shade800;
      case '.json':
        return Colors.green;
      case '.md':
        return Colors.blueGrey;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.svg':
        return Colors.pink;
      case '.pdf':
        return Colors.red;
      default:
        return theme.colorScheme.onSurface.withOpacity(0.7);
    }
  }
} 