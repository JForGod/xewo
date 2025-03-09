import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../../services/core/file_system_service.dart';

/// 文件复制对话框
class FileCopyDialog extends ConsumerStatefulWidget {
  final FileInfo fileInfo;
  final String initialDirectory;
  
  const FileCopyDialog({
    Key? key,
    required this.fileInfo,
    required this.initialDirectory,
  }) : super(key: key);

  @override
  ConsumerState<FileCopyDialog> createState() => _FileCopyDialogState();
}

class _FileCopyDialogState extends ConsumerState<FileCopyDialog> {
  late String _currentPath;
  List<FileInfo> _directories = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _nameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialDirectory;
    _nameController.text = widget.fileInfo.name;
    _loadDirectories();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDirectories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final fileSystem = ref.read(fileSystemProvider);
      final entities = await fileSystem.listDirectoryInfo(_currentPath);
      
      // 只保留目录
      final dirs = entities.where((entity) => entity.isDirectory).toList();
      
      setState(() {
        _directories = dirs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _navigateToParent() {
    final parent = path.dirname(_currentPath);
    if (parent != _currentPath) {
      setState(() {
        _currentPath = parent;
      });
      _loadDirectories();
    }
  }
  
  void _navigateToDirectory(String dirPath) {
    setState(() {
      _currentPath = dirPath;
    });
    _loadDirectories();
  }
  
  Future<void> _copyFile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入文件名')),
      );
      return;
    }
    
    final fileSystem = ref.read(fileSystemProvider);
    final targetPath = path.join(_currentPath, _nameController.text);
    
    // 检查目标文件是否已存在
    if (await fileSystem.exists(targetPath)) {
      if (mounted) {
        final overwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('文件已存在'),
            content: Text('$targetPath 已存在，是否覆盖?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('覆盖'),
              ),
            ],
          ),
        );
        
        if (overwrite != true) return;
      }
    }
    
    // 执行复制
    try {
      await fileSystem.copyFile(widget.fileInfo.path, targetPath);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('复制失败: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('复制到...'),
      content: SizedBox(
        width: 450,
        height: 400,
        child: Column(
          children: [
            // 当前路径
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: _navigateToParent,
                  tooltip: '上一级',
                ),
                Expanded(
                  child: Text(
                    _currentPath,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // 文件名输入
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '文件名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            
            // 目录列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('错误: $_error'))
                      : _directories.isEmpty
                          ? const Center(child: Text('此文件夹没有子文件夹'))
                          : ListView.builder(
                              itemCount: _directories.length,
                              itemBuilder: (context, index) {
                                final dir = _directories[index];
                                return ListTile(
                                  leading: const Icon(Icons.folder, color: Colors.amber),
                                  title: Text(dir.name),
                                  onTap: () => _navigateToDirectory(dir.path),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _copyFile,
          child: const Text('复制'),
        ),
      ],
    );
  }
}

/// 文件移动对话框
class FileMoveDialog extends ConsumerStatefulWidget {
  final FileInfo fileInfo;
  final String initialDirectory;
  
  const FileMoveDialog({
    Key? key,
    required this.fileInfo,
    required this.initialDirectory,
  }) : super(key: key);

  @override
  ConsumerState<FileMoveDialog> createState() => _FileMoveDialogState();
}

class _FileMoveDialogState extends ConsumerState<FileMoveDialog> {
  late String _currentPath;
  List<FileInfo> _directories = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _nameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialDirectory;
    _nameController.text = widget.fileInfo.name;
    _loadDirectories();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDirectories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final fileSystem = ref.read(fileSystemProvider);
      final entities = await fileSystem.listDirectoryInfo(_currentPath);
      
      // 只保留目录
      final dirs = entities.where((entity) => entity.isDirectory).toList();
      
      setState(() {
        _directories = dirs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _navigateToParent() {
    final parent = path.dirname(_currentPath);
    if (parent != _currentPath) {
      setState(() {
        _currentPath = parent;
      });
      _loadDirectories();
    }
  }
  
  void _navigateToDirectory(String dirPath) {
    setState(() {
      _currentPath = dirPath;
    });
    _loadDirectories();
  }
  
  Future<void> _moveFile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入文件名')),
      );
      return;
    }
    
    final fileSystem = ref.read(fileSystemProvider);
    final targetPath = path.join(_currentPath, _nameController.text);
    
    // 检查目标文件是否已存在
    if (await fileSystem.exists(targetPath)) {
      if (mounted) {
        final overwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('文件已存在'),
            content: Text('$targetPath 已存在，是否覆盖?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('覆盖'),
              ),
            ],
          ),
        );
        
        if (overwrite != true) return;
        
        // 如果覆盖，先删除目标文件
        try {
          await fileSystem.delete(targetPath);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除目标文件失败: $e')),
            );
          }
          return;
        }
      }
    }
    
    // 执行移动
    try {
      await fileSystem.rename(widget.fileInfo.path, targetPath);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移动失败: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('移动到...'),
      content: SizedBox(
        width: 450,
        height: 400,
        child: Column(
          children: [
            // 当前路径
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: _navigateToParent,
                  tooltip: '上一级',
                ),
                Expanded(
                  child: Text(
                    _currentPath,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // 文件名输入
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '文件名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            
            // 目录列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('错误: $_error'))
                      : _directories.isEmpty
                          ? const Center(child: Text('此文件夹没有子文件夹'))
                          : ListView.builder(
                              itemCount: _directories.length,
                              itemBuilder: (context, index) {
                                final dir = _directories[index];
                                return ListTile(
                                  leading: const Icon(Icons.folder, color: Colors.amber),
                                  title: Text(dir.name),
                                  onTap: () => _navigateToDirectory(dir.path),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _moveFile,
          child: const Text('移动'),
        ),
      ],
    );
  }
}

/// 文件信息对话框
class FileInfoDialog extends StatelessWidget {
  final FileInfo fileInfo;
  
  const FileInfoDialog({
    Key? key,
    required this.fileInfo,
  }) : super(key: key);
  
  String _formatFileSize(int size) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double fileSize = size.toDouble();
    
    while (fileSize >= 1024 && i < units.length - 1) {
      fileSize /= 1024;
      i++;
    }
    
    return '${fileSize.toStringAsFixed(2)} ${units[i]}';
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(fileInfo.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('类型'),
            subtitle: Text(fileInfo.isDirectory ? '文件夹' : '文件 (${fileInfo.extension})'),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('位置'),
            subtitle: Text(path.dirname(fileInfo.path)),
          ),
          if (!fileInfo.isDirectory)
            ListTile(
              leading: const Icon(Icons.data_usage),
              title: const Text('大小'),
              subtitle: Text(_formatFileSize(fileInfo.size)),
            ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('修改时间'),
            subtitle: Text(fileInfo.lastModified.toString()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
} 