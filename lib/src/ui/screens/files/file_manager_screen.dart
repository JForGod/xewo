import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../widgets/files/file_explorer.dart';
import '../../widgets/files/file_operation_dialog.dart';
import '../../../services/core/file_system_service.dart';
import '../../../state/providers/editor_provider.dart';

/// 文件管理器页面
class FileManagerScreen extends ConsumerStatefulWidget {
  const FileManagerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends ConsumerState<FileManagerScreen> {
  String _currentPath = Directory.current.path;
  String? _selectedFilePath;
  
  void _handleFileSelected(String filePath) {
    setState(() {
      _selectedFilePath = filePath;
    });
  }
  
  Future<void> _openSelectedFile() async {
    if (_selectedFilePath == null) return;
    
    final fileSystem = ref.read(fileSystemProvider);
    try {
      final content = await fileSystem.readFile(_selectedFilePath!);
      
      // 使用编辑器打开文件
      if (mounted) {
        ref.read(editorProvider.notifier).openFile(_selectedFilePath!, content);
        
        // 可以在这里导航到编辑器页面
        // Navigator.of(context).pushNamed('/editor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开文件失败: $e')),
        );
      }
    }
  }
  
  Future<void> _showFileInfo() async {
    if (_selectedFilePath == null) return;
    
    final fileSystem = ref.read(fileSystemProvider);
    try {
      final fileInfo = await fileSystem.getFileInfo(_selectedFilePath!);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => FileInfoDialog(fileInfo: fileInfo),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取文件信息失败: $e')),
        );
      }
    }
  }
  
  Future<void> _copySelectedFile() async {
    if (_selectedFilePath == null) return;
    
    final fileSystem = ref.read(fileSystemProvider);
    try {
      final fileInfo = await fileSystem.getFileInfo(_selectedFilePath!);
      
      if (fileInfo.isDirectory) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('暂不支持复制文件夹')),
          );
        }
        return;
      }
      
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => FileCopyDialog(
            fileInfo: fileInfo,
            initialDirectory: path.dirname(fileInfo.path),
          ),
        );
        
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件复制成功')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('复制文件失败: $e')),
        );
      }
    }
  }
  
  Future<void> _moveSelectedFile() async {
    if (_selectedFilePath == null) return;
    
    final fileSystem = ref.read(fileSystemProvider);
    try {
      final fileInfo = await fileSystem.getFileInfo(_selectedFilePath!);
      
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => FileMoveDialog(
            fileInfo: fileInfo,
            initialDirectory: path.dirname(fileInfo.path),
          ),
        );
        
        if (result == true) {
          setState(() {
            _selectedFilePath = null;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('文件移动成功')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移动文件失败: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件管理器'),
        actions: [
          if (_selectedFilePath != null) ...[
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showFileInfo,
              tooltip: '文件信息',
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copySelectedFile,
              tooltip: '复制',
            ),
            IconButton(
              icon: const Icon(Icons.cut),
              onPressed: _moveSelectedFile,
              tooltip: '移动',
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openSelectedFile,
              tooltip: '打开',
            ),
          ],
        ],
      ),
      body: FileExplorer(
        initialPath: _currentPath,
        onFileSelected: _handleFileSelected,
      ),
    );
  }
} 