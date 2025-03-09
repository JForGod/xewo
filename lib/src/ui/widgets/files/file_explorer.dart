import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../../../services/core/file_system_service.dart';
import 'file_operation_dialog.dart';

/// 文件浏览器小部件
class FileExplorer extends ConsumerStatefulWidget {
  final String initialPath;
  final Function(String)? onFileSelected;
  
  const FileExplorer({
    Key? key,
    required this.initialPath,
    this.onFileSelected,
  }) : super(key: key);

  @override
  ConsumerState<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends ConsumerState<FileExplorer> {
  late String _currentPath;
  List<FileInfo> _files = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedFilePath;
  
  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _loadDirectory(_currentPath);
  }
  
  Future<void> _loadDirectory(String dirPath) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _files = [];
    });
    
    try {
      final fileSystem = ref.read(fileSystemProvider);
      final files = await fileSystem.listDirectoryInfo(dirPath);
      
      setState(() {
        _files = files;
        _currentPath = dirPath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _navigateUp() {
    final parent = path.dirname(_currentPath);
    if (parent != _currentPath) {
      _loadDirectory(parent);
    }
  }
  
  void _selectFile(FileInfo file) {
    setState(() {
      _selectedFilePath = file.path;
    });
    
    if (!file.isDirectory && widget.onFileSelected != null) {
      widget.onFileSelected!(file.path);
    }
  }
  
  void _openFile(FileInfo file) {
    if (file.isDirectory) {
      _loadDirectory(file.path);
    } else if (widget.onFileSelected != null) {
      widget.onFileSelected!(file.path);
    }
  }
  
  Future<void> _showCreateFileDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateFileDialog(),
    );
    
    if (result != null) {
      final String name = result['name'] as String;
      final bool isDirectory = result['isDirectory'] as bool;
      final String content = result['content'] as String? ?? '';
      
      final fileSystem = ref.read(fileSystemProvider);
      final newPath = path.join(_currentPath, name);
      
      try {
        if (isDirectory) {
          await fileSystem.createDirectory(newPath);
        } else {
          await fileSystem.createFile(newPath, content);
        }
        
        // 刷新列表
        _loadDirectory(_currentPath);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _showRenameDialog(FileInfo file) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => RenameDialog(initialName: file.name),
    );
    
    if (result != null && result.isNotEmpty) {
      final fileSystem = ref.read(fileSystemProvider);
      final newPath = path.join(path.dirname(file.path), result);
      
      try {
        await fileSystem.rename(file.path, newPath);
        
        // 刷新列表
        _loadDirectory(_currentPath);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('重命名失败: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _deleteFile(FileInfo file) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        fileName: file.name,
        isDirectory: file.isDirectory,
      ),
    );
    
    if (result == true) {
      final fileSystem = ref.read(fileSystemProvider);
      
      try {
        await fileSystem.delete(
          file.path,
          recursive: file.isDirectory,
        );
        
        // 刷新列表
        _loadDirectory(_currentPath);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }
  
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
  
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
  
  Widget _buildBreadcrumb() {
    final parts = path.split(_currentPath);
    final widgets = <Widget>[];
    
    // 根目录
    widgets.add(
      TextButton(
        onPressed: () => _loadDirectory(parts[0]),
        child: const Text('/'),
      ),
    );
    
    // 路径各部分
    String fullPath = parts[0];
    for (int i = 1; i < parts.length; i++) {
      widgets.add(const Text('/'));
      fullPath = path.join(fullPath, parts[i]);
      final pathSegment = fullPath;
      widgets.add(
        TextButton(
          onPressed: () => _loadDirectory(pathSegment),
          child: Text(parts[i]),
        ),
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: widgets),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 路径导航栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                onPressed: _navigateUp,
                tooltip: '上一级',
              ),
              Expanded(child: _buildBreadcrumb()),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadDirectory(_currentPath),
                tooltip: '刷新',
              ),
              IconButton(
                icon: const Icon(Icons.create_new_folder),
                onPressed: _showCreateFileDialog,
                tooltip: '新建',
              ),
            ],
          ),
        ),
        
        // 文件列表
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('错误: $_error'))
                  : _files.isEmpty
                      ? const Center(child: Text('此文件夹为空'))
                      : ListView.builder(
                          itemCount: _files.length,
                          itemBuilder: (context, index) {
                            final file = _files[index];
                            return ListTile(
                              leading: Icon(
                                file.isDirectory
                                    ? Icons.folder
                                    : Icons.insert_drive_file,
                                color: file.isDirectory
                                    ? Colors.amber
                                    : Colors.blue,
                              ),
                              title: Text(file.name),
                              subtitle: Text(
                                file.isDirectory
                                    ? '文件夹'
                                    : '${file.extension} - ${_formatFileSize(file.size)}',
                              ),
                              trailing: Text(_formatDate(file.lastModified)),
                              selected: _selectedFilePath == file.path,
                              onTap: () => _selectFile(file),
                              onDoubleTap: () => _openFile(file),
                              onLongPress: () => _showFileContextMenu(context, file),
                            );
                          },
                        ),
        ),
      ],
    );
  }
  
  void _showFileContextMenu(BuildContext context, FileInfo file) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    
    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'open',
          child: const ListTile(
            leading: Icon(Icons.open_in_new),
            title: Text('打开'),
          ),
          onTap: () => Future.delayed(
            const Duration(milliseconds: 300),
            () => _openFile(file),
          ),
        ),
        PopupMenuItem(
          value: 'rename',
          child: const ListTile(
            leading: Icon(Icons.edit),
            title: Text('重命名'),
          ),
          onTap: () => Future.delayed(
            const Duration(milliseconds: 300),
            () => _showRenameDialog(file),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: const ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('删除'),
          ),
          onTap: () => Future.delayed(
            const Duration(milliseconds: 300),
            () => _deleteFile(file),
          ),
        ),
      ],
    );
  }
}

/// 创建文件对话框
class CreateFileDialog extends StatefulWidget {
  const CreateFileDialog({Key? key}) : super(key: key);

  @override
  State<CreateFileDialog> createState() => _CreateFileDialogState();
}

class _CreateFileDialogState extends State<CreateFileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isDirectory = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isDirectory ? '新建文件夹' : '新建文件'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '输入名称',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入名称';
                }
                if (value.contains(RegExp(r'[<>:"/\\|?*]'))) {
                  return '名称包含无效字符';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('文件夹'),
              value: _isDirectory,
              onChanged: (value) {
                setState(() {
                  _isDirectory = value;
                });
              },
            ),
            if (!_isDirectory) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '初始内容',
                  hintText: '(可选)',
                ),
                minLines: 3,
                maxLines: 5,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text,
                'isDirectory': _isDirectory,
                'content': _contentController.text,
              });
            }
          },
          child: const Text('创建'),
        ),
      ],
    );
  }
}

/// 重命名对话框
class RenameDialog extends StatefulWidget {
  final String initialName;
  
  const RenameDialog({
    Key? key,
    required this.initialName,
  }) : super(key: key);

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('重命名'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: '新名称',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 删除确认对话框
class DeleteConfirmationDialog extends StatelessWidget {
  final String fileName;
  final bool isDirectory;
  
  const DeleteConfirmationDialog({
    Key? key,
    required this.fileName,
    required this.isDirectory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('确认删除'),
      content: Text(
        '确定要删除${isDirectory ? "文件夹" : "文件"} "$fileName" 吗？${isDirectory ? "\n警告：这将删除文件夹内的所有内容。" : ""}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('删除'),
        ),
      ],
    );
  }
} 